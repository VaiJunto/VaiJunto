package com.vaijunto.dto;

import jakarta.validation.constraints.NotBlank;

public record OfficialActionRequest(@NotBlank String action) {}
