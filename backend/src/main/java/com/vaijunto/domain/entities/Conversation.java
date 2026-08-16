package com.vaijunto.domain.entities;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity @Table(name = "conversations") @Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Conversation {
 @Id @GeneratedValue(strategy = GenerationType.UUID) private UUID id;
 @Column(nullable = false) private String type;
 @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "ride_id") private TripInstance ride;
 @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "participant_a_id") private User participantA;
 @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "participant_b_id") private User participantB;
 @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "admin_account_id") private AdminAccount adminAccount;
 @Column(name = "archived_at") private OffsetDateTime archivedAt;
 @Column(name = "read_only_at") private OffsetDateTime readOnlyAt;
 @Column(name = "last_activity_at", nullable = false) private OffsetDateTime lastActivityAt;
 @CreationTimestamp @Column(name = "created_at", nullable = false, updatable = false) private OffsetDateTime createdAt;
 @UpdateTimestamp @Column(name = "updated_at", nullable = false) private OffsetDateTime updatedAt;
}
