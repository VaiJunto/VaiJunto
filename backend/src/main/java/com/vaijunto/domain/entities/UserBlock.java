package com.vaijunto.domain.entities;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity @Table(name = "user_blocks", uniqueConstraints = @UniqueConstraint(columnNames = {"user_low_id", "user_high_id"}))
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class UserBlock {
 @Id @GeneratedValue(strategy = GenerationType.UUID) private UUID id;
 @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "user_low_id", nullable = false) private User userLow;
 @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "user_high_id", nullable = false) private User userHigh;
 @CreationTimestamp @Column(name = "created_at", nullable = false, updatable = false) private OffsetDateTime createdAt;
}
