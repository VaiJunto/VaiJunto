CREATE TABLE media_objects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    conversation_id UUID REFERENCES conversations(id) ON DELETE RESTRICT,
    message_id UUID REFERENCES conversation_messages(id) ON DELETE SET NULL,
    storage_key VARCHAR(500) NOT NULL UNIQUE,
    category VARCHAR(20) NOT NULL CHECK (category IN ('CHAT', 'PROFILE', 'REPORT')),
    content_type VARCHAR(100) NOT NULL,
    size_bytes BIGINT NOT NULL CHECK (size_bytes > 0),
    duration_seconds INTEGER,
    status VARCHAR(20) NOT NULL CHECK (status IN ('PENDING', 'ACTIVE', 'DELETED', 'FAILED')),
    delete_after TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    deleted_reason VARCHAR(80),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_media_objects_cleanup ON media_objects(status, category, delete_after) WHERE deleted_at IS NULL;
CREATE INDEX idx_media_objects_conversation ON media_objects(conversation_id);
CREATE TRIGGER trg_media_objects_updated_at BEFORE UPDATE ON media_objects FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
