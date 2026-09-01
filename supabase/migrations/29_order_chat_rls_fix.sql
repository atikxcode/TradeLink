-- Migration 029: Disable RLS for order chats
-- Description: Disabling RLS to allow order group chat interactions without strict policies.

ALTER TABLE public.order_chats DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_messages DISABLE ROW LEVEL SECURITY;
