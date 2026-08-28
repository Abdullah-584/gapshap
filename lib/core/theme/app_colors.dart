import 'package:flutter/material.dart';

/// GAPSHAP Color Palette
/// Dark premium theme inspired by the reference UI
class AppColors {
  AppColors._();

  // ─── Primary Palette ───
  static const Color primary = Color(0xFFF5E6C8);       // Warm cream/gold
  static const Color primaryDark = Color(0xFFD4C4A0);    // Deeper cream
  static const Color primaryLight = Color(0xFFFDF5E6);   // Light cream
  
  // ─── Background ───
  static const Color backgroundDark = Color(0xFF0D0D0D);  // Near black
  static const Color backgroundLight = Color(0xFFFFFFFF);  // White
  static const Color surfaceDark = Color(0xFF1A1A1A);     // Dark surface
  static const Color surfaceLight = Color(0xFFF5F0E8);    // Warm cream surface
  
  // ─── Chat Bubbles ───
  static const Color outgoingBubbleLight = Color(0xFFF5E6C8); // Cream outgoing
  static const Color outgoingBubbleDark = Color(0xFF2A2A2A);  // Dark outgoing
  static const Color incomingBubbleLight = Color(0xFFEEEEEE); // Light gray incoming
  static const Color incomingBubbleDark = Color(0xFF1E1E1E);  // Dark incoming
  
  // ─── Text ───
  static const Color textPrimaryLight = Color(0xFF1A1A1A);
  static const Color textSecondaryLight = Color(0xFF888888);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFF999999);
  static const Color textOnPrimary = Color(0xFF1A1A1A);
  
  // ─── Accent ───
  static const Color online = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFA726);
  static const Color success = Color(0xFF66BB6A);
  static const Color info = Color(0xFF42A5F5);
  
  // ─── Story Ring ───
  static const Color storyRingUnread = Color(0xFFF5E6C8);
  static const Color storyRingViewed = Color(0xFF555555);
  
  // ─── Misc ───
  static const Color divider = Color(0xFF2A2A2A);
  static const Color dividerLight = Color(0xFFE0E0E0);
  static const Color shimmer = Color(0xFF2A2A2A);
  static const Color shimmerLight = Color(0xFFE0E0E0);
  static const Color overlay = Color(0x80000000);
  static const Color typing = Color(0xFFF5E6C8);
}
