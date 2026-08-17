package com.vaijunto.repository;
import com.vaijunto.domain.entities.AdminUserTag;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.*;
public interface AdminUserTagRepository extends JpaRepository<AdminUserTag, UUID> { boolean existsByNameIgnoreCase(String name); List<AdminUserTag> findAllByOrderByNameAsc(); }
