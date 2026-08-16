package com.vaijunto.dto;

import jakarta.validation.constraints.Size;

/** O texto de OUTRO fica restrito a auditoria; o parceiro vê apenas a categoria. */
public record CancelParticipationRequest(String reason, @Size(max = 500) String note) {}
