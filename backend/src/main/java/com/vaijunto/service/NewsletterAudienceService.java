package com.vaijunto.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.vaijunto.exception.ApiException;
import jakarta.persistence.EntityManager;
import java.util.*;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Resolve o público-alvo de uma newsletter.
 *
 * <p>Semântica: {@code everyone} ignora os demais filtros. Fora isso, os
 * filtros de grupo (perfil, vínculo, curso, tag) são combinados por <b>E</b> —
 * "professores E do curso X" — e os usuários escolhidos um a um entram por
 * <b>OU</b>, sempre somados ao resultado. Admins são um alvo separado, porque
 * não têm registro em {@code users}.
 *
 * <p>Só entra quem está ativo: conta suspensa ou com exclusão pedida não recebe.
 */
@Service
@RequiredArgsConstructor
public class NewsletterAudienceService {

    private static final Set<String> PROFILE_TYPES = Set.of("PASSENGER", "VAN_DRIVER", "CARPOOL_DRIVER");
    private static final Set<String> AFFILIATIONS = Set.of("STUDENT", "PROFESSOR", "STAFF");
    private static final Set<String> ADMIN_ROLES = Set.of("SUPER_ADMIN", "ADMIN", "MODERATOR");

    private final EntityManager entityManager;

    /** Ids de usuários que recebem a newsletter, sem repetição. */
    @SuppressWarnings("unchecked")
    @Transactional(readOnly = true)
    public List<UUID> resolveUsers(JsonNode audience) {
        boolean everyone = audience.path("everyone").asBoolean(false);
        List<String> profileTypes = strings(audience, "profileTypes", PROFILE_TYPES, "AUDIENCE_PROFILE_INVALID");
        List<String> affiliations = strings(audience, "affiliations", AFFILIATIONS, "AUDIENCE_AFFILIATION_INVALID");
        List<String> courses = strings(audience, "courses", null, null);
        List<UUID> tagIds = uuids(audience, "tagIds");
        List<UUID> userIds = uuids(audience, "userIds");

        boolean hasGroupFilter = !profileTypes.isEmpty() || !affiliations.isEmpty() || !courses.isEmpty() || !tagIds.isEmpty();
        var result = new LinkedHashSet<UUID>();

        if (everyone || hasGroupFilter) {
            var query = entityManager.createNativeQuery("""
                    SELECT u.id FROM users u
                    WHERE u.is_active = true AND u.deletion_requested_at IS NULL
                      AND (:everyone = true OR (
                            (:noProfiles = true OR string_to_array(replace(replace(u.profile_types,'{',''),'}',''), ',') && CAST(:profileTypes AS text[]))
                        AND (:noAffiliations = true OR u.affiliation = ANY(CAST(:affiliations AS text[])))
                        AND (:noCourses = true OR u.course = ANY(CAST(:courses AS text[])))
                        AND (:noTags = true OR EXISTS (
                                SELECT 1 FROM admin_user_tag_assignments a
                                WHERE a.user_id = u.id AND a.tag_id = ANY(CAST(:tagIds AS uuid[]))))
                      ))
                    ORDER BY u.full_name
                    """);
            query.setParameter("everyone", everyone);
            query.setParameter("noProfiles", profileTypes.isEmpty());
            query.setParameter("profileTypes", pgArray(profileTypes));
            query.setParameter("noAffiliations", affiliations.isEmpty());
            query.setParameter("affiliations", pgArray(affiliations));
            query.setParameter("noCourses", courses.isEmpty());
            query.setParameter("courses", pgArray(courses));
            query.setParameter("noTags", tagIds.isEmpty());
            query.setParameter("tagIds", pgArray(tagIds.stream().map(UUID::toString).toList()));
            for (Object id : (List<Object>) query.getResultList()) result.add(asUuid(id));
        }

        // Usuários escolhidos na busca entram mesmo que não passem nos filtros —
        // foi uma escolha explícita do admin.
        if (!userIds.isEmpty()) {
            var query = entityManager.createNativeQuery(
                    "SELECT u.id FROM users u WHERE u.id = ANY(CAST(:ids AS uuid[])) AND u.is_active = true AND u.deletion_requested_at IS NULL");
            query.setParameter("ids", pgArray(userIds.stream().map(UUID::toString).toList()));
            for (Object id : (List<Object>) query.getResultList()) result.add(asUuid(id));
        }
        return List.copyOf(result);
    }

