package com.vaijunto.dto;

import lombok.*;

import java.time.OffsetDateTime;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class NotificationDto {
    private UUID id;
    private String type;
    private String title;
    private String body;
    private String payload;
    private Boolean isRead;
    private OffsetDateTime createdAt;
}
