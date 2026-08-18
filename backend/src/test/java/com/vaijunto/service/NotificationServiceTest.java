package com.vaijunto.service;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

import com.vaijunto.domain.entities.User;
import com.vaijunto.repository.NotificationDeviceTokenRepository;
import com.vaijunto.repository.NotificationRepository;
import com.vaijunto.repository.UserRepository;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Spy;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class NotificationServiceTest {
 @Mock NotificationRepository notifications;
 @Mock UserRepository users;
 @Mock NotificationDeviceTokenRepository devices;
 @Mock RealtimeEventPublisher realtimeEvents;
 @Spy ObjectMapper objectMapper = new ObjectMapper();
 @InjectMocks NotificationService service;
 @Test void savesInternalNotificationWithoutDeviceToken() {
  UUID id=UUID.randomUUID(); when(users.findById(id)).thenReturn(Optional.of(User.builder().id(id).email("user@fatec.sp.gov.br").build()));
  when(notifications.save(any())).thenAnswer(call -> { var notification = (com.vaijunto.domain.entities.Notification) call.getArgument(0); notification.setId(UUID.randomUUID()); return notification; });
  service.createAndSendNotification(id,"Título","Corpo","RIDE_REQUEST","{}",null);
  verify(notifications).save(any());
  verify(devices).findByUserId(id);
 }
}
