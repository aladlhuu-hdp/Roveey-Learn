import 'package:flutter/material.dart';

/// Centralized color palette following Google Stitch / Coastal Editorial guidelines.
/// Values are preserved strictly identical to the original implementation.
abstract final class AppColors {
  // Primary brand palette
  static const Color forest = Color(0xFF145B56);
  static const Color forestDeep = Color(0xFF203A38);
  static const Color leaf = Color(0xFF266863);
  static const Color accentMint = Color(0xFF06D6A0);
  static const Color sea = Color(0xFF496361);
  static const Color sand = Color(0xFFF5F5F7);
  static const Color paper = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF1D1D1F);
  static const Color muted = Color(0xFF6E6E73);
  static const Color line = Color(0xFFE5E5EA);

  // Soft Coastal & Surface tints
  static const Color softLime = Color(0xFFD5E66D);
  static const Color seaMist = Color(0xFFE7F0EC);
  static const Color surfaceGreen = Color(0xFFE4F0DA);
  static const Color surfaceGreenLight = Color(0xFFE8F1EC);
  static const Color surfaceGreenTint = Color(0xFFE5F0DB);
  static const Color surfaceCardGreen = Color(0xFFEAF1E3);
  static const Color surfaceInfoGreen = Color(0xFFE9EEE2);
  static const Color surfaceNeutralCard = Color(0xFFF0F1EC);
  static const Color surfaceCardMuted = Color(0xFFF0F0E6);
  static const Color surfaceCardAlt = Color(0xFFE8F0DF);

  // Accents, borders, badges
  static const Color borderGreen = Color(0xFFBBD6B1);
  static const Color borderGreenMuted = Color(0xFFBFD5A9);
  static const Color borderGreenSoft = Color(0xFFC5DDAE);
  static const Color badgeGreen = Color(0xFFC6DDB9);
  static const Color goldXp = Color(0xFFB48A23);
  static const Color cardOutline = Color(0xFFD8E4D6);
  static const Color neutralBorder = Color(0xFFDCE4DF);

  // Status, error, feedback
  static const Color error = Color(0xFFB85C4A);
  static const Color errorDark = Color(0xFF9C5143);
  static const Color errorBg = Color(0xFFFFF0E8);
  static const Color errorBgSoft = Color(0xFFFFF0EC);
  static const Color errorBgLight = Color(0xFFFFEFE7);
  static const Color errorBorder = Color(0xFFD98A65);
  static const Color errorBorderAlt = Color(0xFFCB7869);
  static const Color warningBrown = Color(0xFF9B5B37);

  // Instrument / Refractometer
  static const Color refractometerBorder = Color(0xFFB8D0C8);
  static const Color refractometerInnerBorder = Color(0xFF9ABAB2);
}
