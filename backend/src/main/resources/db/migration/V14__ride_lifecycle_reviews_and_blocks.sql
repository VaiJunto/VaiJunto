ALTER TABLE trip_instances ADD COLUMN IF NOT EXISTS finish_reason VARCHAR(64);
ALTER TABLE trip_instances ADD COLUMN IF NOT EXISTS finish_note VARCHAR(500);
ALTER TABLE trip_instances ADD COLUMN IF NOT EXISTS final_radius_since TIMESTAMP WITH TIME ZONE;
ALTER TABLE trip_passengers ADD COLUMN IF NOT EXISTS absence_contested_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE trip_passengers ADD COLUMN IF NOT EXISTS absence_contestation VARCHAR(500);
CREATE TABLE IF NOT EXISTS user_blocks (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), user_low_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE, user_high_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE, created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(), CHECK(user_low_id <> user_high_id), UNIQUE(user_low_id,user_high_id));
CREATE TABLE IF NOT EXISTS ride_reviews (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), trip_id UUID NOT NULL REFERENCES trip_instances(id) ON DELETE CASCADE, reviewer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE, reviewee_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE, rating INTEGER NOT NULL CHECK(rating BETWEEN 1 AND 5), created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(), UNIQUE(trip_id,reviewer_id,reviewee_id));
CREATE INDEX IF NOT EXISTS idx_user_blocks_users ON user_blocks(user_low_id,user_high_id);
