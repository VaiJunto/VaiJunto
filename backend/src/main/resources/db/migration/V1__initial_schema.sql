-- Habilita extensão PostGIS para consultas geoespaciais
CREATE EXTENSION IF NOT EXISTS postgis;

-- Função genérica para atualização automática do campo updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 1. Tabela: universities
CREATE TABLE universities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    code VARCHAR(50) NOT NULL UNIQUE,
    domain VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

CREATE TRIGGER trg_universities_updated_at
    BEFORE UPDATE ON universities
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 2. Tabela: users
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    phone VARCHAR(50),
    profile_types VARCHAR(50)[] NOT NULL DEFAULT '{PASSENGER}',
    university_id UUID REFERENCES universities(id),
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

CREATE TRIGGER trg_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 3. Tabela: vehicles
CREATE TABLE vehicles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    driver_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    license_plate VARCHAR(20) NOT NULL UNIQUE,
    model VARCHAR(100),
    color VARCHAR(50),
    capacity INT NOT NULL CHECK (capacity > 0),
    vehicle_type VARCHAR(50) NOT NULL CHECK (vehicle_type IN ('VAN', 'CAR')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

CREATE TRIGGER trg_vehicles_updated_at
    BEFORE UPDATE ON vehicles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 4. Tabela: routes
CREATE TABLE routes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vehicle_id UUID REFERENCES vehicles(id) ON DELETE CASCADE,
    driver_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(150),
    origin_name VARCHAR(255) NOT NULL,
    origin_location GEOGRAPHY(Point, 4326) NOT NULL,
    destination_name VARCHAR(255) NOT NULL,
    destination_location GEOGRAPHY(Point, 4326) NOT NULL,
    waypoints GEOGRAPHY(LineString, 4326),
    departure_time TIME NOT NULL,
    days_of_week INT[] DEFAULT '{1,2,3,4,5}', -- 1=Dom, 2=Seg ... 7=Sáb
    is_recurrent BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

CREATE INDEX idx_routes_origin ON routes USING GIST (origin_location);
CREATE INDEX idx_routes_destination ON routes USING GIST (destination_location);

CREATE TRIGGER trg_routes_updated_at
    BEFORE UPDATE ON routes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 5. Tabela: offers
CREATE TABLE offers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    route_id UUID REFERENCES routes(id) ON DELETE SET NULL,
    driver_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    available_seats INT NOT NULL CHECK (available_seats >= 0),
    price DECIMAL(10, 2) DEFAULT 0.00 NOT NULL,
    departure_at TIMESTAMP WITH TIME ZONE NOT NULL,
    status VARCHAR(50) DEFAULT 'ACTIVE' NOT NULL CHECK (status IN ('ACTIVE', 'FULL', 'CANCELLED', 'FINISHED')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

CREATE TRIGGER trg_offers_updated_at
    BEFORE UPDATE ON offers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 6. Tabela: demands
CREATE TABLE demands (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    passenger_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    origin_name VARCHAR(255) NOT NULL,
    origin_location GEOGRAPHY(Point, 4326) NOT NULL,
    destination_name VARCHAR(255) NOT NULL,
    destination_location GEOGRAPHY(Point, 4326) NOT NULL,
    desired_time TIMESTAMP WITH TIME ZONE NOT NULL,
    status VARCHAR(50) DEFAULT 'OPEN' NOT NULL CHECK (status IN ('OPEN', 'MATCHED', 'CANCELLED')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

CREATE INDEX idx_demands_origin ON demands USING GIST (origin_location);
CREATE INDEX idx_demands_destination ON demands USING GIST (destination_location);

CREATE TRIGGER trg_demands_updated_at
    BEFORE UPDATE ON demands
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 7. Tabela: trip_instances
CREATE TABLE trip_instances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    offer_id UUID REFERENCES offers(id) ON DELETE SET NULL,
    route_id UUID REFERENCES routes(id) ON DELETE SET NULL,
    driver_id UUID NOT NULL REFERENCES users(id),
    scheduled_departure TIMESTAMP WITH TIME ZONE NOT NULL,
    actual_start TIMESTAMP WITH TIME ZONE,
    actual_end TIMESTAMP WITH TIME ZONE,
    status VARCHAR(50) DEFAULT 'SCHEDULED' NOT NULL CHECK (status IN ('SCHEDULED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

CREATE TRIGGER trg_trip_instances_updated_at
    BEFORE UPDATE ON trip_instances
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 8. Tabela: trip_passengers
CREATE TABLE trip_passengers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_instance_id UUID NOT NULL REFERENCES trip_instances(id) ON DELETE CASCADE,
    passenger_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(50) DEFAULT 'REQUESTED' NOT NULL CHECK (status IN ('REQUESTED', 'CONFIRMED', 'CHECKED_IN', 'ABSENT', 'CANCELLED')),
    checked_in_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    CONSTRAINT uq_trip_passenger UNIQUE (trip_instance_id, passenger_id)
);

CREATE TRIGGER trg_trip_passengers_updated_at
    BEFORE UPDATE ON trip_passengers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 9. Tabela: gps_pings (tabela volátil para rastreamento em tempo real)
CREATE TABLE gps_pings (
    id BIGSERIAL PRIMARY KEY,
    trip_instance_id UUID NOT NULL REFERENCES trip_instances(id) ON DELETE CASCADE,
    location GEOGRAPHY(Point, 4326) NOT NULL,
    speed DOUBLE PRECISION,
    heading DOUBLE PRECISION,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

CREATE INDEX idx_gps_pings_trip_time ON gps_pings (trip_instance_id, recorded_at DESC);

-- 10. Tabela: notifications
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(100) NOT NULL,
    payload JSONB,
    is_read BOOLEAN DEFAULT FALSE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

CREATE TRIGGER trg_notifications_updated_at
    BEFORE UPDATE ON notifications
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
