package com.vaijunto.controller;

import com.vaijunto.dto.LiveLocationMessage;
import com.vaijunto.dto.TypingMessage;
import com.vaijunto.service.ConversationService;
import java.security.Principal;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Controller;

@Controller
@RequiredArgsConstructor
public class ChatRealtimeController {
    private final ConversationService conversations;
    private final SimpMessagingTemplate messaging;

    @MessageMapping("/chat/typing")
    public void typing(TypingMessage message, Principal principal) {
        if (principal == null) return;
        String recipient = conversations.otherParticipantEmail(message.conversationId(), principal.getName());
        messaging.convertAndSendToUser(recipient, "/queue/chat/typing", message);
    }

    @MessageMapping("/chat/location")
    public void location(LiveLocationMessage message, Principal principal) {
        long now = System.currentTimeMillis();
        if (principal == null || message.expiresAtEpochMs() < now
                || message.expiresAtEpochMs() > now + 60L * 60L * 1000L) return;
        String recipient = conversations.otherParticipantEmail(message.conversationId(), principal.getName());
        messaging.convertAndSendToUser(recipient, "/queue/chat/location", message);
    }
}
