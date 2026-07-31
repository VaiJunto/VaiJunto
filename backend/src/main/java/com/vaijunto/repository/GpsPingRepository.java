package com.vaijunto.repository;

import com.vaijunto.domain.entities.GpsPing;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface GpsPingRepository extends JpaRepository<GpsPing, Long> {
}
