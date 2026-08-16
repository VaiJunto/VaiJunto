ALTER TABLE users ADD COLUMN verification_status VARCHAR(30) NOT NULL DEFAULT 'NOT_VERIFIED'
    CHECK (verification_status IN ('NOT_VERIFIED', 'VERIFIED', 'PAUSED', 'REJECTED', 'REMOVED'));
ALTER TABLE users ADD COLUMN verification_note TEXT;
ALTER TABLE users ADD COLUMN warned_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE users ADD COLUMN warning_reason TEXT;
ALTER TABLE users ADD COLUMN suspended_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE users ADD COLUMN suspension_reason TEXT;

ALTER TABLE admin_audit_events ADD COLUMN reason TEXT;
CREATE INDEX idx_admin_audit_events_target ON admin_audit_events(target_type, target_id, created_at DESC);
CREATE INDEX idx_message_reports_status_created ON message_reports(status, created_at DESC);
