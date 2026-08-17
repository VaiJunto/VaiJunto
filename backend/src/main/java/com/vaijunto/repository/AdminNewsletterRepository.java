package com.vaijunto.repository;
import com.vaijunto.domain.entities.AdminNewsletter;
import java.time.OffsetDateTime;
import java.util.*;
import org.springframework.data.jpa.repository.JpaRepository;
public interface AdminNewsletterRepository extends JpaRepository<AdminNewsletter, UUID> {
 List<AdminNewsletter> findTop50ByOrderByCreatedAtDesc();
 List<AdminNewsletter> findByStatusAndScheduledForLessThanEqual(String status, OffsetDateTime until);
}
