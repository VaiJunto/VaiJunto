package com.vaijunto.domain.entities;
import jakarta.persistence.*; import lombok.*; import org.hibernate.annotations.CreationTimestamp; import java.time.OffsetDateTime; import java.util.UUID;

/** Entrega de uma newsletter. Exatamente um entre user e admin é preenchido. */
@Entity @Table(name="admin_newsletter_recipients") @Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class AdminNewsletterRecipient {
 @Id @GeneratedValue(strategy=GenerationType.UUID) private UUID id;
 @ManyToOne(fetch=FetchType.LAZY) @JoinColumn(name="newsletter_id",nullable=false) private AdminNewsletter newsletter;
 @ManyToOne(fetch=FetchType.LAZY) @JoinColumn(name="user_id") private User user;
 @ManyToOne(fetch=FetchType.LAZY) @JoinColumn(name="admin_id") private AdminAccount admin;
 @Column(name="read_at") private OffsetDateTime readAt;
 @CreationTimestamp @Column(name="created_at",nullable=false,updatable=false) private OffsetDateTime createdAt;
}
