package com.vaijunto.repository;

import com.vaijunto.domain.entities.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@Repository
public interface UserRepository extends JpaRepository<User, UUID> {

    Optional<User> findByEmail(String email);

    boolean existsByEmail(String email);
    List<User> findByDeletionRequestedAtBeforeAndAnonymizedAtIsNull(OffsetDateTime before);
    List<User> findByNameChangeStatus(String status);
    List<User> findTop50ByNameContainingIgnoreCaseOrFullNameContainingIgnoreCaseOrEmailContainingIgnoreCase(String name, String fullName, String email);
}
