CREATE TABLE conversation_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    client_id UUID NOT NULL,
    kind VARCHAR(20) NOT NULL CHECK (kind IN ('TEXT', 'LOCATION', 'SYSTEM')),
    body TEXT,
    location_json JSONB,
    reply_to_id UUID REFERENCES conversation_messages(id) ON DELETE SET NULL,
    sent_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    delivered_at TIMESTAMP WITH TIME ZONE,
    read_at TIMESTAMP WITH TIME ZONE,
    edited_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT uq_conversation_message_client UNIQUE (conversation_id, client_id),
    CONSTRAINT chk_message_payload CHECK (
        (kind = 'TEXT' AND body IS NOT NULL AND length(trim(body)) > 0) OR
        (kind = 'LOCATION' AND location_json IS NOT NULL) OR kind = 'SYSTEM'
    )
);
CREATE INDEX idx_conversation_messages_history ON conversation_messages(conversation_id, sent_at DESC);

CREATE TABLE message_attachments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id UUID NOT NULL REFERENCES conversation_messages(id) ON DELETE CASCADE,
    storage_key VARCHAR(500) NOT NULL,
    content_type VARCHAR(100) NOT NULL,
    size_bytes BIGINT NOT NULL CHECK (size_bytes > 0),
    duration_seconds INTEGER CHECK (duration_seconds IS NULL OR duration_seconds >= 0),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_attachment_limits CHECK (
        (content_type LIKE 'video/%' AND duration_seconds <= 20) OR
        (content_type LIKE 'audio/%' AND duration_seconds <= 120) OR
        content_type NOT LIKE 'video/%' AND content_type NOT LIKE 'audio/%'
    )
);

CREATE TABLE message_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE RESTRICT,
    status VARCHAR(20) NOT NULL DEFAULT 'ENVIADA' CHECK (status IN ('ENVIADA', 'EM_ANALISE', 'RESOLVIDA')),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);
CREATE TABLE message_report_items (
    report_id UUID NOT NULL REFERENCES message_reports(id) ON DELETE CASCADE,
    message_id UUID NOT NULL REFERENCES conversation_messages(id) ON DELETE RESTRICT,
    PRIMARY KEY (report_id, message_id)
);

ALTER TABLE notifications ADD COLUMN title VARCHAR(160);
ALTER TABLE notifications ADD COLUMN body TEXT;
CREATE INDEX idx_notifications_user_created ON notifications(user_id, created_at DESC);