    /** Ids de contas administrativas alvo, a partir dos papéis escolhidos. */
    @SuppressWarnings("unchecked")
    @Transactional(readOnly = true)
    public List<UUID> resolveAdmins(JsonNode audience) {
        List<String> roles = strings(audience, "adminRoles", ADMIN_ROLES, "AUDIENCE_ROLE_INVALID");
        if (roles.isEmpty()) return List.of();
        var query = entityManager.createNativeQuery(
                "SELECT a.id FROM admin_accounts a WHERE a.is_active = true AND a.role = ANY(CAST(:roles AS text[])) ORDER BY a.email");
        query.setParameter("roles", pgArray(roles));
        var result = new ArrayList<UUID>();
        for (Object id : (List<Object>) query.getResultList()) result.add(asUuid(id));
        return result;
    }

    /**
     * Cursos cadastrados hoje, com busca tolerante a erro de digitação e a
     * acento — "engharia civil" encontra "Engenharia Civil". Enquanto
     * {@code users.course} for texto livre, a lista sai de um DISTINCT; quando
     * virar entidade própria, só troca a origem.
     */
    @SuppressWarnings("unchecked")
    @Transactional(readOnly = true)
    public List<Map<String, Object>> courses(String query) {
        String term = query == null ? "" : query.trim();
        var sql = entityManager.createNativeQuery("""
                SELECT u.course, COUNT(*) AS people
                FROM users u
                WHERE u.course IS NOT NULL AND btrim(u.course) <> ''
                  AND u.is_active = true AND u.deletion_requested_at IS NULL
                  AND (:empty = true
                       OR similarity(unaccent(lower(u.course)), unaccent(lower(:term))) > 0.20
                       OR unaccent(lower(u.course)) LIKE '%' || unaccent(lower(:term)) || '%')
                GROUP BY u.course
                ORDER BY CASE WHEN :empty = true THEN 0
                              ELSE similarity(unaccent(lower(u.course)), unaccent(lower(:term))) END DESC,
                         u.course
                LIMIT 40
                """);
        sql.setParameter("empty", term.isEmpty());
        sql.setParameter("term", term);
        var result = new ArrayList<Map<String, Object>>();
        for (Object[] row : (List<Object[]>) sql.getResultList())
            result.add(Map.of("course", row[0], "people", ((Number) row[1]).intValue()));
        return result;
    }

    /** Nomes de alguns destinatários, só para a confirmação de envio. */
    @SuppressWarnings("unchecked")
    @Transactional(readOnly = true)
    public List<String> sampleNames(List<UUID> userIds, int limit) {
        if (userIds.isEmpty()) return List.of();
        var query = entityManager.createNativeQuery(
                "SELECT u.full_name FROM users u WHERE u.id = ANY(CAST(:ids AS uuid[])) ORDER BY u.full_name LIMIT :limit");
        query.setParameter("ids", pgArray(userIds.stream().map(UUID::toString).toList()));
        query.setParameter("limit", limit);
        return (List<String>) query.getResultList();
    }

    private List<String> strings(JsonNode audience, String field, Set<String> allowed, String errorCode) {
        var node = audience.path(field);
        if (!node.isArray()) return List.of();
        var values = new ArrayList<String>();
        for (JsonNode item : node) {
            String value = item.asText("").trim();
            if (value.isEmpty()) continue;
            if (allowed != null && !allowed.contains(value))
                throw new ApiException(HttpStatus.BAD_REQUEST, errorCode, "Filtro de público inválido: " + value);
            values.add(value);
        }
        return values;
    }

    private List<UUID> uuids(JsonNode audience, String field) {
        var node = audience.path(field);
        if (!node.isArray()) return List.of();
        var values = new ArrayList<UUID>();
        for (JsonNode item : node) {
            try {
                values.add(UUID.fromString(item.asText("")));
            } catch (IllegalArgumentException error) {
                throw new ApiException(HttpStatus.BAD_REQUEST, "AUDIENCE_ID_INVALID", "Identificador inválido no público-alvo.");
            }
        }
        return values;
    }

    /** Literal de array do Postgres: {a,b,c}. Vazio vira {} e nunca casa. */
    private String pgArray(List<String> values) {
        return values.stream().map(v -> "\"" + v.replace("\\", "\\\\").replace("\"", "\\\"") + "\"")
                .reduce((a, b) -> a + "," + b).map(joined -> "{" + joined + "}").orElse("{}");
    }

    private UUID asUuid(Object value) {
        return value instanceof UUID uuid ? uuid : UUID.fromString(value.toString());
    }
}
