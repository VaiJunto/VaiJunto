package com.vaijunto.repository;
import com.vaijunto.domain.entities.Conversation;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import java.util.*;
public interface ConversationRepository extends JpaRepository<Conversation, UUID> {
 @Query("select c from Conversation c where (c.participantA.id=:userId or c.participantB.id=:userId) order by case when c.archivedAt is null then 0 else 1 end, c.lastActivityAt desc")
 List<Conversation> findForUser(@Param("userId") UUID userId);
 boolean existsByRideIdAndParticipantAIdAndParticipantBId(UUID rideId, UUID participantAId, UUID participantBId);
 @Query("select c from Conversation c where (c.participantA.id=:a and c.participantB.id=:b) or (c.participantA.id=:b and c.participantB.id=:a)") List<Conversation> findBetween(@Param("a") UUID a,@Param("b") UUID b);
 @Query("select c from Conversation c where c.type='ADMINISTRATIVE' and c.participantA.id=:userId and c.adminAccount.id=:adminId") Optional<Conversation> findAdministrative(@Param("userId") UUID userId,@Param("adminId") UUID adminId);
}
