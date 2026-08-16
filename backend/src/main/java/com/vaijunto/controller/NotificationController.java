package com.vaijunto.controller;

import com.vaijunto.dto.NotificationDto;
import com.vaijunto.dto.DeviceTokenRequest;
import com.vaijunto.dto.NotificationPreferencesDto;
import com.vaijunto.dto.UpdateNotificationPreferencesRequest;
import com.vaijunto.service.NotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.core.Authentication;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationService notificationService;

    @PostMapping("/device-token")
    public ResponseEntity<Void> registerDeviceToken(@RequestBody @jakarta.validation.Valid DeviceTokenRequest request, Authentication authentication) {
        notificationService.registerDeviceToken(authentication.getName(), request.token());
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/preferences")
    public NotificationPreferencesDto preferences(Authentication authentication) {
        return notificationService.preferences(authentication.getName());
    }

    @PutMapping("/preferences")
    public NotificationPreferencesDto updatePreferences(@RequestBody UpdateNotificationPreferencesRequest request, Authentication authentication) {
        return notificationService.updatePreferences(authentication.getName(), request);
    }

    @GetMapping
    public ResponseEntity<List<NotificationDto>> getNotifications(Authentication authentication) {
        List<NotificationDto> notifications = notificationService.getNotifications(authentication.getName());
        return ResponseEntity.ok(notifications);
    }

    @PutMapping("/{notificationId}/read")
    public ResponseEntity<Void> markAsRead(@PathVariable UUID notificationId, Authentication authentication) {
        notificationService.markAsRead(notificationId, authentication.getName());
        return ResponseEntity.ok().build();
    }
}
