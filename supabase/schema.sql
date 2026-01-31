-- Supabase Database Schema for Leish Studio Booking System
-- PostgreSQL 15

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Studios table
CREATE TABLE IF NOT EXISTS studios (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    capacity INTEGER DEFAULT 1,
    hourly_rate NUMERIC(10,2) NOT NULL,
    amenities JSONB DEFAULT '[]'::jsonb,
    image_url TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Bookings table
CREATE TABLE IF NOT EXISTS bookings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_number TEXT UNIQUE NOT NULL,
    studio_id UUID REFERENCES studios(id) ON DELETE CASCADE,
    customer_name TEXT NOT NULL,
    customer_email TEXT NOT NULL,
    customer_phone TEXT,
    booking_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    duration_hours NUMERIC(4,2) NOT NULL,
    amount NUMERIC(10,2) NOT NULL,
    payment_status TEXT DEFAULT 'pending',
    payment_method TEXT,
    status TEXT DEFAULT 'confirmed',
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_bookings_date ON bookings(booking_date);
CREATE INDEX IF NOT EXISTS idx_bookings_email ON bookings(customer_email);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON bookings(status);
CREATE INDEX IF NOT EXISTS idx_bookings_studio ON bookings(studio_id);
CREATE INDEX IF NOT EXISTS idx_bookings_booking_number ON bookings(booking_number);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at
CREATE TRIGGER update_studios_updated_at BEFORE UPDATE ON studios
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    
CREATE TRIGGER update_bookings_updated_at BEFORE UPDATE ON bookings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert sample studios
INSERT INTO studios (name, description, capacity, hourly_rate, amenities, image_url) VALUES
    ('Podcast Studio', 'Professional podcast recording studio with high-quality microphones and soundproofing', 4, 50.00, '["Microphones", "Soundproofing", "Recording Software", "Headphones"]','https://images.unsplash.com/photo-1598488035139-bdbb2231ce04'),
    ('Video Studio', 'Full video production studio with lighting, cameras, and green screen', 6, 75.00, '["4K Cameras", "Lighting Kit", "Green Screen", "Teleprompter"]','https://images.unsplash.com/photo-1574717024653-61fd2cf4d44d'),
    ('Photo Studio', 'Professional photography studio with backdrops and lighting equipment', 4, 60.00, '["DSLR Cameras", "Studio Lighting", "Backdrops", "Reflectors"]','https://images.unsplash.com/photo-1554080353-a576cf803bda'),
    ('Music Studio', 'Complete music production studio with instruments and mixing equipment', 8, 80.00, '["Keyboard", "Guitars", "Drum Kit", "Mixing Console", "DAW Software"]','https://images.unsplash.com/photo-1598488035139-bdbb2231ce04')
ON CONFLICT DO NOTHING;

-- Create function to check availability
CREATE OR REPLACE FUNCTION check_studio_availability(
    p_studio_id UUID,
    p_booking_date DATE,
    p_start_time TIME,
    p_end_time TIME
)
RETURNS BOOLEAN AS $$
DECLARE
    overlapping_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO overlapping_count
    FROM bookings
    WHERE studio_id = p_studio_id
        AND booking_date = p_booking_date
        AND status = 'confirmed'
        AND (
            (p_start_time >= start_time AND p_start_time < end_time)
            OR (p_end_time > start_time AND p_end_time <= end_time)
            OR (p_start_time <= start_time AND p_end_time >= end_time)
        );
    
    RETURN overlapping_count = 0;
END;
$$ LANGUAGE plpgsql;

-- Enable Row Level Security (RLS)
ALTER TABLE studios ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;

-- Create policies for studios
DROP POLICY IF EXISTS studios_read_policy ON studios;
CREATE POLICY studios_read_policy ON studios FOR SELECT USING (is_active = true);

-- Create policies for bookings
DROP POLICY IF EXISTS bookings_read_policy ON bookings;
CREATE POLICY bookings_read_policy ON bookings FOR SELECT 
    USING (customer_email = current_setting('app.current_user_email', true) OR 
           current_setting('app.is_admin', true) = 'true');

DROP POLICY IF EXISTS bookings_insert_policy ON bookings;
CREATE POLICY bookings_insert_policy ON bookings FOR INSERT 
    WITH CHECK (true);

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT ON studios TO anon, authenticated;
GRANT INSERT ON bookings TO anon, authenticated;
GRANT SELECT ON bookings TO anon, authenticated;
GRANT EXECUTE ON FUNCTION check_studio_availability TO anon, authenticated;
