package com.vaijunto.dto;

import jakarta.validation.constraints.NotNull;
import java.util.UUID;

public record LiveLocationMessage(
        @NotNull UUID conversationId,
        double latitude,
        double longitude,
        long expiresAtEpochMs) {}
