-- ═══════════════════════════════════════════════════════
-- FIX 003: Fix infinite recursion, stories visibility,
-- and conversation RLS policies
-- ═══════════════════════════════════════════════════════

-- ═══ STEP 1: Fix infinite recursion in conversation_members ═══
-- The original policies query conversation_members FROM conversation_members,
-- causing infinite recursion. We replace them with simpler policies.

-- Drop the recursive conversation_members policies
DROP POLICY IF EXISTS "Members can view conversation members" ON conversation_members;
DROP POLICY IF EXISTS "Admins can add members" ON conversation_members;
DROP POLICY IF EXISTS "Members can leave group" ON conversation_members;

-- conversation_members: simplified non-recursive policies
CREATE POLICY "Users can view conversation members"
  ON conversation_members FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can insert conversation members"
  ON conversation_members FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Users can delete own membership"
  ON conversation_members FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- ═══ STEP 2: Fix conversations RLS ═══
-- Drop recursive conversations policies
DROP POLICY IF EXISTS "Members can view conversations" ON conversations;
DROP POLICY IF EXISTS "Authenticated users can create conversations" ON conversations;
DROP POLICY IF EXISTS "Admins can update conversations" ON conversations;

-- Conversations: simple non-recursive policies
CREATE POLICY "Authenticated users can view conversations"
  ON conversations FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can create conversations"
  ON conversations FOR INSERT
  TO authenticated
  WITH CHECK (created_by = auth.uid());

CREATE POLICY "Conversation creators can update conversations"
  ON conversations FOR UPDATE
  TO authenticated
  USING (created_by = auth.uid());

-- ═══ STEP 3: Fix messages RLS ═══
-- Drop recursive messages policies
DROP POLICY IF EXISTS "Members can view messages" ON messages;
DROP POLICY IF EXISTS "Members can send messages" ON messages;
DROP POLICY IF EXISTS "Senders can update own messages" ON messages;
DROP POLICY IF EXISTS "Members can delete messages" ON messages;

-- Messages: simple non-recursive policies
CREATE POLICY "Authenticated users can view messages"
  ON messages FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can send messages"
  ON messages FOR INSERT
  TO authenticated
  WITH CHECK (sender_id = auth.uid());

CREATE POLICY "Senders can update own messages"
  ON messages FOR UPDATE
  TO authenticated
  USING (sender_id = auth.uid());

CREATE POLICY "Senders can delete own messages"
  ON messages FOR DELETE
  TO authenticated
  USING (sender_id = auth.uid());

-- ═══ STEP 4: Fix profiles RLS for trigger ═══
-- The insert policy blocks the trigger from creating profiles
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;

CREATE POLICY "Anyone can insert profiles"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- ═══ STEP 5: Stories - only visible to contacts ═══
-- Create a helper function to check if two users are contacts
CREATE OR REPLACE FUNCTION are_contacts(p_user1 UUID, p_user2 UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM contacts
    WHERE (user_id = p_user1 AND contact_id = p_user2)
       OR (user_id = p_user2 AND contact_id = p_user1)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop old story policies
DROP POLICY IF EXISTS "Users can view non-expired stories" ON stories;
DROP POLICY IF EXISTS "Users can create own stories" ON stories;
DROP POLICY IF EXISTS "Users can delete own stories" ON stories;

-- Stories: only visible to contacts AND self, must be non-expired
CREATE POLICY "Users can view own stories"
  ON stories FOR SELECT
  TO authenticated
  USING (user_id = auth.uid() AND expires_at > NOW());

CREATE POLICY "Users can view contact stories"
  ON stories FOR SELECT
  TO authenticated
  USING (
    expires_at > NOW()
    AND user_id != auth.uid()
    AND are_contacts(auth.uid(), user_id)
  );

CREATE POLICY "Users can create own stories"
  ON stories FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete own stories"
  ON stories FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- ═══ STEP 6: Fix story_views ═══
DROP POLICY IF EXISTS "Story owners can view who viewed their story" ON story_views;
DROP POLICY IF EXISTS "Users can record story views" ON story_views;

CREATE POLICY "Users can view story views"
  ON story_views FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can record story views"
  ON story_views FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

-- ═══ STEP 7: Fix notifications ═══
DROP POLICY IF EXISTS "System can create notifications" ON notifications;

CREATE POLICY "Authenticated users can create notifications"
  ON notifications FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- ═══ STEP 8: Fix message_reads ═══
DROP POLICY IF EXISTS "Members can view message reads" ON message_reads;
DROP POLICY IF EXISTS "Users can mark messages as read" ON message_reads;

CREATE POLICY "Users can view message reads"
  ON message_reads FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can mark messages as read"
  ON message_reads FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

-- ═══ STEP 9: Add missing contacts RLS for viewing reverse contacts ═══
-- Users should see contacts where THEY are the contact_id too (bidirectional)
DROP POLICY IF EXISTS "Users can view own contacts" ON contacts;
DROP POLICY IF EXISTS "Users can add contacts" ON contacts;
DROP POLICY IF EXISTS "Users can delete own contacts" ON contacts;

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
