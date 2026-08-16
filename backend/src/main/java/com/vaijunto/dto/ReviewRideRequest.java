package com.vaijunto.dto;
import jakarta.validation.constraints.Max; import jakarta.validation.constraints.Min; import java.util.UUID;
public record ReviewRideRequest(UUID revieweeId, @Min(1) @Max(5) Integer rating) {}
