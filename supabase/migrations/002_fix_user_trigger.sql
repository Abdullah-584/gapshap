-- Fix: handle_new_user trigger with duplicate username handling
-- Run this in Supabase SQL Editor if user creation fails
--
-- This migration fixes "Database error creating new user" by:
-- 1. Handling duplicate usernames (appends a number)
-- 2. Handling NULL emails gracefully
-- 3. Using explicit schema references for reliability

-- Drop the old trigger and function first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user();

-- Create fixed function with explicit public schema references
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  base_username TEXT;
  final_username TEXT;
  counter INTEGER := 0;
  user_email TEXT;
BEGIN
  -- Safely extract email
  user_email := COALESCE(NEW.email, 'user');

  -- Generate base username from email
  base_username := LOWER(SPLIT_PART(user_email, '@', 1));
  -- Remove non-alphanumeric characters except underscores
  base_username := REGEXP_REPLACE(base_username, '[^a-z0-9_]', '', 'g');
  -- Ensure it's not empty or too short
  IF base_username IS NULL OR LENGTH(base_username) < 3 THEN
    base_username := 'user';
  END IF;
  
  final_username := base_username;
  
  -- Check for uniqueness and append number if needed (max 100 attempts)
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

-- Recreate the trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
