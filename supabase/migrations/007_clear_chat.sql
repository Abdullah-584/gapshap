-- ═══════════════════════════════════════════════════════
-- FIX 007: Persistent "Clear Chat" via cleared_at timestamp
-- Adds a per-user timestamp on conversation_members so that
-- "Clear Chat" persists across sessions and devices.
-- ═══════════════════════════════════════════════════════

-- Add cleared_at column to conversation_members
ALTER TABLE public.conversation_members
  ADD COLUMN IF NOT EXISTS cleared_at TIMESTAMPTZ;

-- Update get_conversations to account for cleared_at
-- (last message might be before the user cleared the chat)
CREATE OR REPLACE FUNCTION public.get_conversations(p_user_id UUID)
RETURNS TABLE(
  id UUID,
  type TEXT,
  name TEXT,
  avatar_url TEXT,
  created_by UUID,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  last_message_content TEXT,
  last_message_sender_id UUID,
  last_message_created_at TIMESTAMPTZ,
  unread_count BIGINT,
  is_pinned BOOLEAN,
  is_muted BOOLEAN,
  other_user_id UUID,
  other_username TEXT,
  other_display_name TEXT,
  other_avatar_url TEXT,
  other_user_is_online BOOLEAN,
  member_count BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    c.id,
    c.type,
    c.name,
    c.avatar_url,
    c.created_by,
    c.created_at,
    c.updated_at,
    lm.content AS last_message_content,
    lm.sender_id AS last_message_sender_id,
    lm.created_at AS last_message_created_at,
    (
      SELECT COUNT(*)
      FROM messages m
      WHERE m.conversation_id = c.id
        AND m.sender_id != p_user_id
        AND m.created_at > cm.last_read_at
        AND m.created_at > COALESCE(cm.cleared_at, to_timestamp(0))
        AND m.is_deleted = FALSE
    ) AS unread_count,
    cm.is_pinned,
    cm.is_muted,
    CASE WHEN c.type = 'direct'
      THEN (SELECT cm2.user_id FROM conversation_members cm2 WHERE cm2.conversation_id = c.id AND cm2.user_id != p_user_id LIMIT 1)
      ELSE NULL
    END AS other_user_id,
    CASE WHEN c.type = 'direct'
      THEN (SELECT p.username FROM profiles p WHERE p.id = (SELECT cm2.user_id FROM conversation_members cm2 WHERE cm2.conversation_id = c.id AND cm2.user_id != p_user_id LIMIT 1))
      ELSE NULL
    END AS other_username,
    CASE WHEN c.type = 'direct'
      THEN (SELECT p.display_name FROM profiles p WHERE p.id = (SELECT cm2.user_id FROM conversation_members cm2 WHERE cm2.conversation_id = c.id AND cm2.user_id != p_user_id LIMIT 1))
      ELSE NULL
    END AS other_display_name,
    CASE WHEN c.type = 'direct'
      THEN (SELECT p.avatar_url FROM profiles p WHERE p.id = (SELECT cm2.user_id FROM conversation_members cm2 WHERE cm2.conversation_id = c.id AND cm2.user_id != p_user_id LIMIT 1))
      ELSE NULL
    END AS other_avatar_url,
    CASE WHEN c.type = 'direct'
      THEN (SELECT p.is_online FROM profiles p WHERE p.id = (SELECT cm2.user_id FROM conversation_members cm2 WHERE cm2.conversation_id = c.id AND cm2.user_id != p_user_id LIMIT 1))
      ELSE FALSE
    END AS other_user_is_online,
    (SELECT COUNT(*) FROM conversation_members cm3 WHERE cm3.conversation_id = c.id) AS member_count
  FROM conversations c
  JOIN conversation_members cm ON c.id = cm.conversation_id
  LEFT JOIN LATERAL (
    SELECT m.content, m.sender_id, m.created_at
    FROM messages m
    WHERE m.conversation_id = c.id
      AND m.is_deleted = FALSE
      AND m.created_at > COALESCE(cm.cleared_at, to_timestamp(0))
    ORDER BY m.created_at DESC
    LIMIT 1
  ) lm ON TRUE
  WHERE cm.user_id = p_user_id
  ORDER BY cm.is_pinned DESC, COALESCE(lm.created_at, c.created_at) DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
