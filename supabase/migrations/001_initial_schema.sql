-- ═══════════════════════════════════════════════════════
-- GAPSHAP Database Schema
-- Complete production database migration
-- ═══════════════════════════════════════════════════════

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";  -- For text search

-- ═══════════════════════════════════════════════
-- 1. PROFILES
-- ═══════════════════════════════════════════════
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE NOT NULL,
  display_name TEXT NOT NULL,
  avatar_url TEXT,
  bio TEXT,
  is_online BOOLEAN DEFAULT FALSE,
  last_seen TIMESTAMPTZ,
  online_status_visibility TEXT DEFAULT 'everyone' CHECK (online_status_visibility IN ('everyone', 'contacts', 'nobody')),
  last_seen_visibility TEXT DEFAULT 'everyone' CHECK (last_seen_visibility IN ('everyone', 'contacts', 'nobody')),
  profile_photo_visibility TEXT DEFAULT 'everyone' CHECK (profile_photo_visibility IN ('everyone', 'contacts', 'nobody')),
  read_receipts_enabled BOOLEAN DEFAULT TRUE,
  typing_indicator_enabled BOOLEAN DEFAULT TRUE,
  story_visibility TEXT DEFAULT 'everyone' CHECK (story_visibility IN ('everyone', 'contacts', 'nobody', 'close_friends')),
  message_permission TEXT DEFAULT 'everyone' CHECK (message_permission IN ('everyone', 'contacts', 'nobody')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_profiles_username ON profiles USING btree (username);
CREATE INDEX idx_profiles_username_trgm ON profiles USING gin (username gin_trgm_ops);
CREATE INDEX idx_profiles_display_name_trgm ON profiles USING gin (display_name gin_trgm_ops);

-- ═══════════════════════════════════════════════
-- 2. CONTACTS
-- ═══════════════════════════════════════════════
CREATE TABLE contacts (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  contact_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, contact_id),
  CHECK (user_id != contact_id)
);

CREATE INDEX idx_contacts_user_id ON contacts(user_id);
CREATE INDEX idx_contacts_contact_id ON contacts(contact_id);

-- ═══════════════════════════════════════════════
-- 3. BLOCKED USERS
-- ═══════════════════════════════════════════════
CREATE TABLE blocked_users (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  blocked_user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, blocked_user_id),
  CHECK (user_id != blocked_user_id)
);

CREATE INDEX idx_blocked_users_user_id ON blocked_users(user_id);
CREATE INDEX idx_blocked_users_blocked_user_id ON blocked_users(blocked_user_id);

-- ═══════════════════════════════════════════════
-- 4. CONVERSATIONS
-- ═══════════════════════════════════════════════
CREATE TABLE conversations (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  type TEXT NOT NULL CHECK (type IN ('direct', 'group')),
  name TEXT,
  avatar_url TEXT,
  created_by UUID NOT NULL REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ═══════════════════════════════════════════════
-- 5. CONVERSATION MEMBERS
-- ═══════════════════════════════════════════════
CREATE TABLE conversation_members (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  role TEXT DEFAULT 'member' CHECK (role IN ('admin', 'member')),
  is_pinned BOOLEAN DEFAULT FALSE,
  is_muted BOOLEAN DEFAULT FALSE,
  last_read_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(conversation_id, user_id)
);

CREATE INDEX idx_conversation_members_user_id ON conversation_members(user_id);
CREATE INDEX idx_conversation_members_conversation_id ON conversation_members(conversation_id);

-- ═══════════════════════════════════════════════
-- 6. MESSAGES
-- ═══════════════════════════════════════════════
CREATE TABLE messages (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES profiles(id),
  type TEXT NOT NULL DEFAULT 'text' CHECK (type IN ('text', 'image', 'video', 'file', 'voice', 'system')),
  content TEXT,
  is_edited BOOLEAN DEFAULT FALSE,
  is_deleted BOOLEAN DEFAULT FALSE,
  reply_to_message_id UUID REFERENCES messages(id) ON DELETE SET NULL,
  reply_to_content TEXT,
  reply_to_sender_name TEXT,
  reply_to_type TEXT,
  attachment_url TEXT,
  attachment_thumbnail_url TEXT,
  attachment_name TEXT,
  attachment_mime_type TEXT,
  attachment_size INTEGER,
  attachment_duration REAL,
  reactions JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  edited_at TIMESTAMPTZ
);

CREATE INDEX idx_messages_conversation_id_created_at ON messages(conversation_id, created_at DESC);
CREATE INDEX idx_messages_sender_id ON messages(sender_id, created_at DESC);
CREATE INDEX idx_messages_content_trgm ON messages USING gin (content gin_trgm_ops) WHERE is_deleted = FALSE;

-- ═══════════════════════════════════════════════
-- 7. MESSAGE READS
-- ═══════════════════════════════════════════════
CREATE TABLE message_reads (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  message_id UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  read_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(message_id, user_id)
);

CREATE INDEX idx_message_reads_message_id ON message_reads(message_id);

-- ═══════════════════════════════════════════════
-- 8. SAVED MESSAGES
-- ═══════════════════════════════════════════════
CREATE TABLE saved_messages (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  message_id UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, message_id)
);

