-- Migration: Initial schema
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Studios
CREATE TABLE studios (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    capacity INTEGER DEFAULT 1,
    hourly_rate NUMERIC(10,2) NOT NULL,
    amenities TEXT[] DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Bookings
CREATE TABLE bookings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    studio_id UUID REFERENCES studios(id) ON DELETE CASCADE,
    booking_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    duration_hours NUMERIC(4,2) NOT NULL,
    amount NUMERIC(10,2) NOT NULL,
    status TEXT DEFAULT 'pending_payment',
    payment_ref TEXT,
    payment_status TEXT DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS
ALTER TABLE studios ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Studios public read" ON studios FOR SELECT USING (is_active = true);
CREATE POLICY "Users own bookings" ON bookings FOR ALL USING (auth.uid() = user_id);

-- Functions
CREATE OR REPLACE FUNCTION check_availability(
    p_studio_id UUID,
    p_date DATE,
    p_start TIME,
    p_end TIME
) RETURNS BOOLEAN AS $$
BEGIN
    RETURN NOT EXISTS (
        SELECT 1 FROM bookings
        WHERE studio_id = p_studio_id
        AND booking_date = p_date
        AND status NOT IN ('cancelled', 'refunded')
        AND (start_time, end_time) OVERLAPS (p_start, p_end)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Seed data
INSERT INTO studios (name, description, capacity, hourly_rate, amenities) VALUES
    ('Station A', 'Makeup station with professional lighting', 8, 80, ARRAY['Mixing Console', 'Keyboard', 'Drums']),
    ('Station B', 'Makeup station with professional lighting', 4, 60, ARRAY['DSLR', 'Strobes', 'Backdrops']),
    ('Studio Suite', 'Professional Studio with green screen', 6, 75, ARRAY['4K Camera', 'Green Screen', 'Lighting']);
