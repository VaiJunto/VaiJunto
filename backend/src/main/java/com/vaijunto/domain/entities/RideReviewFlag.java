package com.vaijunto.domain.entities;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import java.time.OffsetDateTime;
import java.util.UUID;

/** Fila explícita para revisão humana; não altera permissão nem aplica punição. */
@Entity @Table(name = "ride_review_flags") @Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RideReviewFlag {
    @Id @GeneratedValue(strategy = GenerationType.UUID) private UUID id;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "user_id", nullable = false) private User user;
    @Column(nullable = false) private String reason;
    @Column(nullable = false) @Builder.Default private String status = "PENDING";
    @CreationTimestamp @Column(name = "created_at", nullable = false, updatable = false) private OffsetDateTime createdAt;
}
