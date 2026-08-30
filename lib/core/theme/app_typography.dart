import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// GAPSHAP Typography System
class AppTypography {
  AppTypography._();

  // ─── Dark Theme Text Styles ───
  static final TextStyle _darkHeading = GoogleFonts.poppins(
    color: AppColors.textPrimaryDark,
    fontWeight: FontWeight.w700,
  );

  static final TextStyle _darkBody = GoogleFonts.poppins(
    color: AppColors.textPrimaryDark,
    fontWeight: FontWeight.w400,
  );

  static final TextStyle _darkSecondary = GoogleFonts.poppins(
    color: AppColors.textSecondaryDark,
    fontWeight: FontWeight.w400,
  );

  // ─── Light Theme Text Styles ───
  static final TextStyle _lightHeading = GoogleFonts.poppins(
    color: AppColors.textPrimaryLight,
    fontWeight: FontWeight.w700,
  );

  static final TextStyle _lightBody = GoogleFonts.poppins(
    color: AppColors.textPrimaryLight,
    fontWeight: FontWeight.w400,
  );

  static final TextStyle _lightSecondary = GoogleFonts.poppins(
    color: AppColors.textSecondaryLight,
    fontWeight: FontWeight.w400,
  );

  // ─── Dark Theme ───
  static final TextStyle darkDisplayLarge = _darkHeading.copyWith(fontSize: 32, fontWeight: FontWeight.w800);
  static final TextStyle darkDisplayMedium = _darkHeading.copyWith(fontSize: 28, fontWeight: FontWeight.w700);
  static final TextStyle darkHeadlineLarge = _darkHeading.copyWith(fontSize: 24);
  static final TextStyle darkHeadlineMedium = _darkHeading.copyWith(fontSize: 20);
  static final TextStyle darkTitleLarge = _darkHeading.copyWith(fontSize: 18, fontWeight: FontWeight.w600);
  static final TextStyle darkTitleMedium = _darkHeading.copyWith(fontSize: 16, fontWeight: FontWeight.w600);
  static final TextStyle darkBodyLarge = _darkBody.copyWith(fontSize: 16);
  static final TextStyle darkBodyMedium = _darkBody.copyWith(fontSize: 14);
  static final TextStyle darkBodySmall = _darkBody.copyWith(fontSize: 12);
  static final TextStyle darkLabelLarge = _darkBody.copyWith(fontSize: 14, fontWeight: FontWeight.w600);
  static final TextStyle darkLabelMedium = _darkBody.copyWith(fontSize: 12, fontWeight: FontWeight.w600);
  static final TextStyle darkLabelSmall = _darkBody.copyWith(fontSize: 10, fontWeight: FontWeight.w600);
  static final TextStyle darkCaption = _darkSecondary.copyWith(fontSize: 12);
  static final TextStyle darkOverline = _darkSecondary.copyWith(fontSize: 10, letterSpacing: 1.2);

  // ─── Light Theme ───
  static final TextStyle lightDisplayLarge = _lightHeading.copyWith(fontSize: 32, fontWeight: FontWeight.w800);
  static final TextStyle lightDisplayMedium = _lightHeading.copyWith(fontSize: 28, fontWeight: FontWeight.w700);
  static final TextStyle lightHeadlineLarge = _lightHeading.copyWith(fontSize: 24);
  static final TextStyle lightHeadlineMedium = _lightHeading.copyWith(fontSize: 20);
  static final TextStyle lightTitleLarge = _lightHeading.copyWith(fontSize: 18, fontWeight: FontWeight.w600);
  static final TextStyle lightTitleMedium = _lightHeading.copyWith(fontSize: 16, fontWeight: FontWeight.w600);
  static final TextStyle lightBodyLarge = _lightBody.copyWith(fontSize: 16);
  static final TextStyle lightBodyMedium = _lightBody.copyWith(fontSize: 14);
  static final TextStyle lightBodySmall = _lightBody.copyWith(fontSize: 12);
  static final TextStyle lightLabelLarge = _lightBody.copyWith(fontSize: 14, fontWeight: FontWeight.w600);
  static final TextStyle lightLabelMedium = _lightBody.copyWith(fontSize: 12, fontWeight: FontWeight.w600);
  static final TextStyle lightLabelSmall = _lightBody.copyWith(fontSize: 10, fontWeight: FontWeight.w600);
  static final TextStyle lightCaption = _lightSecondary.copyWith(fontSize: 12);
  static final TextStyle lightOverline = _lightSecondary.copyWith(fontSize: 10, letterSpacing: 1.2);
}
