package com.vaijunto.repository;

import com.vaijunto.domain.entities.Route;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface RouteRepository extends JpaRepository<Route, UUID> {
    List<Route> findByDriverId(UUID driverId);
}
