CREATE TABLE admin_user_tags (
    id UUID PRIMARY KEY,
    name VARCHAR(48) NOT NULL UNIQUE,
    color VARCHAR(9) NOT NULL,
    icon_svg TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE TABLE admin_user_tag_assignments (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    tag_id UUID NOT NULL REFERENCES admin_user_tags(id) ON DELETE CASCADE,
    assigned_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, tag_id)
);

CREATE INDEX idx_admin_user_tag_assignments_user ON admin_user_tag_assignments(user_id);
