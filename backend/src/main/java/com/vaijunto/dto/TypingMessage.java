package com.vaijunto.dto;
import java.util.UUID;
public record TypingMessage(UUID conversationId, boolean typing) {}
