-- Toyota Car Status App - Supabase Database Setup
-- Run this in your Supabase SQL Editor

-- Cars table
CREATE TABLE IF NOT EXISTS cars (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  model TEXT NOT NULL DEFAULT 'Camry',
  year INT NOT NULL DEFAULT 2024,
  distance_km INT NOT NULL DEFAULT 0,
  color TEXT NOT NULL DEFAULT 'Silver',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Car status table
CREATE TABLE IF NOT EXISTS car_status (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  car_id UUID REFERENCES cars(id) ON DELETE CASCADE,
  front_left_door BOOLEAN DEFAULT FALSE,
  front_right_door BOOLEAN DEFAULT FALSE,
  rear_left_door BOOLEAN DEFAULT FALSE,
  rear_right_door BOOLEAN DEFAULT FALSE,
  trunk BOOLEAN DEFAULT FALSE,
  hood BOOLEAN DEFAULT FALSE,
  lights BOOLEAN DEFAULT FALSE,
  wipers BOOLEAN DEFAULT FALSE,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Shop items table
CREATE TABLE IF NOT EXISTS shop_items (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  price DECIMAL(10,2) NOT NULL,
  category TEXT NOT NULL,
  image_url TEXT
);

-- Cart items table
CREATE TABLE IF NOT EXISTS cart_items (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  item_id UUID REFERENCES shop_items(id) ON DELETE CASCADE,
  quantity INT NOT NULL DEFAULT 1
);

-- Orders table
CREATE TABLE IF NOT EXISTS orders (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  items JSONB NOT NULL,
  total DECIMAL(10,2) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable realtime for car_status
ALTER PUBLICATION supabase_realtime ADD TABLE car_status;

-- Seed shop items
INSERT INTO shop_items (name, description, price, category, image_url) VALUES
  ('Premium Alloy Wheels', 'Set of 4 high-quality alloy wheels with modern design', 1299.99, 'wheels', 'https://images.unsplash.com/photo-1611821064430-0d40291d0f0b?w=400'),
  ('Sport Wheels', 'Lightweight sport wheels for improved performance', 1599.99, 'wheels', 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400'),
  ('All-Season Tires', 'Set of 4 premium all-season tires', 599.99, 'tires', 'https://images.unsplash.com/photo-1580273916550-e323be2ae537?w=400'),
  ('Winter Tires', 'Set of 4 winter tires for optimal cold weather grip', 699.99, 'tires', 'https://images.unsplash.com/photo-1619642751034-765dfdf7c58e?w=400'),
  ('Premium Wiper Blades', 'High-performance windshield wiper blades pair', 49.99, 'wipers', 'https://images.unsplash.com/photo-1489824904134-891ab64532f1?w=400'),
  ('Rain-X Wiper Blades', 'Water-repellent wiper blades for clear visibility', 59.99, 'wipers', 'https://images.unsplash.com/photo-1493238792000-8113da705763?w=400'),
  ('LED Headlight Kit', 'Bright LED headlight upgrade kit', 299.99, 'lights', 'https://images.unsplash.com/photo-1489824904134-891ab64532f1?w=400'),
  ('Fog Light Set', 'Auxiliary fog lights for improved visibility', 149.99, 'lights', 'https://images.unsplash.com/photo-1544636331-e26879cd4d9b?w=400'),
  ('Brake Pad Set', 'Premium ceramic brake pads for all four wheels', 199.99, 'brakes', 'https://images.unsplash.com/photo-1486262715619-67b85e0b08d3?w=400'),
  ('Oil Filter', 'High-quality oil filter for engine protection', 24.99, 'maintenance', 'https://images.unsplash.com/photo-1487754180451-c456f719a1fc?w=400'),
  ('Air Filter', 'Premium engine air filter for better performance', 34.99, 'maintenance', 'https://images.unsplash.com/photo-1492144534655-ae79c964c9d7?w=400'),
  ('Floor Mats Set', 'All-weather rubber floor mats set of 4', 89.99, 'accessories', 'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?w=400'),
  ('Car Cover', 'Premium waterproof car cover', 129.99, 'accessories', 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=400'),
  ('Dash Cam', 'HD dash camera with night vision', 149.99, 'electronics', 'https://images.unsplash.com/photo-1617704548623-340226c350ea?w=400'),
  ('Phone Mount', 'Magnetic phone mount for dashboard', 29.99, 'accessories', 'https://images.unsplash.com/photo-1551522435-a13afa10f103?w=400');
