ALTER TABLE chat_stickers ADD COLUMN storage_key VARCHAR(255);
ALTER TABLE chat_stickers ADD COLUMN content_type VARCHAR(80);
DELETE FROM chat_stickers;
ALTER TABLE chat_stickers ALTER COLUMN storage_key SET NOT NULL;
ALTER TABLE chat_stickers ALTER COLUMN content_type SET NOT NULL;
