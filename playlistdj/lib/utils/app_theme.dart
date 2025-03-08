import 'package:flutter/material.dart';

// Colors from the web app
class AppColors {
  static const Color spotifyGreen = Color(0xFF1DB954);
  static const Color spotifyBlack = Color(0xFF191414);
  static const Color spotifyWhite = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFF0F0F0);
  static const Color darkGray = Color(0xFF333333);
  static const Color mediumGray = Color(0xFF666666);
  
  // Additional colors for the app
  static const Color background = spotifyBlack;
  static const Color cardBackground = Color(0xFF282828);
  static const Color errorRed = Color(0xFFE61E32);
}

// App theme
class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      primaryColor: AppColors.spotifyGreen,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.spotifyGreen,
        secondary: AppColors.spotifyGreen,
        background: AppColors.background,
        surface: AppColors.cardBackground,
        error: AppColors.errorRed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.spotifyWhite,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: const CardTheme(
        color: AppColors.cardBackground,
        elevation: 4,
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: AppColors.spotifyGreen,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.spotifyGreen,
          foregroundColor: AppColors.spotifyWhite,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.spotifyWhite,
          side: const BorderSide(color: AppColors.spotifyGreen),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.spotifyGreen,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.spotifyGreen,
        inactiveTrackColor: AppColors.mediumGray,
        thumbColor: AppColors.spotifyGreen,
        trackHeight: 4.0,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkGray,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          color: AppColors.spotifyWhite,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: TextStyle(
          color: AppColors.spotifyWhite,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          color: AppColors.spotifyWhite,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: AppColors.spotifyWhite,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: AppColors.lightGray,
          fontSize: 14,
        ),
        bodySmall: TextStyle(
          color: AppColors.mediumGray,
          fontSize: 12,
        ),
      ),
    );
  }
}