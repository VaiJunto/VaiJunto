package com.vaijunto.controller;

import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

import com.vaijunto.dto.LiveLocationMessage;
import com.vaijunto.dto.TypingMessage;
import com.vaijunto.service.ConversationService;
import java.security.Principal;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.messaging.simp.SimpMessagingTemplate;

@ExtendWith(MockitoExtension.class)
class ChatRealtimeControllerTest {
 @Mock ConversationService conversations;
 @Mock SimpMessagingTemplate messaging;
 @Mock Principal principal;
 @InjectMocks ChatRealtimeController controller;

 @Test void typingIsForwardedOnlyToOtherParticipant() {
  UUID conversationId=UUID.randomUUID(); when(principal.getName()).thenReturn("a@fatec.sp.gov.br");
  when(conversations.otherParticipantEmail(conversationId,"a@fatec.sp.gov.br")).thenReturn("b@fatec.sp.gov.br");
  TypingMessage message=new TypingMessage(conversationId,true);
  controller.typing(message,principal);
  verify(messaging).convertAndSendToUser("b@fatec.sp.gov.br","/queue/chat/typing",message);
 }

 @Test void expiredLiveLocationIsDiscarded() {
  controller.location(new LiveLocationMessage(UUID.randomUUID(),-23.2,-45.9,System.currentTimeMillis()-1),principal);
  verifyNoInteractions(conversations,messaging);
 }
}
