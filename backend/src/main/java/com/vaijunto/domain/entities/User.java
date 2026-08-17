package com.vaijunto.domain.entities;

import com.vaijunto.domain.converters.ProfileTypeSetConverter;
import com.vaijunto.domain.enums.ProfileType;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.OffsetDateTime;
import java.util.EnumSet;
import java.util.Set;
import java.util.UUID;

@Entity
@Table(name = "users")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false)
    private String name;

    @Column(name = "full_name", nullable = false)
    private String fullName;

    @Column
    private String course;

    /**
     * Vínculo com a instituição (STUDENT, PROFESSOR, STAFF). Eixo independente
     * de {@link #profileTypes}: um professor também pode ser motorista. Fica
     * nulo até existir o cadastro que preenche isso — a segmentação de
     * newsletter já filtra por ele.
     */
    @Column
    private String affiliation;

    @Column(name = "photo_url")
    private String photoUrl;

    @Column(name = "verification_badge_active", nullable = false)
    @Builder.Default
    private Boolean verificationBadgeActive = false;

    @Column(name = "verification_status", nullable = false)
    @Builder.Default
    private String verificationStatus = "NOT_VERIFIED";

    @Column(name = "verification_note")
    private String verificationNote;

    @Column(name = "warned_at")
    private OffsetDateTime warnedAt;

    @Column(name = "warning_reason")
    private String warningReason;

    @Column(name = "suspended_at")
    private OffsetDateTime suspendedAt;

    @Column(name = "suspension_reason")
    private String suspensionReason;

    @Column(name = "deletion_requested_at")
    private OffsetDateTime deletionRequestedAt;

    @Column(name = "anonymized_at")
    private OffsetDateTime anonymizedAt;

    @Column(name = "requested_full_name")
    private String requestedFullName;

    @Column(name = "name_change_status")
    private String nameChangeStatus;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(name = "password_hash", nullable = false)
    private String password;

    @Column
    private String phone;

    @Convert(converter = ProfileTypeSetConverter.class)
    @Column(name = "profile_types", nullable = false)
    @Builder.Default
    private Set<ProfileType> profileTypes = EnumSet.of(ProfileType.PASSENGER);

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "university_id")
    private University university;

    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private Boolean isActive = true;

    /**
     * Confirmou o código enviado por e-mail no cadastro. Distinto de
     * {@link #isActive} de propósito: uma conta pode existir (isActive) sem
     * ainda ter provado que o e-mail institucional é real.
     */
    @Column(name = "email_verified", nullable = false)
    @Builder.Default
    private Boolean emailVerified = false;

    @Column(name = "notification_hide_content", nullable = false)
    @Builder.Default
    private Boolean notificationHideContent = false;

    @Column(name = "notification_mute_chat", nullable = false)
    @Builder.Default
    private Boolean notificationMuteChat = false;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private OffsetDateTime updatedAt;
}
