package com.vaijunto.domain.entities;

import jakarta.persistence.*;
import lombok.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity @Table(name = "admin_user_tags") @Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class AdminUserTag {
 @Id @GeneratedValue(strategy = GenerationType.UUID) private UUID id;
 @Column(nullable = false, unique = true, length = 48) private String name;
 @Column(nullable = false, length = 9) private String color;
 @Column(name = "icon_svg", nullable = false, columnDefinition = "text") private String iconSvg;
 @Column(name = "created_at", nullable = false) @Builder.Default private OffsetDateTime createdAt = OffsetDateTime.now();
}
