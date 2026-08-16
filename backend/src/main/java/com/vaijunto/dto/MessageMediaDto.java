package com.vaijunto.dto;

import com.vaijunto.domain.entities.MediaObject;
import java.util.UUID;

public record MessageMediaDto(UUID id, String contentType, long sizeBytes, Integer durationSeconds) {
    public static MessageMediaDto from(MediaObject media) {
        return new MessageMediaDto(media.getId(), media.getContentType(), media.getSizeBytes(), media.getDurationSeconds());
    }
}
