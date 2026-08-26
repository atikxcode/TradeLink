-- Migration 027: Order Group Chat
-- Description: Creates a group chat specific to an order, allowing Shop Owner, Supplier, and Delivery Rider to communicate.

CREATE TABLE IF NOT EXISTS public.order_chats (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id       UUID NOT NULL UNIQUE REFERENCES public.orders(id) ON DELETE CASCADE,
    last_message   TEXT NOT NULL DEFAULT '',
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.order_messages (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_chat_id  UUID NOT NULL REFERENCES public.order_chats(id) ON DELETE CASCADE,
    sender_type    TEXT NOT NULL CHECK (sender_type IN ('SHOP_OWNER', 'SUPPLIER', 'DELIVERY_RIDER')),
    sender_id      UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    text_content   TEXT NOT NULL CHECK (length(trim(text_content)) > 0),
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_order_messages_chat ON public.order_messages(order_chat_id, created_at);
CREATE INDEX IF NOT EXISTS idx_order_chats_updated ON public.order_chats(updated_at DESC);
