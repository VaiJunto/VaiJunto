package com.vaijunto.repository;
import com.vaijunto.domain.entities.Conversation;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import java.util.*;
public interface ConversationRepository extends JpaRepository<Conversation, UUID> {
 @Query("select c from Conversation c where (c.participantA.id=:userId or c.participantB.id=:userId) order by case when c.archivedAt is null then 0 else 1 end, c.lastActivityAt desc")
 List<Conversation> findForUser(@Param("userId") UUID userId);
}
