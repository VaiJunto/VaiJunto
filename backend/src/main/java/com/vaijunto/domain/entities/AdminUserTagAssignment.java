package com.vaijunto.domain.entities;

import jakarta.persistence.*;
import lombok.*;
import java.time.OffsetDateTime;

@Entity @Table(name = "admin_user_tag_assignments") @Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class AdminUserTagAssignment {
 @EmbeddedId private AdminUserTagAssignmentId id;
 @ManyToOne(fetch = FetchType.LAZY) @MapsId("userId") @JoinColumn(name = "user_id") private User user;
 @ManyToOne(fetch = FetchType.LAZY) @MapsId("tagId") @JoinColumn(name = "tag_id") private AdminUserTag tag;
 @Column(name = "assigned_at", nullable = false) @Builder.Default private OffsetDateTime assignedAt = OffsetDateTime.now();
}
