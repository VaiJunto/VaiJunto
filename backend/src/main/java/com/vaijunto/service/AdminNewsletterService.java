package com.vaijunto.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.vaijunto.domain.entities.*;
import com.vaijunto.exception.ApiException;
import com.vaijunto.repository.*;
import java.time.OffsetDateTime;
import java.util.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Newsletter administrativa: mensagem em formato embed, montada por
 * componentes, não respondível, enviada para um público segmentado.
 *
 * <p>O conteúdo fica guardado uma vez em {@code admin_newsletters} e cada
 * destinatário recebe uma notificação com o id — o app busca e renderiza. Não
 * duplicamos o corpo por pessoa: um envio para mil pessoas grava mil linhas de
 * entrega, não mil cópias da mensagem.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class AdminNewsletterService {

    private static final Set<String> COMPONENT_TYPES = Set.of("HEADING", "TEXT", "IMAGE", "AUDIO", "VIDEO", "DIVIDER", "BUTTON");
    private static final Set<String> FONTS = Set.of("PLEX_SANS", "PLEX_MONO", "SYSTEM");
    private static final int MAX_COMPONENTS = 40;

    private final AdminNewsletterRepository newsletters;
    private final AdminNewsletterRecipientRepository recipients;
    private final AdminAccountRepository admins;
    private final UserRepository users;
    private final MediaObjectRepository media;
    private final AdminAuditEventRepository audits;
    private final NotificationService notifications;
    private final NewsletterAudienceService audience;
    private final MediaStorageService storage;
    private final ObjectMapper json = new ObjectMapper();

    // ---------------------------------------------------------------- painel

    /** Contagem do público antes de enviar, para a tela de confirmação. */
    @Transactional(readOnly = true)
    public Map<String, Object> previewAudience(Map<String, Object> body) {
        JsonNode node = json.valueToTree(body);
        var userIds = audience.resolveUsers(node);
        var adminIds = audience.resolveAdmins(node);
        return Map.of("userCount", userIds.size(), "adminCount", adminIds.size(),
                "sample", audience.sampleNames(userIds, 8));
    }

    @Transactional(readOnly = true)
    public List<Map<String, Object>> courses(String query) {
        return audience.courses(query);
    }

    /**
     * Cria a newsletter e envia na hora, ou agenda. Regras de validação são as
     * do enunciado: título obrigatório e pelo menos um componente.
     */
    @Transactional
    public Map<String, Object> create(String email, Map<String, Object> body) {
        var admin = admin(email);
        String title = Objects.toString(body.get("title"), "").trim();
        if (title.isBlank()) throw bad("NEWSLETTER_TITLE_REQUIRED", "Dê um título para a newsletter.");
        if (title.length() > 160) throw bad("NEWSLETTER_TITLE_TOO_LONG", "O título passa de 160 caracteres.");

        JsonNode components = validateComponents(json.valueToTree(body.get("components")));
        JsonNode settings = validateSettings(json.valueToTree(body.get("settings")));
        JsonNode target = json.valueToTree(body.getOrDefault("audience", Map.of()));

        var userIds = audience.resolveUsers(target);
        var adminIds = audience.resolveAdmins(target);
        if (userIds.isEmpty() && adminIds.isEmpty())
            throw bad("NEWSLETTER_AUDIENCE_EMPTY", "Escolha pelo menos um destinatário.");

        OffsetDateTime scheduledFor = scheduledFor(body.get("scheduledFor"));
        var newsletter = newsletters.save(AdminNewsletter.builder().createdBy(admin).title(title)
                .components(components.toString()).settings(settings.toString()).audience(target.toString())
                .status("SCHEDULED").scheduledFor(scheduledFor).build());

        if (scheduledFor == null) {
            deliver(newsletter);
            audit(admin, "ADMIN_NEWSLETTER_SENT", newsletter.getId().toString(), title);
        } else {
            audit(admin, "ADMIN_NEWSLETTER_SCHEDULED", newsletter.getId().toString(), title);
        }
        return summary(newsletter);
    }

    @Transactional(readOnly = true)
    public List<Map<String, Object>> list() {
        return newsletters.findTop50ByOrderByCreatedAtDesc().stream().map(this::summary).toList();
    }

    /** Só faz sentido para agendada: uma vez entregue, não há o que desfazer. */
    @Transactional
    public Map<String, Object> cancel(String email, UUID id) {
        var admin = admin(email);
        var newsletter = newsletters.findById(id).orElseThrow(() -> notFound());
        if (!"SCHEDULED".equals(newsletter.getStatus()))
            throw bad("NEWSLETTER_NOT_SCHEDULED", "Só dá para cancelar newsletter agendada.");
        newsletter.setStatus("CANCELLED");
        audit(admin, "ADMIN_NEWSLETTER_CANCELLED", id.toString(), newsletter.getTitle());
        return summary(newsletter);
    }

    /** Conteúdo completo, para o preview do painel e para a leitura no app. */
    @Transactional(readOnly = true)
    public Map<String, Object> content(UUID id) {
        return render(newsletters.findById(id).orElseThrow(() -> notFound()));
    }

    // ------------------------------------------------------------------- app

    /** Leitura pelo destinatário: precisa haver entrega registrada para ele. */
    @Transactional
    public Map<String, Object> read(UUID id, String email) {
        var user = users.findByEmail(email).orElseThrow(ApiException::userNotFound);
        var delivery = recipients.findByNewsletterIdAndUserId(id, user.getId())
                .orElseThrow(() -> new ApiException(HttpStatus.FORBIDDEN, "NEWSLETTER_FORBIDDEN", "Esta newsletter não é sua."));
        if (delivery.getReadAt() == null) delivery.setReadAt(OffsetDateTime.now());
        return render(delivery.getNewsletter());
    }

    // -------------------------------------------------------------- entrega

    /** Dispara as agendadas cuja hora chegou. */
    @Scheduled(fixedDelayString = "${app.newsletter.dispatch-delay-ms:60000}")
    @Transactional
    public void dispatchScheduled() {
        for (var newsletter : newsletters.findByStatusAndScheduledForLessThanEqual("SCHEDULED", OffsetDateTime.now())) {
            try {
                deliver(newsletter);
                log.info("Newsletter agendada entregue: id={}, destinatários={}", newsletter.getId(), newsletter.getRecipientCount());
            } catch (Exception error) {
                newsletter.setStatus("FAILED");
                newsletter.setFailureReason(String.valueOf(error.getMessage()).substring(0, Math.min(500, String.valueOf(error.getMessage()).length())));
                log.error("Falha ao entregar newsletter id={}", newsletter.getId(), error);
            }
        }
    }

    private void deliver(AdminNewsletter newsletter) {
        JsonNode target = read(newsletter.getAudience());
        var userIds = audience.resolveUsers(target);
        var adminIds = audience.resolveAdmins(target);
        String payload = "{\"newsletterId\":\"" + newsletter.getId() + "\"}";
        String preview = preview(read(newsletter.getComponents()));

        for (UUID userId : userIds) {
            if (recipients.findByNewsletterIdAndUserId(newsletter.getId(), userId).isPresent()) continue;
            recipients.save(AdminNewsletterRecipient.builder().newsletter(newsletter)
                    .user(users.getReferenceById(userId)).build());
            notifications.createAndSendNotification(userId, newsletter.getTitle(), preview, "ADMIN_NEWSLETTER", payload, null);
        }
        for (UUID adminId : adminIds) {
            if (recipients.findByNewsletterIdAndAdminId(newsletter.getId(), adminId).isPresent()) continue;
            recipients.save(AdminNewsletterRecipient.builder().newsletter(newsletter)
                    .admin(admins.getReferenceById(adminId)).build());
        }
        newsletter.setRecipientCount(userIds.size() + adminIds.size());
        newsletter.setStatus("SENT");
        newsletter.setSentAt(OffsetDateTime.now());
    }

    // ---------------------------------------------------------- validação

    /**
     * Componentes: lista ordenada, no mínimo um. Mídia precisa existir, estar
     * ativa e ter sido enviada como mídia administrativa — assim o corpo da
     * newsletter nunca aponta para anexo de conversa de usuário.
     */
    private JsonNode validateComponents(JsonNode components) {
        if (!components.isArray() || components.isEmpty())
            throw bad("NEWSLETTER_COMPONENTS_REQUIRED", "Adicione pelo menos um componente.");
        if (components.size() > MAX_COMPONENTS)
            throw bad("NEWSLETTER_COMPONENTS_LIMIT", "São no máximo " + MAX_COMPONENTS + " componentes.");
        for (JsonNode component : components) {
            String type = component.path("type").asText("").trim().toUpperCase(Locale.ROOT);
            if (!COMPONENT_TYPES.contains(type)) throw bad("NEWSLETTER_COMPONENT_INVALID", "Componente inválido: " + type);
            switch (type) {
                case "HEADING", "TEXT" -> {
                    String text = component.path("text").asText("").trim();
                    if (text.isBlank()) throw bad("NEWSLETTER_TEXT_EMPTY", "Há um componente de texto vazio.");
                    if (text.length() > 4000) throw bad("NEWSLETTER_TEXT_TOO_LONG", "Um bloco de texto passa de 4000 caracteres.");
                }
                case "IMAGE", "AUDIO", "VIDEO" -> requireAdminMedia(component.path("mediaId").asText(""), type);
                case "BUTTON" -> {
                    if (component.path("label").asText("").trim().isBlank())
                        throw bad("NEWSLETTER_BUTTON_LABEL", "Dê um texto para o botão.");
                    String link = component.path("link").asText("").trim();
                    if (!link.isEmpty() && !link.startsWith("https://") && !link.startsWith("vaijunto://"))
                        throw bad("NEWSLETTER_BUTTON_LINK", "O link do botão precisa ser https:// ou vaijunto://.");
                }
                default -> { /* DIVIDER não tem conteúdo */ }
            }
        }
        return components;
    }

    private void requireAdminMedia(String mediaId, String type) {
        MediaObject object;
        try {
            object = media.findById(UUID.fromString(mediaId)).orElseThrow(() -> bad("NEWSLETTER_MEDIA_NOT_FOUND", "Anexo não encontrado."));
        } catch (IllegalArgumentException error) {
            throw bad("NEWSLETTER_MEDIA_NOT_FOUND", "Anexo não encontrado.");
        }
        if (!"ACTIVE".equals(object.getStatus())) throw bad("NEWSLETTER_MEDIA_UNAVAILABLE", "Anexo indisponível.");
        if (!"NEWSLETTER".equals(object.getCategory())) throw bad("NEWSLETTER_MEDIA_INVALID", "Anexo não pertence a uma newsletter.");
        String contentType = object.getContentType();
        boolean matches = switch (type) {
            case "IMAGE" -> contentType.startsWith("image/");
            case "AUDIO" -> contentType.startsWith("audio/");
            default -> contentType.startsWith("video/");
        };
        if (!matches) throw bad("NEWSLETTER_MEDIA_TYPE", "O anexo não é do tipo do componente.");
    }

    /** Aparência do embed. Tudo tem padrão, então config vazia é válida. */
    private JsonNode validateSettings(JsonNode settings) {
        ObjectNode result = json.createObjectNode();
        result.put("backgroundColor", color(settings.path("backgroundColor").asText(""), "#FFFFFF"));
        result.put("accentColor", color(settings.path("accentColor").asText(""), "#00AEEF"));
        String footer = settings.path("footer").asText("").trim();
        if (footer.length() > 160) throw bad("NEWSLETTER_FOOTER_TOO_LONG", "O rodapé passa de 160 caracteres.");
        result.put("footer", footer);
        result.put("showDateTime", settings.path("showDateTime").asBoolean(true));
        String font = settings.path("font").asText("PLEX_SANS").trim().toUpperCase(Locale.ROOT);
        if (!FONTS.contains(font)) throw bad("NEWSLETTER_FONT_INVALID", "Fonte inválida.");
        result.put("font", font);
        return result;
    }

    private String color(String value, String fallback) {
        if (value == null || value.isBlank()) return fallback;
        if (!value.matches("^#[0-9A-Fa-f]{6}$")) throw bad("NEWSLETTER_COLOR_INVALID", "Use cor hexadecimal, por exemplo #00AEEF.");
        return value.toUpperCase(Locale.ROOT);
    }

    private OffsetDateTime scheduledFor(Object value) {
        if (value == null || String.valueOf(value).isBlank()) return null;
        OffsetDateTime when;
        try {
            when = OffsetDateTime.parse(String.valueOf(value));
        } catch (Exception error) {
            throw bad("NEWSLETTER_SCHEDULE_INVALID", "Data de agendamento inválida.");
        }
        // Um minuto de folga: o relógio do navegador não bate com o do servidor.
        if (when.isBefore(OffsetDateTime.now().minusMinutes(1)))
            throw bad("NEWSLETTER_SCHEDULE_PAST", "O agendamento precisa ser no futuro.");
        return when;
    }

    // --------------------------------------------------------------- saída

    private Map<String, Object> summary(AdminNewsletter newsletter) {
        var result = new LinkedHashMap<String, Object>();
        result.put("id", newsletter.getId());
        result.put("title", newsletter.getTitle());
        result.put("status", newsletter.getStatus());
        result.put("scheduledFor", newsletter.getScheduledFor());
        result.put("sentAt", newsletter.getSentAt());
        result.put("recipientCount", newsletter.getRecipientCount());
        result.put("readCount", recipients.countByNewsletterIdAndReadAtIsNotNull(newsletter.getId()));
        result.put("createdAt", newsletter.getCreatedAt());
        result.put("failureReason", newsletter.getFailureReason());
        return result;
    }

    /**
     * Conteúdo pronto para renderizar: cada componente de mídia ganha uma URL
     * assinada. Uma hora de validade porque áudio e vídeo continuam buscando
     * bytes depois que a tela abriu.
     */
    private Map<String, Object> render(AdminNewsletter newsletter) {
        var components = new ArrayList<Map<String, Object>>();
        for (JsonNode component : read(newsletter.getComponents())) {
            var item = json.convertValue(component, new com.fasterxml.jackson.core.type.TypeReference<LinkedHashMap<String, Object>>() {});
            String mediaId = Objects.toString(item.get("mediaId"), "");
            if (!mediaId.isBlank()) {
                try {
                    item.put("url", storage.adminMediaUrl(UUID.fromString(mediaId)));
                } catch (Exception error) {
                    log.warn("Anexo indisponível na newsletter {}: {}", newsletter.getId(), error.getMessage());
                    item.put("url", null);
                }
            }
            components.add(item);
        }
        var result = new LinkedHashMap<String, Object>();
        result.put("id", newsletter.getId());
        result.put("title", newsletter.getTitle());
        result.put("components", components);
        result.put("settings", json.convertValue(read(newsletter.getSettings()), Map.class));
        result.put("sentAt", newsletter.getSentAt());
        result.put("createdAt", newsletter.getCreatedAt());
        return result;
    }

    /** Resumo em texto puro: é o que vai no push e na lista de notificações. */
    private String preview(JsonNode components) {
        for (JsonNode component : components) {
            String type = component.path("type").asText("");
            if ("TEXT".equals(type) || "HEADING".equals(type)) {
                String text = component.path("text").asText("").trim().replaceAll("\\s+", " ");
                if (!text.isBlank()) return text.length() <= 140 ? text : text.substring(0, 139) + "…";
            }
        }
        return "Você recebeu uma mensagem do VaiJunto.";
    }

    private JsonNode read(String raw) {
        try {
            return json.readTree(raw);
        } catch (Exception error) {
            throw new ApiException(HttpStatus.INTERNAL_SERVER_ERROR, "NEWSLETTER_CORRUPTED", "Conteúdo da newsletter ilegível.");
        }
    }

    private AdminAccount admin(String email) {
        return admins.findByEmail(email).orElseThrow(() -> new ApiException(HttpStatus.FORBIDDEN, "ADMIN_NOT_FOUND", "Administrador inválido."));
    }

    private void audit(AdminAccount admin, String event, String target, String reason) {
        audits.save(AdminAuditEvent.builder().admin(admin).eventType(event).targetType("NEWSLETTER").targetId(target).reason(reason).build());
    }

    private ApiException bad(String code, String message) {
        return new ApiException(HttpStatus.BAD_REQUEST, code, message);
    }

    private ApiException notFound() {
        return new ApiException(HttpStatus.NOT_FOUND, "NEWSLETTER_NOT_FOUND", "Newsletter não encontrada.");
    }
}
