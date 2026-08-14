package com.vaijunto.repository;
import com.vaijunto.domain.entities.AdminAuditEvent;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.UUID;
public interface AdminAuditEventRepository extends JpaRepository<AdminAuditEvent, UUID> { }
