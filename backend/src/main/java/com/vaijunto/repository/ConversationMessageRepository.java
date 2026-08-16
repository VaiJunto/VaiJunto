package com.vaijunto.repository;
import com.vaijunto.domain.entities.ConversationMessage;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.*;
public interface ConversationMessageRepository extends JpaRepository<ConversationMessage, UUID> {
 List<ConversationMessage> findByConversationIdOrderBySentAtAsc(UUID conversationId);
 Optional<ConversationMessage> findByConversationIdAndClientId(UUID conversationId, UUID clientId);
}
