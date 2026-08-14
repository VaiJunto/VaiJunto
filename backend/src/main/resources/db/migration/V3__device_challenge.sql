-- MFA de primeiro login: device desconhecido precisa confirmar um código
-- enviado por e-mail antes de receber o JWT de sessão. Reaproveita a tabela
-- de códigos do cadastro, agora diferenciada por `purpose`.

ALTER TABLE email_verification_codes
    ADD COLUMN purpose VARCHAR(30) NOT NULL DEFAULT 'EMAIL_VERIFICATION';

-- Substitui o índice antigo (user_id, created_at) por um que também cobre
-- purpose, já que toda consulta agora filtra por ele.
DROP INDEX IF EXISTS idx_email_verification_codes_user_created;
CREATE INDEX idx_email_verification_codes_user_purpose_created
    ON email_verification_codes (user_id, purpose, created_at DESC);

CREATE TABLE known_devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id VARCHAR(100) NOT NULL,
    last_seen_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    UNIQUE (user_id, device_id)
);
