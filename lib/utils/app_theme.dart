import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_constants.dart';

class AppTheme {
  static const brandBlue = Color(0xFF1F6FBA);
  static const brandNavy = Color(0xFF0F3F74);
  static const brandMint = Color(0xFF3DD8C3);
  static const brandCoral = Color(0xFFFF7A59);

  static const brandGradient = LinearGradient(
    colors: [brandBlue, brandMint],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const authBackgroundGradient = LinearGradient(
    colors: [Color(0xFFF0F7FF), Color(0xFFF9FCFF), Color(0xFFEAF8F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get lightTheme => _buildTheme(Brightness.light);

  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final baseTextTheme = GoogleFonts.nunitoTextTheme();
    final background = isDark ? const Color(0xFF08141F) : AppColors.background;
    final surface = isDark ? const Color(0xFF112131) : AppColors.surface;
    final textPrimary =
        isDark ? const Color(0xFFE7F0FA) : AppColors.textPrimary;
    final textSecondary =
        isDark ? const Color(0xFFA5BED6) : AppColors.textSecondary;
    final divider = isDark ? const Color(0xFF183245) : AppColors.divider;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      textTheme: baseTextTheme.apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: brandBlue,
        onPrimary: Colors.white,
        secondary: brandMint,
        onSecondary: brandNavy,
        error: AppColors.danger,
        onError: Colors.white,
        surface: surface,
        onSurface: textPrimary,
        primaryContainer:
            isDark ? const Color(0xFF16436A) : const Color(0xFFDCEFFF),
        onPrimaryContainer: textPrimary,
        secondaryContainer:
            isDark ? const Color(0xFF163C3A) : const Color(0xFFD9FCF7),
        onSecondaryContainer: textPrimary,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        ),
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, AppDimensions.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brandBlue,
          textStyle: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF0D1B29) : AppColors.background,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingM,
          vertical: AppDimensions.paddingM,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          borderSide: BorderSide(color: divider, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          borderSide: BorderSide(color: divider, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          borderSide: const BorderSide(color: brandBlue, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        hintStyle: GoogleFonts.nunito(
          fontSize: 14,
          color: textSecondary,
        ),
        labelStyle: GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textSecondary,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? const Color(0xFF14304A) : AppColors.primaryLight,
        selectedColor: brandBlue,
        labelStyle: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? const Color(0xFF112131) : AppColors.textPrimary,
        contentTextStyle: GoogleFonts.nunito(
          fontSize: 14,
          color: Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        ),
      ),
    );
  }
}
