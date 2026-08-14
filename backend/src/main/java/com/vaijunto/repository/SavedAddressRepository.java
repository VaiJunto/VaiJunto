package com.vaijunto.repository;
import com.vaijunto.domain.entities.SavedAddress;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import java.time.OffsetDateTime; import java.util.*;
public interface SavedAddressRepository extends JpaRepository<SavedAddress, UUID> {
 @Query("select a from SavedAddress a where a.user.id=:userId and a.deletedAt is null and (a.recent=false or a.expiresAt>:now) order by a.recent asc, a.lastUsedAt desc nulls last, a.createdAt desc")
 List<SavedAddress> findVisible(@Param("userId") UUID userId, @Param("now") OffsetDateTime now);
 long countByUserIdAndRecentFalseAndDeletedAtIsNull(UUID userId);
 @Modifying @Query("update SavedAddress a set a.deletedAt=:now where a.user.id=:userId and a.recent=true and a.deletedAt is null")
 int clearRecents(@Param("userId") UUID userId, @Param("now") OffsetDateTime now);
}
