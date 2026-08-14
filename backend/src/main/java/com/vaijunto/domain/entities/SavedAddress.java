package com.vaijunto.domain.entities;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity @Table(name = "saved_addresses") @Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class SavedAddress {
 @Id @GeneratedValue(strategy = GenerationType.UUID) private UUID id;
 @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "user_id", nullable = false) private User user;
 @Column(nullable = false) private String label;
 @Column(name = "address_name", nullable = false) private String addressName;
 @Column(nullable = false) private double latitude;
 @Column(nullable = false) private double longitude;
 @Column(name = "is_recent", nullable = false) @Builder.Default private boolean recent = false;
 @Column(name = "last_used_at") private OffsetDateTime lastUsedAt;
 @Column(name = "expires_at") private OffsetDateTime expiresAt;
 @Column(name = "deleted_at") private OffsetDateTime deletedAt;
 @CreationTimestamp @Column(name = "created_at", nullable = false, updatable = false) private OffsetDateTime createdAt;
 @UpdateTimestamp @Column(name = "updated_at", nullable = false) private OffsetDateTime updatedAt;
}
