# GAPSHAP 💬

A premium social messaging application built with Flutter, Supabase, and Riverpod.

## Features

### Authentication
- ✅ Email/Password signup & login
- ✅ Email verification
- ✅ Forgot/Reset password
- ✅ Session persistence & restoration
- ✅ Change password
- ✅ Account deletion

### Profile
- ✅ Profile creation & editing
- ✅ Avatar upload
- ✅ Username validation & uniqueness
- ✅ Profile viewing
- ✅ Bio & display name

### Real-time Chat
- ✅ One-to-one messaging
- ✅ Group messaging
- ✅ Real-time message delivery via Supabase Realtime
- ✅ Typing indicators
- ✅ Online status & last seen
- ✅ Delivered & read receipts
- ✅ Unread counts
- ✅ Message pagination (infinite scroll)
- ✅ Message search
- ✅ Conversation search

### Messages
- ✅ Text messages
- ✅ Emoji support
- ✅ Reply to messages
- ✅ Forward messages
- ✅ Edit messages (within 5 min)
- ✅ Delete messages (for me / everyone)
- ✅ Copy messages
- ✅ React to messages (👍❤️😂😮😢👏🔥)
- ✅ Save/star messages
- ✅ Message selection & multi-select

### Stories
- ✅ Create stories (image, video, text)
- ✅ Story viewer with progress bars
- ✅ Tap navigation (left/right)
- ✅ Hold to pause
- ✅ Story views tracking
- ✅ 24-hour auto expiration

### Contacts
- ✅ Search users by username
- ✅ Add/remove contacts
- ✅ Block/unblock users
- ✅ Start chat from profile

### Notifications
- ✅ Push notifications (FCM)
- ✅ New message notifications
- ✅ Notification routing to conversations

### Settings
- ✅ Account settings
- ✅ Privacy settings (online status, last seen, photo, stories, read receipts, typing)
- ✅ Notification preferences
- ✅ Appearance (dark/light mode)
- ✅ Blocked users management
- ✅ Help & about

### Privacy & Security
- ✅ Row Level Security (RLS) on all tables
- ✅ Profile photo visibility controls
- ✅ Online status visibility
- ✅ Last seen visibility
- ✅ Story visibility controls
- ✅ Read receipts toggle
- ✅ Typing indicator toggle
- ✅ Who can message you
- ✅ Blocking at database level
- ✅ Report users/messages/stories
- ✅ No sensitive keys in client code

### Offline Support
- ✅ Cached conversations
- ✅ Cached messages
- ✅ Cached profiles
- ✅ Offline state detection

## Architecture

### Tech Stack
- **Flutter** - Cross-platform mobile framework
- **Dart** - Programming language
- **Supabase** - Backend-as-a-Service (Auth, Database, Realtime, Storage)
- **PostgreSQL** - Database with RLS
- **Riverpod** - State management
- **GoRouter** - Navigation
- **Hive** - Local caching
- **FCM** - Push notifications

### Project Structure
```
lib/
  core/
    config/        # App configuration
    constants/     # App constants
    errors/        # Exception classes
    extensions/    # BuildContext extensions
    router/        # GoRouter configuration
    theme/         # Colors, typography, themes
    utils/         # Utilities
    network/       # Network helpers
    widgets/       # Shared widgets
  features/
    auth/          # Authentication
    onboarding/    # New user onboarding
    home/          # Home shell
    chat/          # Messaging
    stories/       # Stories
    contacts/      # Contacts
    profile/       # User profile
    notifications/ # Notifications
    settings/      # Settings
  shared/
    models/        # Shared models
    services/      # Shared services
    widgets/       # Shared widgets
  main.dart        # Entry point
  app.dart         # App widget
supabase/
  migrations/      # Database migrations
```

## Setup

### Prerequisites
- Flutter SDK 3.24+
- Dart SDK 3.5+
- Supabase project
- Firebase project (for push notifications)

### Environment Variables
Create `dart_define` file or pass via `--dart-define`:
```bash
flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co \
            --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

### Supabase Setup
1. Create a Supabase project at https://supabase.com
2. Run the migration SQL in `supabase/migrations/001_initial_schema.sql`
3. Enable Realtime on `messages`, `conversation_members`, `stories` tables
4. Configure Storage buckets (avatars, chat-media, story-media, voice-messages, documents)
5. Copy your project URL and anon key

### Database Setup
Go to Supabase SQL Editor and run:
```sql
-- Paste contents of supabase/migrations/001_initial_schema.sql
```

### Storage Setup
The migration creates these buckets:
- `avatars` (public)
- `chat-media` (private)
- `story-media` (private)
- `voice-messages` (private)
- `documents` (private)

### Push Notifications
1. Create Firebase project
2. Add `google-services.json` (Android) / `GoogleService-Info.plist` (iOS)
3. Configure FCM in Supabase Edge Functions

### Running
```bash
flutter pub get
flutter run
```

### Testing
```bash
flutter test
flutter test --coverage
```

### Building
```bash
# Debug
flutter build apk --debug

# Release
flutter build apk --release
flutter build appbundle --release
```

## CI/CD

GitHub Actions pipeline:
- Code analysis
- Format checking
- Unit tests
- Android build

See `.github/workflows/ci.yml`

## Database Schema

### Tables
- `profiles` - User profiles
- `contacts` - User contacts
- `blocked_users` - Blocked users
- `conversations` - Chat conversations
- `conversation_members` - Group memberships
- `messages` - Chat messages
- `message_reads` - Read receipts
- `saved_messages` - Saved/starred messages
- `stories` - User stories
- `story_views` - Story view tracking
- `notifications` - User notifications
- `push_tokens` - FCM push tokens
- `reports` - User reports

### Key Functions
- `get_conversations(user_id)` - Get conversations with last message & unread count
- `find_direct_conversation(user1, user2)` - Find existing DM
- `toggle_message_reaction(message_id, user_id, emoji)` - Toggle message reactions
- `mark_conversation_read(conversation_id, user_id)` - Mark messages as read

## License

MIT License
