package com.vaijunto.repository;

import com.vaijunto.domain.entities.KnownDevice;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface KnownDeviceRepository extends JpaRepository<KnownDevice, UUID> {

    Optional<KnownDevice> findByUserIdAndDeviceId(UUID userId, String deviceId);
}
