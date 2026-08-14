package com.vaijunto.domain.entities;

import com.vaijunto.domain.enums.VerificationCodePurpose;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "email_verification_codes")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class EmailVerificationCode {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false, length = 6)
    private String code;

    /**
     * Pra qual fluxo este código serve — cadastro (confirmar e-mail) ou
     * desafio de primeiro login num device novo. Sem isso, a consulta "código
     * mais recente do usuário" poderia devolver o código errado quando os
     * dois fluxos coexistem (ex: reenvio de device-challenge logo após um
     * cadastro recém-confirmado).
     */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    @Builder.Default
    private VerificationCodePurpose purpose = VerificationCodePurpose.EMAIL_VERIFICATION;

    @Column(name = "expires_at", nullable = false)
    private OffsetDateTime expiresAt;

    @Column(name = "consumed_at")
    private OffsetDateTime consumedAt;

    @Column(nullable = false)
    @Builder.Default
    private Integer attempts = 0;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    @Transient
    public boolean isExpired() {
        return OffsetDateTime.now().isAfter(expiresAt);
    }

    @Transient
    public boolean isConsumed() {
        return consumedAt != null;
    }
}
