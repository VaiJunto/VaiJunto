ALTER TABLE trip_passengers ADD COLUMN IF NOT EXISTS demand_id UUID REFERENCES demands(id) ON DELETE SET NULL;
ALTER TABLE trip_passengers ADD COLUMN IF NOT EXISTS cancellation_reason VARCHAR(64);
ALTER TABLE trip_passengers ADD COLUMN IF NOT EXISTS cancellation_note VARCHAR(500);
ALTER TABLE trip_passengers DROP CONSTRAINT IF EXISTS trip_passengers_status_check;
ALTER TABLE trip_passengers ADD CONSTRAINT trip_passengers_status_check
  CHECK (status IN ('REQUESTED','CONFIRMED','DECLINED','WITHDRAWN','EXPIRED','CHECKED_IN','ABSENT','CANCELLED'));
CREATE INDEX IF NOT EXISTS idx_trip_passengers_demand ON trip_passengers(demand_id);
CREATE INDEX IF NOT EXISTS idx_trip_passengers_passenger_status ON trip_passengers(passenger_id, status);

CREATE TABLE IF NOT EXISTS ride_review_flags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reason VARCHAR(80) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_ride_review_flags_pending ON ride_review_flags(user_id, status);
