-- ============================================================================
-- Enable Supabase Realtime for chat tables
-- ============================================================================
-- This migration enables real-time subscriptions for chat_conversations and chat_messages tables
-- Run this after 022_create_chat_tables.sql
-- ============================================================================

-- Enable Realtime for chat_conversations table
ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_conversations;

-- Enable Realtime for chat_messages table
ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_messages;

-- Verify Realtime is enabled for chat_conversations
SELECT 
  CASE 
    WHEN EXISTS (
      SELECT 1 
      FROM pg_publication_tables 
      WHERE pubname = 'supabase_realtime' 
      AND tablename = 'chat_conversations'
      AND schemaname = 'public'
    ) THEN '✅ Realtime enabled for chat_conversations'
    ELSE '❌ Realtime NOT enabled for chat_conversations'
  END AS chat_conversations_realtime_status;

-- Verify Realtime is enabled for chat_messages
SELECT 
  CASE 
    WHEN EXISTS (
      SELECT 1 
      FROM pg_publication_tables 
      WHERE pubname = 'supabase_realtime' 
      AND tablename = 'chat_messages'
      AND schemaname = 'public'
    ) THEN '✅ Realtime enabled for chat_messages'
    ELSE '❌ Realtime NOT enabled for chat_messages'
  END AS chat_messages_realtime_status;

