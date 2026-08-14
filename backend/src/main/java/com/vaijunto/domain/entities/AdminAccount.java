package com.vaijunto.domain.entities;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.OffsetDateTime;
import java.util.UUID;

/** Separate credential store: common users can never become administrators by changing a profile type. */
@Entity
@Table(name = "admin_accounts")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class AdminAccount {
    @Id @GeneratedValue(strategy = GenerationType.UUID) private UUID id;
    @Column(nullable = false, unique = true) private String email;
    @Column(name = "password_hash", nullable = false) private String password;
    @Column(nullable = false) private String role;
    @Column(name = "totp_secret", nullable = false) private String totpSecret;
    @Column(name = "is_active", nullable = false) @Builder.Default private Boolean isActive = true;
    @CreationTimestamp @Column(name = "created_at", updatable = false) private OffsetDateTime createdAt;
    @UpdateTimestamp @Column(name = "updated_at") private OffsetDateTime updatedAt;
}
