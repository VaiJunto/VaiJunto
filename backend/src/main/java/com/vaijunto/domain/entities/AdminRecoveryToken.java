package com.vaijunto.domain.entities;
import jakarta.persistence.*; import lombok.*; import java.time.OffsetDateTime; import java.util.UUID;
@Entity @Table(name="admin_recovery_tokens") @Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder public class AdminRecoveryToken {
 @Id @GeneratedValue(strategy=GenerationType.UUID) private UUID id; @ManyToOne(fetch=FetchType.LAZY) @JoinColumn(name="admin_id") private AdminAccount admin;
 @Column(name="token_hash") private String tokenHash; @Column(name="expires_at") private OffsetDateTime expiresAt; @Column(name="consumed_at") private OffsetDateTime consumedAt;
 public boolean usable(){return consumedAt==null && expiresAt.isAfter(OffsetDateTime.now());}
}
