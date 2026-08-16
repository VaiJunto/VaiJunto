package com.vaijunto.dto;
import jakarta.validation.constraints.NotBlank; public record CancelOfferRequest(@NotBlank String reason, String note) {}
