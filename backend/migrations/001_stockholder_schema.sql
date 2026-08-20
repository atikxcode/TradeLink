-- =============================================================================
-- TradeLink — Stockholder Feature Suite
-- PostgreSQL / Supabase Migration (v1)
--
-- Entities:
--   1. users & stockholders
--   2. stock_items
--   3. demands
--   4. orders
--   5. notifications
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------------
CREATE TYPE demand_status AS ENUM ('pending', 'accepted', 'declined', 'completed');
CREATE TYPE order_status AS ENUM ('accepted', 'out_for_delivery', 'delivered', 'cancelled');
CREATE TYPE recipient_role AS ENUM ('stockholder', 'shop_owner');

-- ---------------------------------------------------------------------------
-- 1. users & stockholders
-- ---------------------------------------------------------------------------
CREATE TABLE users (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone         VARCHAR(20) NOT NULL UNIQUE,
    role          recipient_role NOT NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE stockholders (
    stockholder_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id           UUID UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    business_name     VARCHAR(120) NOT NULL,
    owner_name        VARCHAR(120),
    phone             VARCHAR(20) NOT NULL UNIQUE,
    warehouse_address TEXT,
    location_lat      DOUBLE PRECISION,
    location_lng      DOUBLE PRECISION,
    location_geo      GEOGRAPHY(POINT, 4326),
    rating            DECIMAL(2, 1) NOT NULL DEFAULT 5.0 CHECK (rating >= 0 AND rating <= 5),
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_stockholders_location_geo ON stockholders USING GIST (location_geo);
CREATE INDEX idx_stockholders_phone ON stockholders (phone);

-- ---------------------------------------------------------------------------
-- 2. stock_items (Stock listings created by Stockholders)
-- ---------------------------------------------------------------------------
CREATE TABLE stock_items (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    stockholder_id     UUID NOT NULL REFERENCES stockholders(stockholder_id) ON DELETE CASCADE,
    category           VARCHAR(30) NOT NULL
                         CHECK (category IN ('Grocery', 'Pharmacy', 'Stationery', 'Hardware')),
    product_name       VARCHAR(160) NOT NULL,
    quantity_available DECIMAL(10, 2) NOT NULL DEFAULT 0 CHECK (quantity_available >= 0),
    unit               VARCHAR(10) NOT NULL DEFAULT 'kg'
                         CHECK (unit IN ('kg', 'litre', 'pcs')),
    price_per_unit     DECIMAL(10, 2) NOT NULL CHECK (price_per_unit >= 0),
    service_radius_km  INT NOT NULL DEFAULT 10 CHECK (service_radius_km >= 0),
    is_active          BOOLEAN NOT NULL DEFAULT true,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_stock_items_stockholder ON stock_items (stockholder_id) WHERE is_active = true;
CREATE INDEX idx_stock_items_product_name ON stock_items (product_name);
CREATE INDEX idx_stock_items_category ON stock_items (category);

-- ---------------------------------------------------------------------------
-- 3. demands (Posted by Shop Owners)
-- ---------------------------------------------------------------------------
CREATE TABLE demands (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shop_owner_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    product_name     VARCHAR(160) NOT NULL,
    quantity         DECIMAL(10, 2) NOT NULL CHECK (quantity > 0),
    unit             VARCHAR(10) NOT NULL DEFAULT 'kg',
    delivery_location TEXT,
    location_lat     DOUBLE PRECISION,
    location_lng     DOUBLE PRECISION,
    location_geo     GEOGRAPHY(POINT, 4326),
    notes            TEXT,
    status           demand_status NOT NULL DEFAULT 'pending',
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_demands_status ON demands (status) WHERE status = 'pending';
CREATE INDEX idx_demands_location_geo ON demands USING GIST (location_geo);
CREATE INDEX idx_demands_shop_owner ON demands (shop_owner_id);

-- ---------------------------------------------------------------------------
-- 4. orders (Created when Stockholder accepts a Demand)
-- ---------------------------------------------------------------------------
CREATE TABLE orders (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    demand_id      UUID NOT NULL REFERENCES demands(id) ON DELETE CASCADE,
    stockholder_id UUID NOT NULL REFERENCES stockholders(stockholder_id) ON DELETE CASCADE,
    shop_owner_id  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    delivery_otp   VARCHAR(6) NOT NULL,
    status         order_status NOT NULL DEFAULT 'accepted',
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_orders_stockholder_status ON orders (stockholder_id, status);
CREATE INDEX idx_orders_shop_owner ON orders (shop_owner_id);
CREATE INDEX idx_orders_demand ON orders (demand_id);

-- ---------------------------------------------------------------------------
-- 5. notifications
-- ---------------------------------------------------------------------------
CREATE TABLE notifications (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipient_id   UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    recipient_role recipient_role NOT NULL,
    title          VARCHAR(160) NOT NULL,
    message        TEXT NOT NULL,
    type           VARCHAR(40) NOT NULL
                     CHECK (type IN ('ORDER_ACCEPTED', 'DELIVERY_OTP', 'MATCH_FOUND', 'STOCK_DECLINED')),
    is_read        BOOLEAN NOT NULL DEFAULT false,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_notifications_recipient ON notifications (recipient_id, created_at DESC);
CREATE INDEX idx_notifications_unread ON notifications (recipient_id) WHERE is_read = false;

-- ---------------------------------------------------------------------------
-- trigger: keep stock_items.updated_at fresh
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_stock_items_updated_at
    BEFORE UPDATE ON stock_items
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();