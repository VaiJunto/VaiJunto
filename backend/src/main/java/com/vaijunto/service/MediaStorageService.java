package com.vaijunto.service;

import com.vaijunto.config.R2Config.R2Properties;
import com.vaijunto.domain.entities.Conversation;
import com.vaijunto.domain.entities.MediaObject;
import com.vaijunto.domain.entities.User;
import com.vaijunto.dto.MediaUploadIntentDto;
import com.vaijunto.dto.MediaUploadIntentRequest;
import com.vaijunto.exception.ApiException;
import com.vaijunto.repository.ConversationRepository;
import com.vaijunto.repository.MediaObjectRepository;
import com.vaijunto.repository.UserRepository;
import java.time.Duration;
import java.time.OffsetDateTime;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.http.HttpStatus;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.DeleteObjectRequest;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.model.HeadObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest;
import software.amazon.awssdk.services.s3.presigner.model.PutObjectPresignRequest;

@Slf4j
@Service
@RequiredArgsConstructor
public class MediaStorageService {
    private static final long MB = 1024L * 1024L;
    private final R2Properties r2;
    private final ObjectProvider<S3Client> clients;
    private final ObjectProvider<S3Presigner> presigners;
    private final MediaObjectRepository media;
    private final UserRepository users;
    private final ConversationRepository conversations;

    @Transactional
    public MediaUploadIntentDto intent(MediaUploadIntentRequest request, String email) {
        User user = users.findByEmail(email).orElseThrow(ApiException::userNotFound);
        validate(request);
        requireR2();
        Conversation conversation = null;
        if ("CHAT".equals(request.category().toUpperCase(Locale.ROOT))) {
            if (request.conversationId() == null) throw bad("CONVERSATION_REQUIRED", "Informe a conversa.");
            conversation = conversations.findById(request.conversationId())
                    .orElseThrow(() -> bad("CONVERSATION_NOT_FOUND", "Conversa não encontrada."));
            if (!participant(conversation, user)) throw ApiException.conversationForbidden();
        }
        ensureCapacity(request.sizeBytes());
        String category = request.category().toUpperCase(Locale.ROOT);
        MediaObject object = media.save(MediaObject.builder().owner(user).conversation(conversation)
                .storageKey(category.toLowerCase(Locale.ROOT) + "/" + user.getId() + "/" + UUID.randomUUID())
                .category(category).contentType(request.contentType().toLowerCase(Locale.ROOT))
                .sizeBytes(request.sizeBytes()).durationSeconds(request.durationSeconds()).status("PENDING").build());
        PutObjectRequest put = PutObjectRequest.builder().bucket(r2.bucket()).key(object.getStorageKey())
                .contentType(object.getContentType()).contentLength(object.getSizeBytes()).build();
        String url = presigners.getObject().presignPutObject(PutObjectPresignRequest.builder().putObjectRequest(put)
                .signatureDuration(Duration.ofMinutes(5)).build()).url().toString();
        return new MediaUploadIntentDto(object.getId(), url, OffsetDateTime.now().plusMinutes(5));
    }

    @Transactional
    public void complete(UUID id, String email) {
        User user = users.findByEmail(email).orElseThrow(ApiException::userNotFound);
        MediaObject object = media.findByIdAndOwnerId(id, user.getId()).orElseThrow(() -> bad("MEDIA_NOT_FOUND", "Mídia não encontrada."));
        if (!"PENDING".equals(object.getStatus())) return;
        requireR2();
        var head = clients.getObject().headObject(HeadObjectRequest.builder().bucket(r2.bucket()).key(object.getStorageKey()).build());
        if (head.contentLength() != object.getSizeBytes() || head.contentType() == null || !head.contentType().equalsIgnoreCase(object.getContentType())) {
            deleteRemote(object, "UPLOAD_INVALID");
            throw bad("MEDIA_INVALID", "O arquivo enviado não respeita os limites.");
        }
        object.setStatus("ACTIVE");
    }

    @Transactional(readOnly = true)
    public String downloadUrl(UUID id, String email) {
        User user = users.findByEmail(email).orElseThrow(ApiException::userNotFound);
        MediaObject object = media.findById(id).orElseThrow(() -> bad("MEDIA_NOT_FOUND", "Mídia não encontrada."));
        if (!canRead(object, user)) throw ApiException.conversationForbidden();
        if (!"ACTIVE".equals(object.getStatus())) throw bad("MEDIA_UNAVAILABLE", "Mídia indisponível.");
        requireR2();
        return presigners.getObject().presignGetObject(GetObjectPresignRequest.builder()
                .getObjectRequest(GetObjectRequest.builder().bucket(r2.bucket()).key(object.getStorageKey()).build())
                .signatureDuration(Duration.ofMinutes(2)).build()).url().toString();
    }

