package com.vaijunto.dto;
import jakarta.validation.constraints.NotBlank;
public record DeviceTokenRequest(@NotBlank String token) {}