CREATE INDEX idx_saved_messages_user_id ON saved_messages(user_id);

-- ═══════════════════════════════════════════════
-- 9. STORIES
-- ═══════════════════════════════════════════════
CREATE TABLE stories (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('image', 'video', 'text')),
  content TEXT,
  media_url TEXT,
  thumbnail_url TEXT,
  caption TEXT,
  background_color TEXT,
  font_family TEXT,
  view_count INTEGER DEFAULT 0,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_stories_user_id_created_at ON stories(user_id, created_at DESC);
CREATE INDEX idx_stories_expires_at ON stories(expires_at);

-- ═══════════════════════════════════════════════
-- 10. STORY VIEWS
-- ═══════════════════════════════════════════════
CREATE TABLE story_views (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  story_id UUID NOT NULL REFERENCES stories(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  viewed_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(story_id, user_id)
);

CREATE INDEX idx_story_views_story_id ON story_views(story_id);

-- ═══════════════════════════════════════════════
-- 11. NOTIFICATIONS
-- ═══════════════════════════════════════════════
CREATE TABLE notifications (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('new_message', 'reaction', 'story_interaction', 'contact_request', 'system')),
  title TEXT,
  body TEXT,
  conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
  story_id UUID REFERENCES stories(id) ON DELETE CASCADE,
  sender_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_notifications_user_id_created_at ON notifications(user_id, created_at DESC);

-- ═══════════════════════════════════════════════
-- 12. PUSH TOKENS
-- ═══════════════════════════════════════════════
CREATE TABLE push_tokens (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  token TEXT NOT NULL UNIQUE,
  platform TEXT NOT NULL CHECK (platform IN ('android', 'ios', 'web')),
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_push_tokens_user_id ON push_tokens(user_id);
CREATE INDEX idx_push_tokens_token ON push_tokens(token);

-- ═══════════════════════════════════════════════
-- 13. REPORTS
-- ═══════════════════════════════════════════════
CREATE TABLE reports (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  reporter_id UUID NOT NULL REFERENCES profiles(id),
  reported_user_id UUID REFERENCES profiles(id),
  reported_message_id UUID REFERENCES messages(id),
  reported_story_id UUID REFERENCES stories(id),
  reason TEXT NOT NULL CHECK (reason IN ('spam', 'harassment', 'inappropriate_content', 'impersonation', 'other')),
  description TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'resolved', 'dismissed')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ═══════════════════════════════════════════════
-- FUNCTIONS & TRIGGERS
-- ═══════════════════════════════════════════════

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, username, display_name)
  VALUES (
    NEW.id,
    LOWER(SPLIT_PART(NEW.email, '@', 1)),
    SPLIT_PART(NEW.email, '@', 1)
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Update conversation timestamp on new message
CREATE OR REPLACE FUNCTION update_conversation_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE conversations
  SET updated_at = NOW()
  WHERE id = NEW.conversation_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_new_message
  AFTER INSERT ON messages
  FOR EACH ROW EXECUTE FUNCTION update_conversation_timestamp();

-- Update story view count
CREATE OR REPLACE FUNCTION update_story_view_count()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE stories
  SET view_count = view_count + 1
  WHERE id = NEW.story_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_story_view
  AFTER INSERT ON story_views
  FOR EACH ROW EXECUTE FUNCTION update_story_view_count();

-- Auto-delete expired stories
CREATE OR REPLACE FUNCTION delete_expired_stories()
RETURNS void AS $$
BEGIN
  DELETE FROM stories WHERE expires_at < NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update online status
CREATE OR REPLACE FUNCTION update_online_status(
  p_user_id UUID,
  p_is_online BOOLEAN
)
RETURNS void AS $$
BEGIN
  UPDATE profiles
  SET is_online = p_is_online,
      last_seen = CASE WHEN p_is_online = FALSE THEN NOW() ELSE last_seen END,
      updated_at = NOW()
  WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Toggle message reaction
CREATE OR REPLACE FUNCTION toggle_message_reaction(
  p_message_id UUID,
  p_user_id UUID,
  p_emoji TEXT
)
RETURNS void AS $$
DECLARE
  current_reactions JSONB;
  emoji_users JSONB;
BEGIN
  SELECT reactions INTO current_reactions
  FROM messages WHERE id = p_message_id;

  emoji_users := current_reactions -> p_emoji;

  IF emoji_users IS NULL THEN
    -- Emoji doesn't exist, add it
    UPDATE messages
    SET reactions = reactions || jsonb_build_object(p_emoji, jsonb_build_array(p_user_id))
    WHERE id = p_message_id;
  ELSIF emoji_users @> to_jsonb(p_user_id) THEN
    -- User already reacted, remove their reaction
    emoji_users := (
      SELECT jsonb_agg(elem)
      FROM jsonb_array_elements_text(emoji_users) elem
      WHERE elem::uuid != p_user_id
    );

    IF emoji_users IS NULL OR jsonb_array_length(emoji_users) = 0 THEN
      -- No more reactions for this emoji, remove the key
      UPDATE messages
      SET reactions = reactions - p_emoji
      WHERE id = p_message_id;
    ELSE
      UPDATE messages
      SET reactions = jsonb_set(reactions, ARRAY[p_emoji], emoji_users)
      WHERE id = p_message_id;
    END IF;
  ELSE
    -- User hasn't reacted, add them
    UPDATE messages
    SET reactions = jsonb_set(
      reactions,
      ARRAY[p_emoji],
      (reactions -> p_emoji) || to_jsonb(p_user_id)
    )
    WHERE id = p_message_id;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Mark conversation as read
CREATE OR REPLACE FUNCTION mark_conversation_read(
  p_conversation_id UUID,
  p_user_id UUID
)
RETURNS void AS $$
BEGIN
  UPDATE conversation_members
  SET last_read_at = NOW()
  WHERE conversation_id = p_conversation_id
    AND user_id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Find direct conversation between two users
CREATE OR REPLACE FUNCTION find_direct_conversation(
  p_user1 UUID,
  p_user2 UUID
)
RETURNS TABLE(id UUID) AS $$
BEGIN
  RETURN QUERY
  SELECT cm1.conversation_id
  FROM conversation_members cm1
  JOIN conversation_members cm2 ON cm1.conversation_id = cm2.conversation_id
  JOIN conversations c ON c.id = cm1.conversation_id
  WHERE cm1.user_id = p_user1
    AND cm2.user_id = p_user2
    AND c.type = 'direct'
  LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get conversations with last message and unread count
CREATE OR REPLACE FUNCTION get_conversations(p_user_id UUID)
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
    WHERE m.conversation_id = c.id AND m.is_deleted = FALSE
    ORDER BY m.created_at DESC
    LIMIT 1
  ) lm ON TRUE
  WHERE cm.user_id = p_user_id
  ORDER BY cm.is_pinned DESC, COALESCE(lm.created_at, c.created_at) DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ═══════════════════════════════════════════════
-- ROW LEVEL SECURITY POLICIES
-- ═══════════════════════════════════════════════

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE blocked_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversation_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_reads ENABLE ROW LEVEL SECURITY;
ALTER TABLE saved_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE stories ENABLE ROW LEVEL SECURITY;
ALTER TABLE story_views ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE push_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

-- ═══ PROFILES ═══
-- Everyone can read profiles (for search, etc.)
CREATE POLICY "Profiles are viewable by authenticated users"
  ON profiles FOR SELECT
  TO authenticated
  USING (true);

-- Users can update own profile
CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING (id = auth.uid());

-- Users can insert own profile
CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (id = auth.uid());

-- ═══ CONTACTS ═══
CREATE POLICY "Users can view own contacts"
  ON contacts FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can add contacts"
  ON contacts FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete own contacts"
  ON contacts FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- ═══ BLOCKED USERS ═══
CREATE POLICY "Users can view own blocked users"
  ON blocked_users FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can block users"
  ON blocked_users FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can unblock users"
  ON blocked_users FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- ═══ CONVERSATIONS ═══
CREATE POLICY "Members can view conversations"
  ON conversations FOR SELECT
  TO authenticated
  USING (
    id IN (
      SELECT conversation_id FROM conversation_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Authenticated users can create conversations"
  ON conversations FOR INSERT
  TO authenticated
  WITH CHECK (created_by = auth.uid());

CREATE POLICY "Admins can update conversations"
  ON conversations FOR UPDATE
  TO authenticated
  USING (
    id IN (
      SELECT conversation_id FROM conversation_members
      WHERE user_id = auth.uid() AND role = 'admin'
    )
  );

-- ═══ CONVERSATION MEMBERS ═══
CREATE POLICY "Members can view conversation members"
  ON conversation_members FOR SELECT
  TO authenticated
  USING (
    conversation_id IN (
      SELECT conversation_id FROM conversation_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can add members"
  ON conversation_members FOR INSERT
  TO authenticated
  WITH CHECK (
    conversation_id IN (
      SELECT conversation_id FROM conversation_members
      WHERE user_id = auth.uid() AND role = 'admin'
    )
    OR user_id = auth.uid()
  );

CREATE POLICY "Members can leave group"
  ON conversation_members FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- ═══ MESSAGES ═══
CREATE POLICY "Members can view messages"
  ON messages FOR SELECT
  TO authenticated
  USING (
    conversation_id IN (
      SELECT conversation_id FROM conversation_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Members can send messages"
  ON messages FOR INSERT
  TO authenticated
  WITH CHECK (
    sender_id = auth.uid()
    AND conversation_id IN (
      SELECT conversation_id FROM conversation_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Senders can update own messages"
  ON messages FOR UPDATE
  TO authenticated
  USING (sender_id = auth.uid());

CREATE POLICY "Members can delete messages"
  ON messages FOR DELETE
  TO authenticated
  USING (
    sender_id = auth.uid()
    OR conversation_id IN (
      SELECT conversation_id FROM conversation_members
      WHERE user_id = auth.uid() AND role = 'admin'
    )
  );

-- ═══ MESSAGE READS ═══
CREATE POLICY "Members can view message reads"
  ON message_reads FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can mark messages as read"
  ON message_reads FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

-- ═══ SAVED MESSAGES ═══
CREATE POLICY "Users can view own saved messages"
  ON saved_messages FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can save messages"
  ON saved_messages FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can unsave messages"
  ON saved_messages FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- ═══ STORIES ═══
CREATE POLICY "Users can view non-expired stories"
  ON stories FOR SELECT
  TO authenticated
  USING (expires_at > NOW());

CREATE POLICY "Users can create own stories"
  ON stories FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete own stories"
  ON stories FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- ═══ STORY VIEWS ═══
CREATE POLICY "Story owners can view who viewed their story"
  ON story_views FOR SELECT
  TO authenticated
  USING (
    story_id IN (
      SELECT id FROM stories WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can record story views"
  ON story_views FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

-- ═══ NOTIFICATIONS ═══
CREATE POLICY "Users can view own notifications"
  ON notifications FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "System can create notifications"
  ON notifications FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Users can update own notifications"
  ON notifications FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid());

-- ═══ PUSH TOKENS ═══
CREATE POLICY "Users can manage own push tokens"
  ON push_tokens FOR ALL
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ═══ REPORTS ═══
CREATE POLICY "Users can create reports"
  ON reports FOR INSERT
  TO authenticated
  WITH CHECK (reporter_id = auth.uid());

-- ═══════════════════════════════════════════════
-- STORAGE BUCKETS & POLICIES
-- ═══════════════════════════════════════════════

-- Create storage buckets
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  ('avatars', 'avatars', true, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp']),
  ('chat-media', 'chat-media', false, 52428800, ARRAY['image/jpeg', 'image/png', 'image/webp', 'video/mp4', 'video/quicktime']),
  ('story-media', 'story-media', false, 52428800, ARRAY['image/jpeg', 'image/png', 'image/webp', 'video/mp4', 'video/quicktime']),
  ('voice-messages', 'voice-messages', false, 10485760, ARRAY['audio/mpeg', 'audio/wav', 'audio/ogg']),
  ('documents', 'documents', false, 52428800, ARRAY['application/pdf', 'text/plain', 'application/msword', 'application/vnd.openxmlformats-officedocument.*']);

-- Storage policies: Avatars (public read, owner write)
CREATE POLICY "Avatar images are publicly accessible"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');

CREATE POLICY "Anyone can upload an avatar"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'avatars');

-- Storage policies: Chat media
CREATE POLICY "Chat members can view chat media"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (bucket_id = 'chat-media');

CREATE POLICY "Authenticated users can upload chat media"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'chat-media');

-- Storage policies: Story media
CREATE POLICY "Authenticated users can view story media"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (bucket_id = 'story-media');

CREATE POLICY "Authenticated users can upload story media"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'story-media');

-- Storage policies: Voice messages
CREATE POLICY "Authenticated users can view voice messages"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (bucket_id = 'voice-messages');

CREATE POLICY "Authenticated users can upload voice messages"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'voice-messages');

-- Storage policies: Documents
CREATE POLICY "Authenticated users can view documents"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (bucket_id = 'documents');

CREATE POLICY "Authenticated users can upload documents"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'documents');
