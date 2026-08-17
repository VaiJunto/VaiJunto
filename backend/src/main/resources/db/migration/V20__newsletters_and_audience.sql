-- Busca de curso tolerante a erro de digitação ("engharia civil" -> "Engenharia Civil").
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS unaccent;

-- Vínculo com a instituição. Eixo independente de profile_types: um professor
-- também pode ser motorista de carona, então não cabe no enum ProfileType.
-- Fica nulo até existir o cadastro que preenche isso.
ALTER TABLE users ADD COLUMN affiliation VARCHAR(20)
    CHECK (affiliation IN ('STUDENT', 'PROFESSOR', 'STAFF'));
CREATE INDEX idx_users_affiliation ON users(affiliation);
CREATE INDEX idx_users_course_trgm ON users USING gin (course gin_trgm_ops);

-- Newsletter: título + lista ordenada de componentes + aparência do embed +
-- público-alvo, tudo versionado no próprio registro. Uma vez enviada é
-- imutável: o app busca por id para renderizar.
CREATE TABLE admin_newsletters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_by UUID NOT NULL REFERENCES admin_accounts(id) ON DELETE RESTRICT,
    title VARCHAR(160) NOT NULL,
    components JSONB NOT NULL,
    settings JSONB NOT NULL,
    audience JSONB NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('SCHEDULED', 'SENT', 'CANCELLED', 'FAILED')),
    scheduled_for TIMESTAMP WITH TIME ZONE,
    sent_at TIMESTAMP WITH TIME ZONE,
    recipient_count INTEGER NOT NULL DEFAULT 0,
    failure_reason VARCHAR(500),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_admin_newsletters_dispatch ON admin_newsletters(status, scheduled_for);
CREATE TRIGGER trg_admin_newsletters_updated_at BEFORE UPDATE ON admin_newsletters
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Entrega. Admins não têm registro em users, por isso as duas colunas —
-- exatamente uma é preenchida.
CREATE TABLE admin_newsletter_recipients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    newsletter_id UUID NOT NULL REFERENCES admin_newsletters(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    admin_id UUID REFERENCES admin_accounts(id) ON DELETE CASCADE,
    read_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_newsletter_recipient_target CHECK ((user_id IS NOT NULL) <> (admin_id IS NOT NULL))
);
CREATE UNIQUE INDEX idx_newsletter_recipient_user ON admin_newsletter_recipients(newsletter_id, user_id) WHERE user_id IS NOT NULL;
CREATE UNIQUE INDEX idx_newsletter_recipient_admin ON admin_newsletter_recipients(newsletter_id, admin_id) WHERE admin_id IS NOT NULL;

-- Mídia de newsletter e de mensagem administrativa: dono é um admin, não um
-- usuário, e não entra na expiração de 30 dias do chat (delete_after fica nulo
-- e a limpeza automática só varre category='CHAT').
ALTER TABLE media_objects ALTER COLUMN owner_id DROP NOT NULL;
ALTER TABLE media_objects ADD COLUMN admin_owner_id UUID REFERENCES admin_accounts(id) ON DELETE RESTRICT;
ALTER TABLE media_objects DROP CONSTRAINT media_objects_category_check;
ALTER TABLE media_objects ADD CONSTRAINT media_objects_category_check
    CHECK (category IN ('CHAT', 'PROFILE', 'REPORT', 'NEWSLETTER', 'ADMIN_MESSAGE'));
ALTER TABLE media_objects ADD CONSTRAINT chk_media_owner
    CHECK ((owner_id IS NOT NULL) OR (admin_owner_id IS NOT NULL));
