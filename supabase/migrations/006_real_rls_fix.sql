-- ═══════════════════════════════════════════════════════
-- FIX 006: REAL RLS fix — membership-scoped access control
-- Previous 003/004/005 migrations used USING(true) on most
-- tables, meaning any authenticated user could read ALL
-- messages. This migration uses SECURITY DEFINER functions
-- to check membership without causing infinite recursion.
-- ═══════════════════════════════════════════════════════

-- ═══ STEP 1: SECURITY DEFINER helper functions ═══
-- These bypass RLS when querying conversation_members,
-- preventing the infinite recursion that occurs when an
-- RLS policy on conversation_members tries to query itself.

-- Check if a user is a member of a conversation
CREATE OR REPLACE FUNCTION public.is_conversation_member(
  p_conversation_id UUID,
  p_user_id UUID
) RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.conversation_members
    WHERE conversation_id = p_conversation_id
      AND user_id = p_user_id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Check if a user is in a conversation that contains a given message
CREATE OR REPLACE FUNCTION public.is_message_conversation_member(
  p_message_id UUID,
  p_user_id UUID
) RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.messages m
    JOIN public.conversation_members cm
      ON cm.conversation_id = m.conversation_id
    WHERE m.id = p_message_id
      AND cm.user_id = p_user_id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Check if a user can view a story (self or contacts)
CREATE OR REPLACE FUNCTION public.can_view_story(
  p_story_id UUID,
  p_user_id UUID
) RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.stories s
    WHERE s.id = p_story_id
      AND s.expires_at > NOW()
      AND (
        s.user_id = p_user_id
        OR public.are_contacts(p_user_id, s.user_id)
      )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ═══ STEP 2: conversation_members ═══
-- Safe to be readable by all authenticated users — knowing
-- who is in which group is a much smaller exposure than the
-- actual messages. The alternative (SECURITY DEFINER) would
-- work too, but this is simpler and acceptable.

DROP POLICY IF EXISTS "View conversation members" ON public.conversation_members;
DROP POLICY IF EXISTS "View members of own conversations" ON public.conversation_members;
DROP POLICY IF EXISTS "Insert conversation members" ON public.conversation_members;
DROP POLICY IF EXISTS "Add members to own conversations" ON public.conversation_members;
DROP POLICY IF EXISTS "Delete own membership" ON public.conversation_members;

CREATE POLICY "Authenticated can view members" ON public.conversation_members
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Authenticated can add members" ON public.conversation_members
  FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Delete own membership" ON public.conversation_members
  FOR DELETE TO authenticated USING (user_id = auth.uid());

-- ═══ STEP 3: conversations ═══
-- Safe to be readable — conversation metadata (name, type) is
-- low-sensitivity. The actual content is in messages, which we
-- scope below.

DROP POLICY IF EXISTS "View conversations" ON public.conversations;
DROP POLICY IF EXISTS "View own conversations" ON public.conversations;
DROP POLICY IF EXISTS "Create conversations" ON public.conversations;
DROP POLICY IF EXISTS "Update own conversations" ON public.conversations;

CREATE POLICY "Authenticated can view conversations" ON public.conversations
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Authenticated can create conversations" ON public.conversations
  FOR INSERT TO authenticated WITH CHECK (created_by = auth.uid());

CREATE POLICY "Creators can update conversations" ON public.conversations
  FOR UPDATE TO authenticated USING (created_by = auth.uid());

-- ═══ STEP 4: messages ═══
-- THIS IS THE CRITICAL ONE. Messages must only be readable
-- by members of the conversation. SECURITY DEFINER function
-- bypasses RLS on conversation_members to check membership
-- without causing infinite recursion.

DROP POLICY IF EXISTS "View messages" ON public.messages;
DROP POLICY IF EXISTS "Authenticated users can view messages" ON public.messages;

CREATE POLICY "Members can view messages" ON public.messages
  FOR SELECT TO authenticated
  USING (public.is_conversation_member(conversation_id, auth.uid()));

DROP POLICY IF EXISTS "Send messages" ON public.messages;
DROP POLICY IF EXISTS "Authenticated users can send messages" ON public.messages;

CREATE POLICY "Members can send messages" ON public.messages
  FOR INSERT TO authenticated
  WITH CHECK (
    sender_id = auth.uid()
    AND public.is_conversation_member(conversation_id, auth.uid())
  );

DROP POLICY IF EXISTS "Update own messages" ON public.messages;
DROP POLICY IF EXISTS "Senders can update own messages" ON public.messages;

CREATE POLICY "Senders can update own messages" ON public.messages
  FOR UPDATE TO authenticated
  USING (sender_id = auth.uid());

DROP POLICY IF EXISTS "Delete own messages" ON public.messages;
DROP POLICY IF EXISTS "Senders can delete own messages" ON public.messages;

CREATE POLICY "Senders can delete own messages" ON public.messages
  FOR DELETE TO authenticated
  USING (sender_id = auth.uid());

-- ═══ STEP 5: stories ═══
-- Must be scoped to contacts-only (WhatsApp-style).

DROP POLICY IF EXISTS "View own stories" ON public.stories;
DROP POLICY IF EXISTS "View contact stories" ON public.stories;
DROP POLICY IF EXISTS "Users can view non-expired stories" ON public.stories;
DROP POLICY IF EXISTS "Users can view own stories" ON public.stories;
DROP POLICY IF EXISTS "Users can view contact stories" ON public.stories;

CREATE POLICY "View own stories" ON public.stories
  FOR SELECT TO authenticated
  USING (user_id = auth.uid() AND expires_at > NOW());

CREATE POLICY "View contact stories" ON public.stories
  FOR SELECT TO authenticated
  USING (
    expires_at > NOW()
    AND user_id != auth.uid()
    AND public.are_contacts(auth.uid(), user_id)
  );

-- ═══ STEP 6: story_views ═══
DROP POLICY IF EXISTS "View story views" ON public.story_views;

CREATE POLICY "Authenticated can view story views" ON public.story_views
  FOR SELECT TO authenticated USING (true);

-- ═══ STEP 7: message_reads ═══
DROP POLICY IF EXISTS "View message reads" ON public.message_reads;
DROP POLICY IF EXISTS "Authenticated can view message reads" ON public.message_reads;
DROP POLICY IF EXISTS "Users can view message reads" ON public.message_reads;

CREATE POLICY "Authenticated can view message reads" ON public.message_reads
  FOR SELECT TO authenticated USING (true);

-- ═══ STEP 8: notifications ═══
DROP POLICY IF EXISTS "View own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Create notifications" ON public.notifications;
DROP POLICY IF EXISTS "Authenticated users can create notifications" ON public.notifications;

CREATE POLICY "View own notifications" ON public.notifications
  FOR SELECT TO authenticated USING (user_id = auth.uid());

CREATE POLICY "Authenticated can create notifications" ON public.notifications
  FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Update own notifications" ON public.notifications
  FOR UPDATE TO authenticated USING (user_id = auth.uid());
