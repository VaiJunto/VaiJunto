package com.vaijunto.service;

import com.google.firebase.FirebaseApp;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import com.vaijunto.domain.entities.Notification;
import com.vaijunto.domain.entities.User;
import com.vaijunto.domain.entities.NotificationDeviceToken;
import com.vaijunto.dto.NotificationDto;
import com.vaijunto.dto.NotificationPreferencesDto;
import com.vaijunto.dto.UpdateNotificationPreferencesRequest;
import com.vaijunto.repository.NotificationRepository;
import com.vaijunto.repository.UserRepository;
import com.vaijunto.repository.NotificationDeviceTokenRepository;
import com.vaijunto.exception.ApiException;
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
    private final NotificationDeviceTokenRepository deviceTokens;

    @Transactional
    public void createAndSendNotification(UUID userId, String title, String body, String type, String payloadJson, String deviceToken) {
        User user = userRepository.findById(userId).orElse(null);
        if (user == null) return;

        Notification notification = Notification.builder()
                .user(user)
                .type(type)
                .title(title)
                .body(body)
                .payload(payloadJson)
                .isRead(false)
                .build();
        
        notificationRepository.save(notification);

        if (deviceToken != null && !deviceToken.isBlank()) registerDeviceToken(userId, deviceToken);
        if (!("CHAT_MESSAGE".equals(type) && Boolean.TRUE.equals(user.getNotificationMuteChat()))) {
            String pushBody = Boolean.TRUE.equals(user.getNotificationHideContent()) ? "Você tem uma nova notificação do VaiJunto." : body;
            deviceTokens.findByUserId(userId).forEach(token -> sendPushNotification(token.getToken(), title, pushBody, type));
        }
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

    public List<NotificationDto> getNotifications(String email) {
        UUID userId = userRepository.findByEmail(email).orElseThrow(ApiException::userNotFound).getId();
        return notificationRepository.findByUserIdOrderByCreatedAtDesc(userId)
                .stream()
                .map(this::mapToDto)
                .collect(Collectors.toList());
    }

    @Transactional
    public void registerDeviceToken(String email, String token) {
        registerDeviceToken(userRepository.findByEmail(email).orElseThrow(ApiException::userNotFound).getId(), token);
    }

    @Transactional(readOnly = true)
    public NotificationPreferencesDto preferences(String email) { var user=userRepository.findByEmail(email).orElseThrow(ApiException::userNotFound); return new NotificationPreferencesDto(Boolean.TRUE.equals(user.getNotificationHideContent()), Boolean.TRUE.equals(user.getNotificationMuteChat())); }
    @Transactional
    public NotificationPreferencesDto updatePreferences(String email, UpdateNotificationPreferencesRequest request) { var user=userRepository.findByEmail(email).orElseThrow(ApiException::userNotFound); if(request.hideContent()!=null) user.setNotificationHideContent(request.hideContent()); if(request.muteChat()!=null) user.setNotificationMuteChat(request.muteChat()); return new NotificationPreferencesDto(Boolean.TRUE.equals(user.getNotificationHideContent()), Boolean.TRUE.equals(user.getNotificationMuteChat())); }

    private void registerDeviceToken(UUID userId, String token) {
        User user = userRepository.getReferenceById(userId);
        var existing = deviceTokens.findByToken(token);
        if (existing.isPresent()) { existing.get().setUser(user); return; }
        deviceTokens.save(NotificationDeviceToken.builder().user(user).token(token).build());
    }

    @Transactional
    public void markAsRead(UUID notificationId, String email) {
        UUID userId = userRepository.findByEmail(email).orElseThrow(ApiException::userNotFound).getId();
        notificationRepository.findByIdAndUserId(notificationId, userId).ifPresent(n -> {
            n.setIsRead(true);
            notificationRepository.save(n);
        });
    }

    private NotificationDto mapToDto(Notification n) {
        return NotificationDto.builder()
                .id(n.getId())
                .type(n.getType())
                .title(n.getTitle())
                .body(n.getBody())
                .payload(n.getPayload())
                .isRead(n.getIsRead())
                .createdAt(n.getCreatedAt())
                .build();
    }
}
