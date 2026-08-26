-- Migration 028: Chat Images, Active Status
-- Description: Adds image_url to chat messages, last_active_at to users, and relaxes constraints on text_content

ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS last_active_at TIMESTAMPTZ DEFAULT now();

ALTER TABLE public.messages
ADD COLUMN IF NOT EXISTS image_url TEXT;

-- Drop the length constraint on text_content so that it's allowed to be empty if an image is provided
ALTER TABLE public.messages
DROP CONSTRAINT IF EXISTS messages_text_content_check;
ALTER TABLE public.messages
DROP CONSTRAINT IF EXISTS messages_content_check;

ALTER TABLE public.messages
ADD CONSTRAINT messages_content_check CHECK (
    (text_content IS NOT NULL AND length(trim(text_content)) > 0) OR
    (image_url IS NOT NULL AND length(trim(image_url)) > 0)
);

ALTER TABLE public.order_messages
ADD COLUMN IF NOT EXISTS image_url TEXT;

-- Drop the length constraint on text_content so that it's allowed to be empty if an image is provided
ALTER TABLE public.order_messages
DROP CONSTRAINT IF EXISTS order_messages_text_content_check;
ALTER TABLE public.order_messages
DROP CONSTRAINT IF EXISTS order_messages_content_check;

ALTER TABLE public.order_messages
ADD CONSTRAINT order_messages_content_check CHECK (
    (text_content IS NOT NULL AND length(trim(text_content)) > 0) OR
    (image_url IS NOT NULL AND length(trim(image_url)) > 0)
);
