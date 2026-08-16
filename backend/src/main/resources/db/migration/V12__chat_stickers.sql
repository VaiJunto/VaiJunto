CREATE TABLE chat_stickers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(80) NOT NULL UNIQUE,
    label VARCHAR(120) NOT NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO chat_stickers (code, label) VALUES
 ('👍', 'Confirmado'), ('🕒', 'A caminho'), ('📍', 'Estou aqui'), ('🙏', 'Obrigado');
