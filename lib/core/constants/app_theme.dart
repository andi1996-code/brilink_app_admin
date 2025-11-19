import 'package:flutter/material.dart';
import 'app_color.dart';
import 'app_style.dart';

class AppTheme {
  // 🌞 Light Theme
  static ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColor.primary,
    scaffoldBackgroundColor: AppColor.background,
    cardColor: AppColor.surface,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColor.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    colorScheme: const ColorScheme.light(
      primary: AppColor.primary,
      secondary: AppColor.secondary,
      background: AppColor.background,
      surface: AppColor.surface,
      error: AppColor.error,
    ),
    textTheme: const TextTheme(
      bodyLarge: AppStyle.bodyText,
      bodyMedium: AppStyle.caption,
      titleLarge: AppStyle.heading1,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: AppStyle.elevatedButtonStyle,
    ),
  );

  // 🌚 Dark Theme
  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColor.primary,
    scaffoldBackgroundColor: AppColor.darkBackground,
    cardColor: AppColor.darkSurface,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColor.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    colorScheme: const ColorScheme.dark(
      primary: AppColor.primary,
      secondary: AppColor.secondary,
      background: AppColor.darkBackground,
      surface: AppColor.darkSurface,
      error: AppColor.error,
    ),
    textTheme: const TextTheme(
      bodyLarge: AppStyle.bodyText,
      bodyMedium: AppStyle.caption,
      titleLarge: AppStyle.heading1,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: AppStyle.elevatedButtonStyle,
    ),
  );
}
