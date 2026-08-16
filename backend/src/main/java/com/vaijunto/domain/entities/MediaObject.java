package com.vaijunto.domain.entities;
import jakarta.persistence.*; import lombok.*; import org.hibernate.annotations.CreationTimestamp; import org.hibernate.annotations.UpdateTimestamp; import java.time.OffsetDateTime; import java.util.UUID;
@Entity @Table(name="media_objects") @Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder public class MediaObject {
 @Id @GeneratedValue(strategy=GenerationType.UUID) private UUID id;
 @ManyToOne(fetch=FetchType.LAZY) @JoinColumn(name="owner_id",nullable=false) private User owner;
 @ManyToOne(fetch=FetchType.LAZY) @JoinColumn(name="conversation_id") private Conversation conversation;
 @ManyToOne(fetch=FetchType.LAZY) @JoinColumn(name="message_id") private ConversationMessage message;
 @Column(name="storage_key",nullable=false) private String storageKey; @Column(nullable=false) private String category; @Column(name="content_type",nullable=false) private String contentType; @Column(name="size_bytes",nullable=false) private long sizeBytes; @Column(name="duration_seconds") private Integer durationSeconds; @Column(nullable=false) private String status; @Column(name="delete_after") private OffsetDateTime deleteAfter; @Column(name="deleted_at") private OffsetDateTime deletedAt; @Column(name="deleted_reason") private String deletedReason; @CreationTimestamp @Column(name="created_at",nullable=false,updatable=false) private OffsetDateTime createdAt; @UpdateTimestamp @Column(name="updated_at",nullable=false) private OffsetDateTime updatedAt;
 public void setMessage(ConversationMessage message){this.message=message;if(message!=null&&!message.getMedia().contains(this))message.getMedia().add(this);}
}
