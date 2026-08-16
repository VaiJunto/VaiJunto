package com.vaijunto.repository;
import com.vaijunto.domain.entities.NotificationDeviceToken; import org.springframework.data.jpa.repository.JpaRepository; import java.util.*;
public interface NotificationDeviceTokenRepository extends JpaRepository<NotificationDeviceToken,UUID> { Optional<NotificationDeviceToken> findByToken(String token); List<NotificationDeviceToken> findByUserId(UUID userId); }
