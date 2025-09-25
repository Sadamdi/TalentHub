import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF007BFF);
  static const Color secondary = Color(0xFF8A38F5);
  static const Color background = Color(0xFFF5F0F5);

  // Text Colors
  static const Color textPrimary = Color(0xFF06010D);
  static const Color textSecondary = Color(0xFF4C4C4C);
  static const Color textLight = Color(0xFF6B6B6B);
  static const Color textMuted = Color(0xFF7E7E7E);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF003D80);

  // Neutral Colors
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color grey = Color(0xFFA4A4A4);
  static const Color border = Color(0xFFE0E0E0);

  // Shadow Colors
  static const Color shadowLight = Color(0x19000000);
  static const Color shadowMedium = Color(0x3F000000);
  static const Color shadowDark = Color(0x4C000000);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkCard = Color(0xFF1E1E1E);
  static const Color darkSurface = Color(0xFF2C2C2C);
  static const Color darkBorder = Color(0xFF3C3C3C);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB3B3B3);
  static const Color darkTextLight = Color(0xFF8C8C8C);
  static const Color darkShadowLight = Color(0x33FFFFFF);
  static const Color darkShadowMedium = Color(0x66FFFFFF);
  static const Color darkShadowDark = Color(0x99FFFFFF);

  // Job Category Colors
  static const Color designerColor = Color(0xFF8A38F5);
  static const Color writerColor = Color(0xFF007BFF);
  static const Color financeColor = Color(0xFF4CAF50);
  static const Color developerColor = Color(0xFFFF9800);

  // Context-aware colors (will be used with theme provider)
  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBackground
        : background;
  }

  static Color getCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkCard : white;
  }

  static Color getTextPrimaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextPrimary
        : textPrimary;
  }

  static Color getTextSecondaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextSecondary
        : textSecondary;
  }

  static Color getBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBorder
        : border;
  }

  static Color getShadowColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkShadowLight
        : shadowLight;
  }
}
