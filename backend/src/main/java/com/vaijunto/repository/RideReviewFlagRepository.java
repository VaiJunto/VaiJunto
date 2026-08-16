package com.vaijunto.repository;
import com.vaijunto.domain.entities.RideReviewFlag;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.UUID;
public interface RideReviewFlagRepository extends JpaRepository<RideReviewFlag, UUID> { boolean existsByUserIdAndStatus(UUID userId, String status); }
