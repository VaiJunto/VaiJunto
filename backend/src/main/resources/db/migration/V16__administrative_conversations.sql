ALTER TABLE conversations ADD COLUMN admin_account_id UUID REFERENCES admin_accounts(id);
ALTER TABLE conversation_messages ALTER COLUMN sender_id DROP NOT NULL;
ALTER TABLE conversation_messages ADD COLUMN admin_sender_id UUID REFERENCES admin_accounts(id);
ALTER TABLE conversation_messages ADD CONSTRAINT chk_message_author CHECK ((sender_id IS NOT NULL) <> (admin_sender_id IS NOT NULL));
CREATE INDEX idx_conversations_admin_account ON conversations(admin_account_id);
