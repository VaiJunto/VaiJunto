package com.vaijunto.repository;

import com.vaijunto.domain.entities.Demand;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@Repository
public interface DemandRepository extends JpaRepository<Demand, UUID> {
    List<Demand> findByPassengerId(UUID passengerId);

    @Query(value = "SELECT d.* FROM demands d " +
            "WHERE d.status = 'OPEN' " +
            "AND d.desired_time >= :startTime " +
            "AND ST_DWithin(d.origin_location, ST_SetSRID(ST_MakePoint(:lon, :lat), 4326), :distanceInMeters)",
            nativeQuery = true)
    List<Demand> findOpenDemandsNearOrigin(
            @Param("lon") double lon,
            @Param("lat") double lat,
            @Param("distanceInMeters") double distanceInMeters,
            @Param("startTime") OffsetDateTime startTime);
}
