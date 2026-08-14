CREATE TABLE saved_addresses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    label VARCHAR(80) NOT NULL,
    address_name VARCHAR(255) NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    is_recent BOOLEAN NOT NULL DEFAULT FALSE,
    last_used_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);
CREATE UNIQUE INDEX uq_saved_addresses_active_label ON saved_addresses(user_id, lower(label)) WHERE deleted_at IS NULL AND is_recent = FALSE;
CREATE INDEX idx_saved_addresses_recent_expiry ON saved_addresses(user_id, expires_at) WHERE is_recent = TRUE AND deleted_at IS NULL;
CREATE TRIGGER trg_saved_addresses_updated_at BEFORE UPDATE ON saved_addresses FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS year INTEGER;
ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS make VARCHAR(100);
ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS trim VARCHAR(100);
ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS fuel VARCHAR(50);
ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS average_consumption NUMERIC(6,2);
ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS photo_url VARCHAR(500);
ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS is_default BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS archived_at TIMESTAMP WITH TIME ZONE;
CREATE UNIQUE INDEX uq_vehicles_active_plate ON vehicles(license_plate) WHERE archived_at IS NULL;
CREATE UNIQUE INDEX uq_vehicles_default_per_driver ON vehicles(driver_id) WHERE is_default = TRUE AND archived_at IS NULL;

CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type VARCHAR(30) NOT NULL CHECK (type IN ('RIDE', 'PROPOSAL', 'OFFICIAL', 'ADMINISTRATIVE')),
    ride_id UUID REFERENCES trip_instances(id) ON DELETE SET NULL,
    participant_a_id UUID REFERENCES users(id) ON DELETE SET NULL,
    participant_b_id UUID REFERENCES users(id) ON DELETE SET NULL,
    archived_at TIMESTAMP WITH TIME ZONE,
    read_only_at TIMESTAMP WITH TIME ZONE,
    last_activity_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_conversations_participant_a ON conversations(participant_a_id, last_activity_at DESC);
CREATE INDEX idx_conversations_participant_b ON conversations(participant_b_id, last_activity_at DESC);
CREATE TRIGGER trg_conversations_updated_at BEFORE UPDATE ON conversations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
