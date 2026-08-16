package com.vaijunto.dto;
import jakarta.validation.constraints.*; import java.util.UUID;
public record MediaUploadIntentRequest(@NotBlank String category, UUID conversationId, @NotBlank @Size(max=100) String contentType, @Positive long sizeBytes, @PositiveOrZero Integer durationSeconds) {}
