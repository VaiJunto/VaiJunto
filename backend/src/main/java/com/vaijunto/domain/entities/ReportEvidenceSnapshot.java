package com.vaijunto.domain.entities;

import jakarta.persistence.*;
import java.time.OffsetDateTime;
import java.util.UUID;
import lombok.*;

@Entity
@Table(name = "report_evidence_snapshots")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ReportEvidenceSnapshot {
    @Id @GeneratedValue(strategy = GenerationType.UUID) private UUID id;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "report_id", nullable = false) private MessageReport report;
    @Column(name = "original_message_id", nullable = false) private UUID originalMessageId;
    @Column(name = "sender_id", nullable = false) private UUID senderId;
    @Column(nullable = false) private String kind;
    @Column(columnDefinition = "text") private String body;
    @Column(name = "location_json", columnDefinition = "text") private String locationJson;
    @Column(name = "sent_at", nullable = false) private OffsetDateTime sentAt;
    @Column(name = "media_ids_json", nullable = false, columnDefinition = "text") private String mediaIdsJson;
    @Column(name = "created_at", nullable = false) private OffsetDateTime createdAt;
}
