package com.vaijunto.repository;
import com.vaijunto.domain.entities.MessageReport;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.UUID;
import java.util.List;
public interface MessageReportRepository extends JpaRepository<MessageReport, UUID> {
 List<MessageReport> findByStatusOrderByCreatedAtDesc(String status);
 List<MessageReport> findAllByOrderByCreatedAtDesc();
}
