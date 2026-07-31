package com.vaijunto.repository;

import com.vaijunto.domain.entities.University;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface UniversityRepository extends JpaRepository<University, UUID> {

    Optional<University> findByCode(String code);
}
