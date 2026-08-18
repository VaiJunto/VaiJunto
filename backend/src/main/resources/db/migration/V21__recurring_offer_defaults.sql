ALTER TABLE routes ALTER COLUMN is_recurrent SET DEFAULT FALSE;
COMMENT ON COLUMN routes.days_of_week IS 'ISO-8601: 1=segunda, 7=domingo';
