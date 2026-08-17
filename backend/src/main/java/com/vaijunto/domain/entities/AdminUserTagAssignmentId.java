package com.vaijunto.domain.entities;

import jakarta.persistence.*;
import lombok.*;
import java.io.Serializable;
import java.util.UUID;

@Embeddable @Getter @Setter @NoArgsConstructor @AllArgsConstructor @EqualsAndHashCode
public class AdminUserTagAssignmentId implements Serializable { @Column(name="user_id") private UUID userId; @Column(name="tag_id") private UUID tagId; }
