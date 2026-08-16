package com.vaijunto.repository;
import com.vaijunto.domain.entities.RideReview; import org.springframework.data.jpa.repository.JpaRepository; import java.util.UUID;
public interface RideReviewRepository extends JpaRepository<RideReview, UUID> { boolean existsByTripIdAndReviewerIdAndRevieweeId(UUID tripId, UUID reviewerId, UUID revieweeId); }
