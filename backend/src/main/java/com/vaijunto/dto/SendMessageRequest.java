package com.vaijunto.dto;
import jakarta.validation.constraints.*;
import java.util.UUID;
public record SendMessageRequest(@NotNull UUID clientId, @NotBlank @Size(max=20) String kind, @Size(max=4000) String body, String locationJson, UUID replyToId, @Size(max=5) java.util.List<UUID> mediaIds) {}
