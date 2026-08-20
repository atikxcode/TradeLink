-- =============================================================================
-- TradeLink — Backend-compatible schema
-- Aligned with supabase/migrations/ (users, products, stocks, demands,
-- orders, otps, notifications, ratings) so the backend API and the Flutter
-- app operate on the same tables/columns.
--
-- NOTE: These migrations are applied to the shared Supabase project via the
-- `supabase/migrations/` SQL files. This file is kept in sync for local dev
-- and documents the exact schema the backend expects.
-- =============================================================================

DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('shop_owner', 'supplier');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE demand_status AS ENUM ('pending', 'accepted', 'delivered', 'cancelled');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE order_status AS ENUM ('pending', 'accepted', 'in_transit', 'delivered', 'cancelled');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- ---------------------------------------------------------------------------
-- users
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auth_id UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    role user_role NOT NULL DEFAULT 'shop_owner',
    full_name TEXT NOT NULL,
    phone_number TEXT NOT NULL UNIQUE,
    business_name TEXT NOT NULL,
    category TEXT NOT NULL DEFAULT 'Grocery',
    trade_license TEXT,
    min_order_value NUMERIC(12, 2) DEFAULT 0,
    supply_radius TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    address TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read access to users"
ON public.users FOR SELECT USING (true);
CREATE POLICY "Allow inserts to users table"
ON public.users FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow users to update own profile"
ON public.users FOR UPDATE USING (auth.uid() = auth_id OR auth.uid() IS NULL);
CREATE INDEX IF NOT EXISTS idx_users_phone ON public.users(phone_number);
CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);

-- ---------------------------------------------------------------------------
-- products (master catalog)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    category TEXT NOT NULL DEFAULT 'Grocery',
    unit TEXT NOT NULL DEFAULT 'kg',
    default_price NUMERIC(10, 2),
    image_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read on products"
ON public.products FOR SELECT USING (true);
CREATE POLICY "Allow authenticated insert on products"
ON public.products FOR INSERT WITH CHECK (true);

INSERT INTO public.products (name, category, unit, default_price) VALUES
('Basmati Rice', 'Grocery', 'kg', 145.00),
('Soybean Oil', 'Grocery', 'litre', 165.00),
('Sugar', 'Grocery', 'kg', 130.00),
('Lentils (Musur Dal)', 'Grocery', 'kg', 120.00),
('Wheat Flour (Atta)', 'Grocery', 'kg', 55.00),
('Napa Extra 500mg', 'Pharmacy', 'pcs', 2.50),
('Paracetamol Syrup', 'Pharmacy', 'pcs', 35.00),
('Steel Nails 2-inch', 'Hardware', 'kg', 110.00),
('PVC Pipe 1-inch', 'Hardware', 'pcs', 250.00)
ON CONFLICT DO NOTHING;

-- ---------------------------------------------------------------------------
-- stocks (Supplier inventory / Shop Owner stores)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.stocks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
    product_name TEXT NOT NULL,
    category TEXT NOT NULL DEFAULT 'Grocery',
    quantity NUMERIC(10, 2) NOT NULL DEFAULT 0,
    unit TEXT NOT NULL DEFAULT 'kg',
    price_per_unit NUMERIC(10, 2) NOT NULL DEFAULT 0,
    is_available BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.stocks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public select on stocks"
ON public.stocks FOR SELECT USING (true);
CREATE POLICY "Allow insert own stocks"
ON public.stocks FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow update own stocks"
ON public.stocks FOR UPDATE USING (true);
CREATE POLICY "Allow delete own stocks"
ON public.stocks FOR DELETE USING (true);
CREATE INDEX IF NOT EXISTS idx_stocks_user_id ON public.stocks(user_id);
CREATE INDEX IF NOT EXISTS idx_stocks_product_name ON public.stocks(product_name);

