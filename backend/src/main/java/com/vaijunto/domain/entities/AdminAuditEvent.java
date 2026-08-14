package com.vaijunto.domain.entities;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity @Table(name = "admin_audit_events")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class AdminAuditEvent {
    @Id @GeneratedValue(strategy = GenerationType.UUID) private UUID id;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "admin_id") private AdminAccount admin;
    @Column(name = "event_type", nullable = false) private String eventType;
    @Column(name = "target_type") private String targetType;
    @Column(name = "target_id") private String targetId;
    @CreationTimestamp @Column(name = "created_at", updatable = false) private OffsetDateTime createdAt;
}
