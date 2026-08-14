package com.vaijunto.domain.entities;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.OffsetDateTime;
import java.util.UUID;

/**
 * Device que já passou pelo desafio de e-mail no primeiro login (MFA de
 * primeiro acesso). Enquanto o {@code deviceId} salvo no app bater com um
 * registro aqui, o login segue direto pro JWT sem pedir código de novo.
 */
@Entity
@Table(name = "known_devices", uniqueConstraints = @UniqueConstraint(columnNames = {"user_id", "device_id"}))
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class KnownDevice {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "device_id", nullable = false, length = 100)
    private String deviceId;

    @Column(name = "last_seen_at", nullable = false)
    private OffsetDateTime lastSeenAt;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;
}
