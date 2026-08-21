-- =============================================================================
-- TradeLink — User Auth OTP (Shop Owner & Stockholder)
--
-- Stores one-time passwords used for phone-based LOGIN of shop owners and
-- stockholders (suppliers). Registration does NOT use OTP. Keyed by
-- phone_number (+ role) instead of user_id so an OTP can be issued for a
-- phone number that already has a users row.
-- This is separate from public.otps which is delivery verification only.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Table: user_auth_otps
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_auth_otps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone_number TEXT NOT NULL,
    role user_role NOT NULL DEFAULT 'shop_owner',
    otp_code VARCHAR(6) NOT NULL,
    is_verified BOOLEAN NOT NULL DEFAULT false,
    attempts INTEGER NOT NULL DEFAULT 0,            -- brute-force guard
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT (now() + interval '5 minutes'),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

COMMENT ON TABLE public.user_auth_otps IS
    'Login one-time passwords for shop_owner / supplier (stockholder) phone auth';

-- ---------------------------------------------------------------------------
-- Indexes: latest OTP per phone+role lookup, expiry cleanup
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_user_auth_otps_phone_role
ON public.user_auth_otps(phone_number, role, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_user_auth_otps_expires_at
ON public.user_auth_otps(expires_at);

-- ---------------------------------------------------------------------------
-- RLS Policies (same open model as the rest of the schema)
-- ---------------------------------------------------------------------------
ALTER TABLE public.user_auth_otps ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow select on user_auth_otps"
ON public.user_auth_otps FOR SELECT USING (true);

CREATE POLICY "Allow insert on user_auth_otps"
ON public.user_auth_otps FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow update on user_auth_otps"
ON public.user_auth_otps FOR UPDATE USING (true);

CREATE POLICY "Allow delete on user_auth_otps"
ON public.user_auth_otps FOR DELETE USING (true);

-- ---------------------------------------------------------------------------
-- Housekeeping: invalidate older unverified OTPs when a new one is issued,
-- and purge expired rows (call via pg_cron or from the backend after send)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION invalidate_previous_otps(
    p_phone_number TEXT,
    p_role user_role
)
RETURNS void AS $$
BEGIN
    UPDATE public.user_auth_otps
    SET is_verified = true  -- mark consumed so old codes can never verify
    WHERE phone_number = p_phone_number
      AND role = p_role
      AND is_verified = false;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION purge_expired_auth_otps()
RETURNS void AS $$
BEGIN
    DELETE FROM public.user_auth_otps
    WHERE expires_at < now() - interval '1 day';
END;
$$ LANGUAGE plpgsql;
