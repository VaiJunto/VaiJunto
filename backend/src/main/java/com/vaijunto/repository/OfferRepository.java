package com.vaijunto.repository;

import com.vaijunto.domain.entities.Offer;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@Repository
public interface OfferRepository extends JpaRepository<Offer, UUID> {
    List<Offer> findByDriverId(UUID driverId);

    @Query(value = "SELECT o.* FROM offers o " +
            "JOIN routes r ON o.route_id = r.id " +
            "WHERE o.status = 'ACTIVE' " +
            "AND o.departure_at >= :startTime " +
            "AND ST_DWithin(r.origin_location, ST_SetSRID(ST_MakePoint(:lon, :lat), 4326), :distanceInMeters)",
            nativeQuery = true)
    List<Offer> findActiveOffersNearOrigin(
            @Param("lon") double lon,
            @Param("lat") double lat,
            @Param("distanceInMeters") double distanceInMeters,
            @Param("startTime") OffsetDateTime startTime);
}