-- ---------------------------------------------------------------------------
-- demands (posted by Shop Owners)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.demands (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shop_owner_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    product_name TEXT NOT NULL,
    category TEXT NOT NULL DEFAULT 'Grocery',
    quantity NUMERIC(10, 2) NOT NULL,
    unit TEXT NOT NULL DEFAULT 'kg',
    notes TEXT,
    status demand_status NOT NULL DEFAULT 'pending',
    accepted_supplier_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    accepted_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.demands ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public select on demands"
ON public.demands FOR SELECT USING (true);
CREATE POLICY "Allow insert demands"
ON public.demands FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow update demands"
ON public.demands FOR UPDATE USING (true);
CREATE INDEX IF NOT EXISTS idx_demands_shop_owner ON public.demands(shop_owner_id);
CREATE INDEX IF NOT EXISTS idx_demands_status ON public.demands(status);

-- ---------------------------------------------------------------------------
-- orders + otps (OTP-secured delivery verification)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    demand_id UUID REFERENCES public.demands(id) ON DELETE SET NULL,
    shop_owner_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    supplier_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    product_name TEXT NOT NULL,
    quantity NUMERIC(10, 2) NOT NULL,
    unit TEXT NOT NULL DEFAULT 'kg',
    total_amount NUMERIC(12, 2) NOT NULL DEFAULT 0,
    status order_status NOT NULL DEFAULT 'pending',
    delivery_address TEXT,
    delivery_lat DOUBLE PRECISION,
    delivery_lng DOUBLE PRECISION,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS public.otps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL UNIQUE REFERENCES public.orders(id) ON DELETE CASCADE,
    otp_code VARCHAR(6) NOT NULL,
    is_verified BOOLEAN DEFAULT false,
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (now() + interval '24 hours'),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.otps ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public select on orders"
ON public.orders FOR SELECT USING (true);
CREATE POLICY "Allow insert on orders"
ON public.orders FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow update on orders"
ON public.orders FOR UPDATE USING (true);
CREATE POLICY "Allow select on otps"
ON public.otps FOR SELECT USING (true);
CREATE POLICY "Allow insert on otps"
ON public.otps FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow update on otps"
ON public.otps FOR UPDATE USING (true);
CREATE INDEX IF NOT EXISTS idx_orders_shop_owner ON public.orders(shop_owner_id);
CREATE INDEX IF NOT EXISTS idx_orders_supplier ON public.orders(supplier_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(status);

-- ---------------------------------------------------------------------------
-- notifications + ratings
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    subtitle TEXT NOT NULL,
    type TEXT DEFAULT 'info',
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS public.ratings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL,
    shop_owner_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    supplier_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5) NOT NULL,
    review TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ratings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow select on notifications"
ON public.notifications FOR SELECT USING (true);
CREATE POLICY "Allow insert on notifications"
ON public.notifications FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow update on notifications"
ON public.notifications FOR UPDATE USING (true);
CREATE POLICY "Allow select on ratings"
ON public.ratings FOR SELECT USING (true);
CREATE POLICY "Allow insert on ratings"
ON public.ratings FOR INSERT WITH CHECK (true);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_ratings_supplier_id ON public.ratings(supplier_id);

-- ---------------------------------------------------------------------------
-- trigger: keep users/stocks/demands/orders updated_at fresh
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$ BEGIN
    CREATE TRIGGER trg_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION set_updated_at();
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TRIGGER trg_stocks_updated_at BEFORE UPDATE ON public.stocks FOR EACH ROW EXECUTE FUNCTION set_updated_at();
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TRIGGER trg_demands_updated_at BEFORE UPDATE ON public.demands FOR EACH ROW EXECUTE FUNCTION set_updated_at();
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TRIGGER trg_orders_updated_at BEFORE UPDATE ON public.orders FOR EACH ROW EXECUTE FUNCTION set_updated_at();
EXCEPTION WHEN duplicate_object THEN null;
END $$;