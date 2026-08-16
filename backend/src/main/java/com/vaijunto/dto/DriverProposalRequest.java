package com.vaijunto.dto;

import jakarta.validation.constraints.NotNull;
import java.util.UUID;

public record DriverProposalRequest(@NotNull UUID demandId) {}
