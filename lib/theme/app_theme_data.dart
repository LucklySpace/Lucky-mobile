import 'package:flutter/material.dart';

import 'app_theme.dart';

/// 统一主题配置类
/// 提供亮色和暗色主题的配置
class AppThemeData {
  /// 亮色主题
  static final lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: const Color(0xFF409EFF),
    scaffoldBackgroundColor: AppTheme.bg_page,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppTheme.bg_page,
      foregroundColor: AppTheme.block,
      elevation: 0,
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF409EFF),
      brightness: Brightness.light,
    ).copyWith(
      primary: const Color(0xFF409EFF),
      onPrimary: Colors.white,
      secondary: const Color(0xFF998AED),
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: AppTheme.block,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppTheme.block,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppTheme.block,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: AppTheme.block,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: AppTheme.block,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: AppTheme.block,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: AppTheme.text_white_gray_deep,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFf5f7fa),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(
          color: Color(0xFF409EFF),
          width: 1.5,
        ),
      ),
      labelStyle: const TextStyle(
        color: Color(0xFF999999),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF409EFF),
        foregroundColor: Colors.white,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        elevation: 0,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF409EFF),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );

  /// 暗色主题
  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF409EFF),
    scaffoldBackgroundColor: AppTheme.bg_page_gray,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppTheme.bg_page_gray,
      foregroundColor: AppTheme.text_block_white,
      elevation: 0,
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF409EFF),
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFF409EFF),
      onPrimary: Colors.white,
      secondary: const Color(0xFF998AED),
      onSecondary: Colors.white,
      surface: AppTheme.bg_page_gray,
      onSurface: AppTheme.text_block_white,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppTheme.text_block_white,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppTheme.text_block_white,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: AppTheme.text_block_white,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: AppTheme.text_block_white,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: AppTheme.text_block_white,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: AppTheme.text_block_gray_deep,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppTheme.bg_tran_block,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(
          color: Color(0xFF409EFF),
          width: 1.5,
        ),
      ),
      labelStyle: const TextStyle(
        color: AppTheme.text_block_gray_light,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF409EFF),
        foregroundColor: Colors.white,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        elevation: 0,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF409EFF),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );
}
