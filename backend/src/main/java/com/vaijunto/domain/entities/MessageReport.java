package com.vaijunto.domain.entities;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import java.time.OffsetDateTime;
import java.util.*;
@Entity @Table(name="message_reports") @Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class MessageReport { @Id @GeneratedValue(strategy=GenerationType.UUID) private UUID id; @ManyToOne(fetch=FetchType.LAZY) @JoinColumn(name="reporter_id",nullable=false) private User reporter; @ManyToOne(fetch=FetchType.LAZY) @JoinColumn(name="conversation_id",nullable=false) private Conversation conversation; @Column(nullable=false) @Builder.Default private String status="ENVIADA"; @ManyToMany @JoinTable(name="message_report_items",joinColumns=@JoinColumn(name="report_id"),inverseJoinColumns=@JoinColumn(name="message_id")) @Builder.Default private Set<ConversationMessage> messages=new LinkedHashSet<>(); @CreationTimestamp @Column(name="created_at",nullable=false,updatable=false) private OffsetDateTime createdAt; }
