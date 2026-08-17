package com.vaijunto.repository;
import com.vaijunto.domain.entities.AdminNewsletterRecipient;
import java.util.*;
import org.springframework.data.jpa.repository.JpaRepository;
public interface AdminNewsletterRecipientRepository extends JpaRepository<AdminNewsletterRecipient, UUID> {
 Optional<AdminNewsletterRecipient> findByNewsletterIdAndUserId(UUID newsletterId, UUID userId);
 Optional<AdminNewsletterRecipient> findByNewsletterIdAndAdminId(UUID newsletterId, UUID adminId);
 List<AdminNewsletterRecipient> findTop50ByAdminIdOrderByCreatedAtDesc(UUID adminId);
 long countByNewsletterIdAndReadAtIsNotNull(UUID newsletterId);
}
