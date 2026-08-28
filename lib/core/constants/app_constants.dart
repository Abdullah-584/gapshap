/// App-wide constants
class AppConstants {
  AppConstants._();

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 350);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Pagination
  static const int messagesPerPage = 30;
  static const int conversationsPerPage = 20;
  static const int usersPerPage = 20;
  static const int storiesPerPage = 50;
  
  // Cache
  static const Duration cacheExpiry = Duration(hours: 1);
  static const Duration profileCacheExpiry = Duration(hours: 6);
  static const Duration settingsCacheExpiry = Duration(hours: 24);
  
  // Validation
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 20;
  static const int minPasswordLength = 8;
  static const int maxDisplayNameLength = 50;
  static const int maxBioLength = 200;
  static const int maxGroupNameLength = 100;
  static const int maxMessageLength = 5000;
  
  // File Limits
  static const int maxImageSizeBytes = 10 * 1024 * 1024; // 10MB
  static const int maxVideoSizeBytes = 50 * 1024 * 1024; // 50MB
  static const int maxFileSizeBytes = 50 * 1024 * 1024; // 50MB
  static const int maxVoiceMessageSeconds = 300; // 5 minutes
  
  // Debounce
  static const Duration searchDebounce = Duration(milliseconds: 500);
  static const Duration typingDebounce = Duration(milliseconds: 2000);
  
  // Regex
  static final RegExp usernameRegex = RegExp(r'^[a-zA-Z0-9_]{3,20}$');
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  
  // Story
  static const Duration storyExpiration = Duration(hours: 24);
  static const Duration storyDuration = Duration(seconds: 5);
  
  // Reactions
  static const List<String> defaultReactions = [
    '👍', '❤️', '😂', '😮', '😢', '👏', '🔥',
  ];
  
  // Report Reasons
  static const List<String> reportReasons = [
    'spam',
    'harassment',
    'inappropriate_content',
    'impersonation',
    'other',
  ];
  
  // Privacy Options
  static const List<String> privacyOptions = [
    'everyone',
    'contacts',
    'nobody',
  ];
}
