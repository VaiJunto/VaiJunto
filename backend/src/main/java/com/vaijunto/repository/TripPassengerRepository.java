package com.vaijunto.repository;

import com.vaijunto.domain.entities.TripPassenger;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

@Repository
public interface TripPassengerRepository extends JpaRepository<TripPassenger, UUID> {
    List<TripPassenger> findByTripInstanceId(UUID tripInstanceId);
    Optional<TripPassenger> findByTripInstanceIdAndPassengerId(UUID tripInstanceId, UUID passengerId);
    long countByPassengerIdAndStatusIn(UUID passengerId, java.util.Collection<com.vaijunto.domain.enums.PassengerStatus> statuses);
    @Query("select case when count(tp) > 0 then true else false end from TripPassenger tp where tp.passenger.id = :passengerId and tp.status in ('CONFIRMED', 'CHECKED_IN') and tp.tripInstance.scheduledDeparture between :from and :to and (:ignoreId is null or tp.id <> :ignoreId)")
    boolean existsAcceptedOverlap(@Param("passengerId") UUID passengerId, @Param("from") java.time.OffsetDateTime from, @Param("to") java.time.OffsetDateTime to, @Param("ignoreId") UUID ignoreId);
    long countByPassengerIdAndStatusInAndUpdatedAtAfter(UUID passengerId, java.util.Collection<com.vaijunto.domain.enums.PassengerStatus> statuses, java.time.OffsetDateTime after);
    List<TripPassenger> findByTripInstanceDriverIdAndPassengerIdAndStatusIn(UUID driverId, UUID passengerId, java.util.Collection<com.vaijunto.domain.enums.PassengerStatus> statuses);
}
