CREATE TABLE notification_device_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token VARCHAR(512) NOT NULL UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_notification_device_tokens_user ON notification_device_tokens(user_id);
CREATE TRIGGER trg_notification_device_tokens_updated_at BEFORE UPDATE ON notification_device_tokens FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
