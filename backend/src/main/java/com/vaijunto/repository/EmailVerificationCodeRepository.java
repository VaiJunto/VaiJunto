package com.vaijunto.repository;

import com.vaijunto.domain.entities.EmailVerificationCode;
import com.vaijunto.domain.enums.VerificationCodePurpose;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface EmailVerificationCodeRepository extends JpaRepository<EmailVerificationCode, UUID> {

    Optional<EmailVerificationCode> findFirstByUserIdAndPurposeOrderByCreatedAtDesc(
            UUID userId, VerificationCodePurpose purpose);
}
