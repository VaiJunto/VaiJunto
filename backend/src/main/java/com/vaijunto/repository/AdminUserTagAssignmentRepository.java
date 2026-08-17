package com.vaijunto.repository;
import com.vaijunto.domain.entities.*;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.*;
public interface AdminUserTagAssignmentRepository extends JpaRepository<AdminUserTagAssignment, AdminUserTagAssignmentId> { List<AdminUserTagAssignment> findByIdUserId(UUID userId); }
