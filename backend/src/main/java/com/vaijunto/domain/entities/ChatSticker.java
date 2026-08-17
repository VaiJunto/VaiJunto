package com.vaijunto.domain.entities;

import jakarta.persistence.*;
import java.time.OffsetDateTime;
import java.util.UUID;
import lombok.*;

@Entity @Table(name = "chat_stickers") @Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ChatSticker {
 @Id @GeneratedValue(strategy = GenerationType.UUID) private UUID id;
 @Column(nullable = false, unique = true) private String code;
 @Column(nullable = false) private String label;
 @Column(name = "storage_key", nullable = false) private String storageKey;
 @Column(name = "content_type", nullable = false) private String contentType;
 @Column(nullable = false) private boolean active;
 @Column(name = "created_at", nullable = false) private OffsetDateTime createdAt;
}
