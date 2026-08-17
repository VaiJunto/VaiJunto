package com.vaijunto.domain.entities;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import java.time.OffsetDateTime;
import java.util.*;

@Entity @Table(name = "conversation_messages") @Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ConversationMessage {
 @Id @GeneratedValue(strategy = GenerationType.UUID) private UUID id;
 @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "conversation_id", nullable = false) private Conversation conversation;
 @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "sender_id") private User sender;
 @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "admin_sender_id") private AdminAccount adminSender;
 @Column(name = "client_id", nullable = false) private UUID clientId;
 @Column(nullable = false) private String kind;
 @Column(columnDefinition = "text") private String body;
 // O driver JDBC manda String como varchar e o Postgres recusa gravar varchar em
 // coluna jsonb ("column is of type jsonb but expression is of type character
 // varying"). O cast explícito no write resolve sem trocar o tipo Java.
 @Column(name = "location_json", columnDefinition = "jsonb")
 @org.hibernate.annotations.ColumnTransformer(write = "cast(? as jsonb)")
 private String locationJson;
 @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "reply_to_id") private ConversationMessage replyTo;
 @CreationTimestamp @Column(name = "sent_at", nullable = false, updatable = false) private OffsetDateTime sentAt;
 @Column(name = "delivered_at") private OffsetDateTime deliveredAt;
 @Column(name = "read_at") private OffsetDateTime readAt;
 @Column(name = "edited_at") private OffsetDateTime editedAt;
 @Column(name = "deleted_at") private OffsetDateTime deletedAt;
 @OneToMany(mappedBy = "message", fetch = FetchType.LAZY) @Builder.Default private List<MediaObject> media = new ArrayList<>();
}
