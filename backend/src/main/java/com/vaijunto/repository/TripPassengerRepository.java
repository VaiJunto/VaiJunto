package com.vaijunto.repository;

import com.vaijunto.domain.entities.TripPassenger;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface TripPassengerRepository extends JpaRepository<TripPassenger, UUID> {
    List<TripPassenger> findByTripInstanceId(UUID tripInstanceId);
    Optional<TripPassenger> findByTripInstanceIdAndPassengerId(UUID tripInstanceId, UUID passengerId);
}
