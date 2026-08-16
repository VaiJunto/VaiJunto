package com.vaijunto.dto;
import jakarta.validation.constraints.*;
import java.util.*;
public record ReportMessagesRequest(@NotEmpty @Size(max=50) List<UUID> messageIds) {}
