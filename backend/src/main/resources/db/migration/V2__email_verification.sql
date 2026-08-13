-- Confirmação de e-mail institucional no cadastro.
--
-- A conta já é criada em `users` no momento do registro (isActive continua
-- true — é o login por senha que fica liberado), mas fica sem acesso ao app
-- até o código de 6 dígitos ser confirmado. `email_verified` é o que a
-- aplicação checa antes de emitir um token.
ALTER TABLE users ADD COLUMN email_verified BOOLEAN NOT NULL DEFAULT FALSE;

CREATE TABLE email_verification_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    code VARCHAR(6) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    consumed_at TIMESTAMP WITH TIME ZONE,
    attempts INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Toda consulta é "o código mais recente deste usuário" — cobre o caso comum
-- (verificar) e evita full scan quando alguém pede reenvio repetidas vezes.
CREATE INDEX idx_email_verification_codes_user_created
    ON email_verification_codes (user_id, created_at DESC);
