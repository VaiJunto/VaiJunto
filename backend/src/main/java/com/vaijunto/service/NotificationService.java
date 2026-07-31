package com.vaijunto.service;

import com.google.firebase.FirebaseApp;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import com.vaijunto.domain.entities.Notification;
import com.vaijunto.domain.entities.User;
import com.vaijunto.dto.NotificationDto;
import com.vaijunto.repository.NotificationRepository;
import com.vaijunto.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final UserRepository userRepository;

    @Transactional
    public void createAndSendNotification(UUID userId, String title, String body, String type, String payloadJson, String deviceToken) {
        User user = userRepository.findById(userId).orElse(null);
        if (user == null) return;

        Notification notification = Notification.builder()
                .user(user)
                .type(type)
                .payload(payloadJson)
                .isRead(false)
                .build();
        
        notificationRepository.save(notification);

        sendPushNotification(deviceToken, title, body, type);
    }

    private void sendPushNotification(String deviceToken, String title, String body, String type) {
        if (deviceToken == null || deviceToken.isEmpty()) {
            return; // Usuário sem token de dispositivo
        }

        try {
            if (!FirebaseApp.getApps().isEmpty()) {
                Message message = Message.builder()
                        .setToken(deviceToken)
                        .putData("title", title)
                        .putData("body", body)
                        .putData("type", type)
                        .build();

                String response = FirebaseMessaging.getInstance().send(message);
                log.info("Notificação Push (FCM) enviada com sucesso. ID: {}", response);
            } else {
                log.debug("Simulando envio de push notification (FCM inativo): Titulo={}, Body={}", title, body);
            }
        } catch (Exception e) {
            log.error("Falha ao enviar notificação Push (FCM): {}", e.getMessage());
        }
    }

    public List<NotificationDto> getUnreadNotifications(UUID userId) {
        return notificationRepository.findByUserIdAndIsReadFalseOrderByCreatedAtDesc(userId)
                .stream()
                .map(this::mapToDto)
                .collect(Collectors.toList());
    }

    @Transactional
    public void markAsRead(UUID notificationId) {
        notificationRepository.findById(notificationId).ifPresent(n -> {
            n.setIsRead(true);
            notificationRepository.save(n);
        });
    }

    private NotificationDto mapToDto(Notification n) {
        return NotificationDto.builder()
                .id(n.getId())
                .type(n.getType())
                .payload(n.getPayload())
                .isRead(n.getIsRead())
                .createdAt(n.getCreatedAt())
                .build();
    }
}
