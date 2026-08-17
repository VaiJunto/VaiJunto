package com.vaijunto.domain.entities;
import jakarta.persistence.*; import lombok.*; import org.hibernate.annotations.ColumnTransformer; import org.hibernate.annotations.CreationTimestamp; import org.hibernate.annotations.UpdateTimestamp; import java.time.OffsetDateTime; import java.util.UUID;

/**
 * Newsletter administrativa: título + componentes ordenados (texto, título,
 * imagem, áudio, vídeo, divisor, botão) + aparência do embed + público-alvo.
 * Depois de enviada é imutável — o app busca por id para renderizar, então
 * editar aqui mudaria o que já está na mão de quem recebeu.
 */
@Entity @Table(name="admin_newsletters") @Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class AdminNewsletter {
 @Id @GeneratedValue(strategy=GenerationType.UUID) private UUID id;
 @ManyToOne(fetch=FetchType.LAZY) @JoinColumn(name="created_by",nullable=false) private AdminAccount createdBy;
 @Column(nullable=false,length=160) private String title;
 // Ver ConversationMessage.locationJson: String vai como varchar e o Postgres
 // recusa gravar em coluna jsonb sem cast explícito.
 @Column(nullable=false,columnDefinition="jsonb") @ColumnTransformer(write="cast(? as jsonb)") private String components;
 @Column(nullable=false,columnDefinition="jsonb") @ColumnTransformer(write="cast(? as jsonb)") private String settings;
 @Column(nullable=false,columnDefinition="jsonb") @ColumnTransformer(write="cast(? as jsonb)") private String audience;
 @Column(nullable=false) private String status;
 @Column(name="scheduled_for") private OffsetDateTime scheduledFor;
 @Column(name="sent_at") private OffsetDateTime sentAt;
 @Column(name="recipient_count",nullable=false) @Builder.Default private int recipientCount=0;
 @Column(name="failure_reason",length=500) private String failureReason;
 @CreationTimestamp @Column(name="created_at",nullable=false,updatable=false) private OffsetDateTime createdAt;
 @UpdateTimestamp @Column(name="updated_at",nullable=false) private OffsetDateTime updatedAt;
}
