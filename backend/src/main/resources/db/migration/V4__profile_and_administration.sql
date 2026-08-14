-- Additive migration: preserves every MVP user and route already stored.
ALTER TABLE users
    ADD COLUMN full_name VARCHAR(255),
    ADD COLUMN course VARCHAR(255),
    ADD COLUMN photo_url VARCHAR(2048),
    ADD COLUMN verification_badge_active BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN name_change_status VARCHAR(30),
    ADD COLUMN deletion_requested_at TIMESTAMP WITH TIME ZONE,
    ADD COLUMN anonymized_at TIMESTAMP WITH TIME ZONE;

UPDATE users SET full_name = name WHERE full_name IS NULL;
ALTER TABLE users ALTER COLUMN full_name SET NOT NULL;

-- `name` remains for backwards compatibility with existing queries; full_name
-- is the private canonical profile field introduced by this migration.
CREATE TABLE admin_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(30) NOT NULL CHECK (role IN ('SUPER_ADMIN', 'ADMIN', 'MODERATOR')),
    totp_secret VARCHAR(255) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);
CREATE TRIGGER trg_admin_accounts_updated_at BEFORE UPDATE ON admin_accounts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE admin_audit_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id UUID REFERENCES admin_accounts(id),
    event_type VARCHAR(100) NOT NULL,
    target_type VARCHAR(100),
    target_id VARCHAR(255),
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_admin_audit_events_admin_created ON admin_audit_events (admin_id, created_at DESC);
