package com.vaijunto.repository;

import com.vaijunto.domain.entities.Vehicle;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface VehicleRepository extends JpaRepository<Vehicle, UUID> {
    List<Vehicle> findByDriverId(UUID driverId);
    List<Vehicle> findByDriverIdAndArchivedAtIsNullOrderByIsDefaultDescCreatedAtDesc(UUID driverId);
    boolean existsByLicensePlateAndArchivedAtIsNull(String licensePlate);
}
