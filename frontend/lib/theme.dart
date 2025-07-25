import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppColors {
  static const Color main = Color.fromARGB(255, 9, 97, 191);

  static const Color primary = Color.fromARGB(255, 45, 46, 55);
  static const Color secondary = Color.fromRGBO(60, 61, 70, 0.545);

  static const Color ad = Color.fromARGB(255, 173, 173, 173);
  static const Color e3 = Color.fromARGB(255, 227, 227, 227);

  static const Color success = Color.fromARGB(255, 61, 131, 97);
  static const Color error = Color.fromARGB(255, 198, 32, 32);

  static const Color white = Color.fromARGB(255, 255, 255, 255);
  static const Color black = Color.fromARGB(255, 0, 0, 0);
}

final TextTheme appTextTheme = TextTheme(
  titleMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
  headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
  bodyMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),

  labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
  labelMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
);

final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  fontFamily: 'IranYekanX',
  iconTheme: const IconThemeData(size: 24),
  textTheme: appTextTheme,
  scaffoldBackgroundColor: AppColors.white,
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.white,
    foregroundColor: AppColors.primary,
    elevation: 0,
  ),
  colorScheme: const ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.white,
    secondary: AppColors.secondary,
    onSecondary: AppColors.white,
    error: AppColors.error,
    onError: AppColors.white,
    surface: AppColors.white,
    onSurface: AppColors.primary,
  ),
);

final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  fontFamily: 'IranYekanX',
  iconTheme: const IconThemeData(size: 24),
  textTheme: appTextTheme,
  scaffoldBackgroundColor: AppColors.primary,
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.white,
    elevation: 0,
  ),
  colorScheme: const ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.white,
    onPrimary: AppColors.primary,
    secondary: AppColors.secondary,
    onSecondary: AppColors.white,
    error: AppColors.error,
    onError: AppColors.white,
    surface: AppColors.secondary,
    onSurface: AppColors.white,
  ),
);

final themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);

Future<void> initThemeMode() async {
  final prefs = await SharedPreferences.getInstance();
  final savedTheme = prefs.getString('themeMode') ?? 'system';

  switch (savedTheme) {
    case 'light':
      themeModeNotifier.value = ThemeMode.light;
      break;
    case 'dark':
      themeModeNotifier.value = ThemeMode.dark;
      break;
    default:
      themeModeNotifier.value = ThemeMode.system;
  }
}

Future<void> saveThemeMode(ThemeMode mode) async {
  final prefs = await SharedPreferences.getInstance();
  switch (mode) {
    case ThemeMode.light:
      await prefs.setString('themeMode', 'light');
      break;
    case ThemeMode.dark:
      await prefs.setString('themeMode', 'dark');
      break;
    case ThemeMode.system:
      await prefs.setString('themeMode', 'system');
      break;
  }
  themeModeNotifier.value = mode;
}
