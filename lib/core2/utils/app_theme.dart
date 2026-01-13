import 'package:flutter/material.dart';
import 'package:techno_store/core2/utils/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        drawerTheme: const DrawerThemeData(
          backgroundColor: AppColors.primary,
        ),
        fontFamily: 'Cairo',
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.primary,
          // shadowColor: AppColors.primary,
          elevation: 0,
        ),
        scaffoldBackgroundColor: AppColors.secondary,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            fontStyle: FontStyle.italic,
          ),
          titleLarge: TextStyle(
            // title in body
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
          titleMedium: TextStyle(
            // body large text
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: AppColors.primary,
          ),
          bodyLarge: TextStyle(
            // body medium text
            fontSize: 18,
            color: AppColors.primary,
          ),
          labelLarge: TextStyle(
            // body small text
            fontSize: 16,
            color: AppColors.primary,
          ),
          labelMedium: TextStyle(
            fontSize: 14,
            color: AppColors.primary,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          suffixIconColor: AppColors.primary,
          labelStyle: const TextStyle(
            color: AppColors.grey,
            fontSize: 16,
          ),
          hintStyle: const TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18.0,
            vertical: 14.0,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: AppColors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: AppColors.grey4),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: AppColors.red.withAlpha(150)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: AppColors.red),
          ),
          filled: true,
          fillColor: AppColors.white,
        ),
        // app bar theme
      );

  static ThemeData get darkTheme => ThemeData.dark(useMaterial3: true).copyWith(
        brightness: Brightness.dark,
        // fontFamily: 'Cairo',
        scaffoldBackgroundColor: AppColors.primary,
        drawerTheme: const DrawerThemeData(
          backgroundColor: AppColors.primary,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.secondary,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        colorScheme: ThemeData.dark(useMaterial3: true).colorScheme.copyWith(
              primary: AppColors.primary,
              secondary: AppColors.secondary,
              surface: AppColors.primary,
              onPrimary: AppColors.secondary,
              onSecondary: AppColors.primary,
              error: AppColors.red2,
              brightness: Brightness.dark,
            ),
        textTheme: ThemeData.dark(useMaterial3: true).textTheme.copyWith(
              displayLarge: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
                fontStyle: FontStyle.italic,
              ),
              titleLarge: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.secondary,
              ),
              titleMedium: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: AppColors.secondary,
              ),
              bodyLarge: TextStyle(
                fontSize: 18,
                color: AppColors.grey2,
              ),
              labelLarge: TextStyle(
                fontSize: 16,
                color: AppColors.grey4,
              ),
              labelMedium: TextStyle(
                fontSize: 14,
                color: AppColors.grey4,
              ),
            ),
        inputDecorationTheme: InputDecorationTheme(
          suffixIconColor: AppColors.secondary,
          labelStyle: TextStyle(
            color: AppColors.grey4,
            fontSize: 16,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18.0,
            vertical: 14.0,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: AppColors.grey4),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: AppColors.secondary),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: AppColors.grey4.withOpacity(0.5)),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: AppColors.red.withAlpha(150)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: AppColors.red2),
          ),
          filled: true,
          fillColor: AppColors.secondary2,
        ),
      );
}
