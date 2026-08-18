package com.vaijunto.service;

import com.vaijunto.dto.RealtimeEventDto;
import java.util.Collection;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

@Service
@RequiredArgsConstructor
public class RealtimeEventPublisher {
    private final SimpMessagingTemplate messaging;

    public void afterCommit(Collection<String> recipients, RealtimeEventDto event) {
        Runnable publish = () -> recipients.stream()
                .filter(email -> email != null && !email.isBlank()).distinct()
                .forEach(email -> messaging.convertAndSendToUser(email, "/queue/events", event));
        if (TransactionSynchronizationManager.isSynchronizationActive()) {
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override public void afterCommit() { publish.run(); }
            });
        } else {
            publish.run();
        }
    }
}
