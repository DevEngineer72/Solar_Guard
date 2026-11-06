import 'package:flutter/material.dart';

import 'app_tokens.dart';

ThemeData buildAppTheme() => ThemeData(
  useMaterial3: true,
  fontFamily: 'Manrope',
  scaffoldBackgroundColor: AppColors.background,
  colorScheme: const ColorScheme.light(
    primary: AppColors.navy,
    onPrimary: Colors.white,
    secondary: AppColors.blue,
    surface: Colors.white,
    onSurface: AppColors.ink,
    error: AppColors.red,
  ),
  dividerColor: AppColors.border,
  navigationBarTheme: const NavigationBarThemeData(
    backgroundColor: Colors.white,
    indicatorColor: AppColors.softBlue,
    elevation: 0,
    height: 76,
  ),
  navigationRailTheme: const NavigationRailThemeData(
    backgroundColor: Colors.white,
    indicatorColor: AppColors.softBlue,
    useIndicator: true,
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(48, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(48, 48),
      side: const BorderSide(color: AppColors.outline),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  chipTheme: ChipThemeData(
    side: const BorderSide(color: AppColors.border),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
  ),
);
