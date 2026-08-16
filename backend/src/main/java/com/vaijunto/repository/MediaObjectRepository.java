package com.vaijunto.repository;

import com.vaijunto.domain.entities.MediaObject;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface MediaObjectRepository extends JpaRepository<MediaObject, UUID> {
    @Query("select coalesce(sum(m.sizeBytes),0) from MediaObject m where m.status='ACTIVE' and m.deletedAt is null")
    long activeBytes();

    List<MediaObject> findByStatusAndCategoryAndDeleteAfterLessThanEqualOrderByDeleteAfterAsc(
            String status, String category, OffsetDateTime until);

    List<MediaObject> findByStatusAndCategoryAndDeleteAfterIsNullOrderByCreatedAtAsc(
            String status, String category);

    List<MediaObject> findByStatusAndCategoryAndDeleteAfterIsNotNullOrderByDeleteAfterAsc(
            String status, String category);

    List<MediaObject> findByStatusAndCategoryAndDeleteAfterIsNull(String status, String category);

    List<MediaObject> findByStatusAndCreatedAtBefore(String status, OffsetDateTime before);

    Optional<MediaObject> findByIdAndOwnerId(UUID id, UUID ownerId);
}
