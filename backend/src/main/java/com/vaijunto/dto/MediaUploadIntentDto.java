package com.vaijunto.dto;
import java.time.OffsetDateTime; import java.util.UUID;
public record MediaUploadIntentDto(UUID id,String uploadUrl,OffsetDateTime uploadUrlExpiresAt) {}
