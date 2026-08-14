package com.vaijunto.repository;

import com.vaijunto.domain.entities.Offer;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

@Repository
public interface OfferRepository extends JpaRepository<Offer, UUID> {
    List<Offer> findByDriverIdOrderByDepartureAtAsc(UUID driverId);
    long countByDriverIdAndStatusIn(UUID driverId, java.util.Collection<com.vaijunto.domain.enums.OfferStatus> statuses);
    @Query(value = "SELECT EXISTS(SELECT 1 FROM offers WHERE driver_id = :driverId AND status IN ('ACTIVE','FULL') AND departure_at BETWEEN :from AND :to)", nativeQuery = true)
    boolean existsOverlappingOffer(@Param("driverId") UUID driverId, @Param("from") OffsetDateTime from, @Param("to") OffsetDateTime to);
    Page<Offer> findByStatusInAndDepartureAtAfterOrderByDepartureAtAsc(java.util.Collection<com.vaijunto.domain.enums.OfferStatus> statuses, OffsetDateTime from, Pageable pageable);

    @Query(value = "SELECT o.* FROM offers o " +
            "JOIN routes r ON o.route_id = r.id " +
            "WHERE o.status = 'ACTIVE' " +
            "AND (r.is_recurrent = TRUE OR o.departure_at >= :startTime) " +
            "AND ST_DWithin(r.origin_location, ST_SetSRID(ST_MakePoint(:lon, :lat), 4326), :distanceInMeters)",
            nativeQuery = true)
    List<Offer> findActiveOffersNearOrigin(
            @Param("lon") double lon,
            @Param("lat") double lat,
            @Param("distanceInMeters") double distanceInMeters,
            @Param("startTime") OffsetDateTime startTime);
}
