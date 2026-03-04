import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Builds the light theme for the application.
///
/// Note: This function is cached at the provider level (see theme_provider.dart),
/// so it's only called once when the light theme provider is first accessed.
/// GoogleFonts.manropeTextTheme() will not be called on every rebuild.
ThemeData buildAppTheme() {
  const primary = AppColors.primary;
  final colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: Colors.black,
    secondary: const Color(0xFF111827),
    onSecondary: Colors.white,
    error: const Color(0xFFB00020),
    onError: Colors.white,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
  );

  // Base Manrope text theme with clear weight hierarchy
  // switched to standard text theme to avoid network errors
  final baseTextTheme = ThemeData.light().textTheme.apply(
    fontFamily: 'Manrope',
    bodyColor: AppColors.textPrimary,
    displayColor: AppColors.textPrimary,
  );

  final textTheme = baseTextTheme.copyWith(
    displayLarge: baseTextTheme.displayLarge?.copyWith(
      fontWeight: FontWeight.w800,
    ),
    displayMedium: baseTextTheme.displayMedium?.copyWith(
      fontWeight: FontWeight.w800,
    ),
    displaySmall: baseTextTheme.displaySmall?.copyWith(
      fontWeight: FontWeight.w700,
    ),
    headlineLarge: baseTextTheme.headlineLarge?.copyWith(
      fontWeight: FontWeight.w700,
    ),
    headlineMedium: baseTextTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.w700,
    ),
    headlineSmall: baseTextTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.w700,
    ),
    titleLarge: baseTextTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    titleMedium: baseTextTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
    ),
    titleSmall: baseTextTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
    bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
    bodyMedium: baseTextTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondary,
    ),
    bodySmall: baseTextTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondary,
    ),
    labelLarge: baseTextTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    labelMedium: baseTextTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w600,
    ),
    labelSmall: baseTextTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.background,
    textTheme: textTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      elevation: 0,
      foregroundColor: AppColors.textPrimary,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.thumbBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.outlineSoft),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.outlineSoft),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        minimumSize: const Size(0, 48), // Minimum height for mobile
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        minimumSize: const Size(0, 48), // Minimum height for mobile
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.outlineSoft),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        minimumSize: const Size(0, 48), // Minimum height for mobile
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        foregroundColor: AppColors.textPrimary,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 48), // Minimum height for mobile
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(40, 40), // Minimum touch target for mobile
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.thumbBg,
      selectedColor: AppColors.primary,
      secondarySelectedColor: AppColors.primary,
      checkmarkColor: AppColors.textPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      labelStyle: baseTextTheme.bodyMedium?.copyWith(
        color: AppColors.textPrimary,
        fontSize: 12,
      ),
      secondaryLabelStyle: baseTextTheme.bodyMedium?.copyWith(
        color: AppColors.textPrimary,
        fontSize: 12,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 2, // Subtle elevation for depth
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.outlineSoft.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      shadowColor: AppColors.shadowSoft,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.outlineSoft,
      thickness: 1,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primary.withValues(alpha: 0.2),
      surfaceTintColor: Colors.transparent,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        return IconThemeData(
          color:
              states.contains(WidgetState.selected)
                  ? Colors.black
                  : AppColors.textSecondary,
        );
      }),
      labelTextStyle: WidgetStateProperty.all(baseTextTheme.labelMedium),
      height: 64,
    ),
  );
}

/// Builds the dark theme for the application.
///
/// Note: This function is cached at the provider level (see theme_provider.dart),
/// so it's only called once when the dark theme provider is first accessed.
/// GoogleFonts.manropeTextTheme() will not be called on every rebuild.
ThemeData buildAppDarkTheme() {
  const primary = AppColors.primary;
  // Dark theme colors
  const darkBackground = Color(0xFF121212);
  const darkSurface = Color(0xFF1E1E1E);
  const darkTextPrimary = Color(0xFFE0E0E0);
  const darkTextSecondary = Color(0xFF9E9E9E);
  const darkOutlineSoft = Color(0xFF424242);
  const darkThumbBg = Color(0xFF2C2C2C);
  const darkShadowSoft = Color(0x40000000);

  final colorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: primary,
    onPrimary: Colors.black,
    secondary: const Color(0xFFBB86FC),
    onSecondary: Colors.white,
    error: const Color(0xFFCF6679),
    onError: Colors.white,
    surface: darkSurface,
    onSurface: darkTextPrimary,
  );

  // Base Manrope text theme with clear weight hierarchy
  // switched to standard text theme to avoid network errors
  final baseTextTheme = ThemeData.dark().textTheme.apply(
    fontFamily: 'Manrope',
    bodyColor: darkTextPrimary,
    displayColor: darkTextPrimary,
  );

  final textTheme = baseTextTheme.copyWith(
    displayLarge: baseTextTheme.displayLarge?.copyWith(
      fontWeight: FontWeight.w800,
    ),
    displayMedium: baseTextTheme.displayMedium?.copyWith(
      fontWeight: FontWeight.w800,
    ),
    displaySmall: baseTextTheme.displaySmall?.copyWith(
      fontWeight: FontWeight.w700,
    ),
    headlineLarge: baseTextTheme.headlineLarge?.copyWith(
      fontWeight: FontWeight.w700,
    ),
    headlineMedium: baseTextTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.w700,
    ),
    headlineSmall: baseTextTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.w700,
    ),
    titleLarge: baseTextTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    titleMedium: baseTextTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
    ),
    titleSmall: baseTextTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
    bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
    bodyMedium: baseTextTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w400,
      color: darkTextSecondary,
    ),
    bodySmall: baseTextTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w400,
      color: darkTextSecondary,
    ),
    labelLarge: baseTextTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    labelMedium: baseTextTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w600,
    ),
    labelSmall: baseTextTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: darkBackground,
    textTheme: textTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: darkSurface,
      elevation: 0,
      foregroundColor: darkTextPrimary,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkThumbBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: darkOutlineSoft),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: darkOutlineSoft),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        minimumSize: const Size(0, 48), // Minimum height for mobile
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        minimumSize: const Size(0, 48), // Minimum height for mobile
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: darkOutlineSoft),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        minimumSize: const Size(0, 48), // Minimum height for mobile
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        foregroundColor: darkTextPrimary,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 48), // Minimum height for mobile
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(40, 40), // Minimum touch target for mobile
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: darkThumbBg,
      selectedColor: AppColors.primary,
      secondarySelectedColor: AppColors.primary,
      checkmarkColor: darkTextPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      labelStyle: baseTextTheme.bodyMedium?.copyWith(
        color: darkTextPrimary,
        fontSize: 12,
      ),
      secondaryLabelStyle: baseTextTheme.bodyMedium?.copyWith(
        color: darkTextPrimary,
        fontSize: 12,
      ),
    ),
    cardTheme: CardThemeData(
      color: darkSurface,
      elevation: 2, // Subtle elevation for depth
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: darkOutlineSoft.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      shadowColor: darkShadowSoft,
    ),
    dividerTheme: const DividerThemeData(color: darkOutlineSoft, thickness: 1),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: darkSurface,
      indicatorColor: AppColors.primary.withValues(alpha: 0.2),
      surfaceTintColor: Colors.transparent,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        return IconThemeData(
          color:
              states.contains(WidgetState.selected)
                  ? Colors.black
                  : darkTextSecondary,
        );
      }),
      labelTextStyle: WidgetStateProperty.all(baseTextTheme.labelMedium),
      height: 64,
    ),
  );
}
