package com.vaijunto.domain.entities;
import jakarta.persistence.*; import lombok.*; import java.time.OffsetDateTime; import java.util.UUID;
@Entity @Table(name="admin_invites") @Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder public class AdminInvite {
 @Id @GeneratedValue(strategy=GenerationType.UUID) private UUID id; private String email; private String role;
 @Column(name="token_hash") private String tokenHash; @Column(name="expires_at") private OffsetDateTime expiresAt; @Column(name="consumed_at") private OffsetDateTime consumedAt;
 @ManyToOne(fetch=FetchType.LAZY) @JoinColumn(name="invited_by") private AdminAccount invitedBy;
 public boolean usable(){return consumedAt==null && expiresAt.isAfter(OffsetDateTime.now());}
}
