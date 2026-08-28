class AppConfig {
  AppConfig._();

  // Supabase Configuration
  // These should come from environment variables in production
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://bciugzjibbhzcmalmaiz.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJjaXVnemppYmJoemNtYWxtYWl6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc4OTY1ODYsImV4cCI6MjEwMzQ3MjU4Nn0.iwkfurW5wrtgNfUfgCPBa0wtgTA6evT26irLEdwVlvI',
  );

  // App Info
  static const String appName = 'GAPSHAP';
  static const String appVersion = '1.0.0';

  // Storage Buckets
  static const String avatarsBucket = 'avatars';
  static const String chatMediaBucket = 'chat-media';
  static const String storyMediaBucket = 'story-media';
  static const String voiceMessagesBucket = 'voice-messages';
  static const String documentsBucket = 'documents';

  // Limits
  static const int maxFileSizeMB = 50;
  static const int maxImageSizeMB = 10;
  static const int maxVideoSizeMB = 50;
  static const int maxVoiceMessageDurationSeconds = 300; // 5 minutes
  static const int messagesPageSize = 30;
  static const int storyExpirationHours = 24;
  static const int maxGroupMembers = 256;
  static const int maxBioLength = 200;
  static const int maxGroupNameLength = 100;
  static const int maxMessageLength = 5000;

  // Message Edit Window (5 minutes)
  static const Duration editWindow = Duration(minutes: 5);
}
