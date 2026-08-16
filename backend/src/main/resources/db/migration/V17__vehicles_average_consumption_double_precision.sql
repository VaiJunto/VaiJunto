-- Vehicle.averageConsumption is mapped as Java Double. Keep the persisted type
-- aligned with Hibernate schema validation while preserving existing values.
ALTER TABLE vehicles
    ALTER COLUMN average_consumption TYPE DOUBLE PRECISION
    USING average_consumption::DOUBLE PRECISION;
