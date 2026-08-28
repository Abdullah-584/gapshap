import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// BuildContext extensions
extension ContextExtensions on BuildContext {
  // Theme
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;
  bool get isDarkMode => theme.brightness == Brightness.dark;

  // MediaQuery
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => mediaQuery.size;
  double get screenHeight => screenSize.height;
  double get screenWidth => screenSize.width;
  EdgeInsets get padding => mediaQuery.padding;
  double get topPadding => padding.top;
  double get bottomPadding => padding.bottom;
  bool get isKeyboardOpen => mediaQuery.viewInsets.bottom > 0;

  // Navigation
  NavigatorState get navigator => Navigator.of(this);
  
  // Snackbars
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void showErrorSnackBar(String message) => showSnackBar(message, isError: true);
  void showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 20),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: AppColors.surfaceDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // Focus
  void unfocus() => FocusScope.of(this).unfocus();
}
