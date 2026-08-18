package com.vaijunto.dto;

import java.time.OffsetDateTime;
import java.util.Map;
import java.util.UUID;

public record RealtimeEventDto(int version, UUID eventId, String type,
        OffsetDateTime occurredAt, String resourceType, String resourceId,
        Map<String, Object> payload) {
    public static RealtimeEventDto create(String type, String resourceType,
            Object resourceId, Map<String, Object> payload) {
        return new RealtimeEventDto(1, UUID.randomUUID(), type,
                OffsetDateTime.now(), resourceType,
                resourceId == null ? null : resourceId.toString(), payload);
    }
}
