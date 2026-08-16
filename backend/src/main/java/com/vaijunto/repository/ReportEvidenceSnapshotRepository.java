package com.vaijunto.repository;

import com.vaijunto.domain.entities.ReportEvidenceSnapshot;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ReportEvidenceSnapshotRepository extends JpaRepository<ReportEvidenceSnapshot, UUID> {
    java.util.List<ReportEvidenceSnapshot> findByReportIdOrderByCreatedAtAsc(UUID reportId);
}
