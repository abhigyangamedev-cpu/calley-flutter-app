import 'package:material_ui/material_ui.dart';

/// Colours sampled from the "Get Calley App Design" Figma file.
class AppColors {
  static const primary = Color(0xFF2563EB);
  static const navy = Color(0xFF1E2F5C);
  static const background = Color(0xFFF5F7FB);
  static const border = Color(0xFFE2E8F0);
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const lightBlue = Color(0xFFEEF4FF);
  static const whatsapp = Color(0xFF25D366);
  static const error = Color(0xFFDC2626);

  static const pending = Color(0xFFF59E0B);
  static const pendingBg = Color(0xFFFFF4E0);
  static const done = Color(0xFF22C55E);
  static const doneBg = Color(0xFFE7F8EE);
  static const scheduled = Color(0xFF8B5CF6);
  static const scheduledBg = Color(0xFFF1EBFF);
}

ThemeData buildTheme() {
  OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: color, width: width),
      );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: AppColors.background,
  );

  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 0,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
      suffixIconColor: AppColors.textSecondary,
      border: border(AppColors.border),
      enabledBorder: border(AppColors.border),
      focusedBorder: border(AppColors.primary, 1.5),
      errorBorder: border(AppColors.error),
      focusedErrorBorder: border(AppColors.error, 1.5),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
