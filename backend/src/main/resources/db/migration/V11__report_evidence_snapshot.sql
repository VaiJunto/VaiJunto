CREATE TABLE report_evidence_snapshots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_id UUID NOT NULL REFERENCES message_reports(id) ON DELETE CASCADE,
    original_message_id UUID NOT NULL,
    sender_id UUID NOT NULL,
    kind VARCHAR(30) NOT NULL,
    body TEXT,
    location_json TEXT,
    sent_at TIMESTAMPTZ NOT NULL,
    media_ids_json TEXT NOT NULL DEFAULT '[]',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_report_evidence_report ON report_evidence_snapshots(report_id);
