package com.vaijunto.repository;

import com.vaijunto.domain.entities.TripInstance;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface TripInstanceRepository extends JpaRepository<TripInstance, UUID> {
    List<TripInstance> findByDriverId(UUID driverId);
    List<TripInstance> findByStatusAndScheduledDepartureBefore(com.vaijunto.domain.enums.TripStatus status, java.time.OffsetDateTime departure);
}
