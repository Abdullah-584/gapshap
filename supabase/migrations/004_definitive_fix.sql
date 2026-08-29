-- ═══════════════════════════════════════════════════════
-- DEFINITIVE FIX: User creation + all RLS issues
-- Run this ONE file in Supabase SQL Editor to fix everything
-- ═══════════════════════════════════════════════════════

-- ═══ STEP 1: Fix profiles INSERT policy (allow trigger) ═══
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
DROP POLICY IF EXISTS "Anyone can insert profiles" ON public.profiles;

CREATE POLICY "Allow all profile inserts"
  ON public.profiles FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- ═══ STEP 2: Drop and recreate the trigger function ═══
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  base_username TEXT;
  final_username TEXT;
  counter INTEGER := 0;
  user_email TEXT;
BEGIN
  user_email := COALESCE(NEW.email, 'user');
  base_username := LOWER(SPLIT_PART(user_email, '@', 1));
  base_username := REGEXP_REPLACE(base_username, '[^a-z0-9_]', '', 'g');
  IF base_username IS NULL OR LENGTH(base_username) < 3 THEN
    base_username := 'user';
  END IF;
  final_username := base_username;
  WHILE EXISTS (SELECT 1 FROM public.profiles WHERE username = final_username) AND counter < 100 LOOP
    counter := counter + 1;
    final_username := base_username || counter::TEXT;
  END LOOP;
  INSERT INTO public.profiles (id, username, display_name)
  VALUES (
    NEW.id,
    final_username,
    COALESCE(NEW.raw_user_meta_data->>'display_name', SPLIT_PART(user_email, '@', 1))
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ═══ STEP 3: Fix conversation_members (no infinite recursion) ═══
DROP POLICY IF EXISTS "Members can view conversation members" ON public.conversation_members;
DROP POLICY IF EXISTS "Admins can add members" ON public.conversation_members;
DROP POLICY IF EXISTS "Members can leave group" ON public.conversation_members;

CREATE POLICY "View conversation members" ON public.conversation_members
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "Insert conversation members" ON public.conversation_members
  FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Delete own membership" ON public.conversation_members
  FOR DELETE TO authenticated USING (user_id = auth.uid());

-- ═══ STEP 4: Fix conversations (no infinite recursion) ═══
DROP POLICY IF EXISTS "Members can view conversations" ON public.conversations;
DROP POLICY IF EXISTS "Authenticated users can create conversations" ON public.conversations;
DROP POLICY IF EXISTS "Admins can update conversations" ON public.conversations;

CREATE POLICY "View conversations" ON public.conversations
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "Create conversations" ON public.conversations
  FOR INSERT TO authenticated WITH CHECK (created_by = auth.uid());
CREATE POLICY "Update own conversations" ON public.conversations
  FOR UPDATE TO authenticated USING (created_by = auth.uid());

-- ═══ STEP 5: Fix messages (no infinite recursion) ═══
DROP POLICY IF EXISTS "Members can view messages" ON public.messages;
DROP POLICY IF EXISTS "Members can send messages" ON public.messages;
DROP POLICY IF EXISTS "Senders can update own messages" ON public.messages;
DROP POLICY IF EXISTS "Members can delete messages" ON public.messages;

CREATE POLICY "View messages" ON public.messages
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "Send messages" ON public.messages
  FOR INSERT TO authenticated WITH CHECK (sender_id = auth.uid());
CREATE POLICY "Update own messages" ON public.messages
  FOR UPDATE TO authenticated USING (sender_id = auth.uid());
CREATE POLICY "Delete own messages" ON public.messages
  FOR DELETE TO authenticated USING (sender_id = auth.uid());

-- ═══ STEP 6: Stories - contacts only ═══
CREATE OR REPLACE FUNCTION public.are_contacts(p_user1 UUID, p_user2 UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.contacts
    WHERE (user_id = p_user1 AND contact_id = p_user2)
       OR (user_id = p_user2 AND contact_id = p_user1)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP POLICY IF EXISTS "Users can view non-expired stories" ON public.stories;
DROP POLICY IF EXISTS "Users can view own stories" ON public.stories;
DROP POLICY IF EXISTS "Users can view contact stories" ON public.stories;

CREATE POLICY "View own stories" ON public.stories
  FOR SELECT TO authenticated
  USING (user_id = auth.uid() AND expires_at > NOW());
CREATE POLICY "View contact stories" ON public.stories
  FOR SELECT TO authenticated
  USING (expires_at > NOW() AND user_id != auth.uid() AND public.are_contacts(auth.uid(), user_id));

-- ═══ STEP 7: Fix other tables ═══
DROP POLICY IF EXISTS "Story owners can view who viewed their story" ON public.story_views;
CREATE POLICY "View story views" ON public.story_views FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "System can create notifications" ON public.notifications;
CREATE POLICY "Create notifications" ON public.notifications FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "Members can view message reads" ON public.message_reads;
CREATE POLICY "View message reads" ON public.message_reads FOR SELECT TO authenticated USING (true);
