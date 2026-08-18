package com.vaijunto.dto;

import java.time.OffsetDateTime;

public record MediaDownloadUrlDto(String url, OffsetDateTime expiresAt) {}