    @Scheduled(cron = "${app.r2.cleanup-cron:0 0 * * * *}")
    @Transactional
    public void cleanupExpired() {
        for (MediaObject object : media.findByStatusAndCreatedAtBefore("PENDING", OffsetDateTime.now().minusMinutes(15))) deleteRemote(object, "UPLOAD_ABANDONED");
        for (MediaObject object : media.findByStatusAndCategoryAndDeleteAfterIsNull("ACTIVE", "CHAT")) {
            var ride = object.getConversation() == null ? null : object.getConversation().getRide();
            if (ride != null && ride.getActualEnd() != null) object.setDeleteAfter(ride.getActualEnd().plusHours(24));
        }
        for (MediaObject object : media.findByStatusAndCategoryAndDeleteAfterLessThanEqualOrderByDeleteAfterAsc("ACTIVE", "CHAT", OffsetDateTime.now())) deleteRemote(object, "RETENTION_EXPIRED");
    }

    /** Used only after an authorized moderator explicitly confirms evidence removal. */
    @Transactional
    public void deleteReportedMedia(UUID id, String reason) {
        MediaObject object = media.findById(id).orElseThrow(() -> bad("MEDIA_NOT_FOUND", "Mídia não encontrada."));
        if (!"REPORT".equals(object.getCategory())) throw bad("MEDIA_NOT_REPORT_EVIDENCE", "A mídia não pertence a uma denúncia.");
        deleteRemote(object, "ADMIN_EVIDENCE_REMOVAL: " + reason.trim());
    }

    @Transactional
    public void ensureCapacity(long incoming) {
        if (media.activeBytes() + incoming <= r2.maxBytes()) return;
        // Only common chat media already scheduled for deletion is eligible here.
        // PROFILE and REPORT are deliberately excluded from automatic cleanup.
        for (MediaObject object : media.findByStatusAndCategoryAndDeleteAfterIsNotNullOrderByDeleteAfterAsc("ACTIVE", "CHAT")) {
            deleteRemote(object, "STORAGE_LIMIT_30_GB");
            if (media.activeBytes() + incoming <= r2.maxBytes()) return;
        }
        throw new ApiException(HttpStatus.INSUFFICIENT_STORAGE, "STORAGE_LIMIT_REACHED", "O armazenamento de mídia está cheio. Tente novamente mais tarde.");
    }

    private void validate(MediaUploadIntentRequest request) {
        String category = request.category().toUpperCase(Locale.ROOT);
        String type = request.contentType().toLowerCase(Locale.ROOT);
        if (!Set.of("CHAT", "PROFILE").contains(category)) throw bad("MEDIA_CATEGORY_INVALID", "Categoria de mídia inválida.");
        if (type.startsWith("image/") && request.sizeBytes() <= 5 * MB) return;
        if (type.startsWith("video/") && request.sizeBytes() <= 15 * MB && request.durationSeconds() != null && request.durationSeconds() <= 20) return;
        if (type.startsWith("audio/") && request.sizeBytes() <= 3 * MB && request.durationSeconds() != null && request.durationSeconds() <= 120) return;
        throw bad("MEDIA_LIMIT_EXCEEDED", "A mídia excede o tipo, duração ou tamanho permitido.");
    }

    private void deleteRemote(MediaObject object, String reason) {
        try {
            if (r2.configured()) clients.getObject().deleteObject(DeleteObjectRequest.builder().bucket(r2.bucket()).key(object.getStorageKey()).build());
            object.setStatus("DELETED"); object.setDeletedAt(OffsetDateTime.now()); object.setDeletedReason(reason);
            log.info("Mídia removida: id={}, key={}, motivo={}", object.getId(), object.getStorageKey(), reason);
        } catch (Exception error) {
            log.error("Falha ao remover mídia id={} do R2; banco preservado para reconciliação", object.getId(), error);
        }
    }

    private boolean participant(Conversation c, User u) { return c.getParticipantA() != null && c.getParticipantA().getId().equals(u.getId()) || c.getParticipantB() != null && c.getParticipantB().getId().equals(u.getId()); }
    private boolean canRead(MediaObject object, User user) { return object.getOwner().getId().equals(user.getId()) || object.getConversation() != null && participant(object.getConversation(), user); }
    private void requireR2() { if (!r2.configured() || clients.getIfAvailable() == null || presigners.getIfAvailable() == null) throw new ApiException(HttpStatus.SERVICE_UNAVAILABLE, "MEDIA_NOT_CONFIGURED", "O armazenamento de mídia ainda não está configurado."); }
    private ApiException bad(String code, String message) { return new ApiException(HttpStatus.BAD_REQUEST, code, message); }
}
