import 'package:flutter/material.dart';

class AuthTheme {
  // Brand Colors
  static const Color primary = Color(0xFF5D85DC);
  static const Color primaryDisabled = Color(0xFFC2D0F5);
  static const Color background = Colors.white;
  static const Color textDark = Color(0xFF1A1D1F);
  static const Color textGrey = Color(0xFF9A9FA5);
  static const Color borderGrey = Color(0xFFEFEFEF);
  static const Color borderActive = Color(0xFF5D85DC);
  static const Color errorRed = Color(0xFFFF6A55);
  static const Color greyBg = Color(0xFFF4F4F4);

  // Fonts
  static const String fontFamily = 'Poppins';

  // Text Styles
  static const TextStyle headerStyle = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w600, // SemiBold
    fontSize: 24.0,
    color: textDark,
    height: 1.3,
  );

  static const TextStyle titleStyle = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w600, // SemiBold
    fontSize: 32.0,
    color: textDark,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w500, // Medium
    fontSize: 14.0,
    color: textGrey,
    height: 1.5,
  );

  static const TextStyle inputLabelStyle = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w600, // SemiBold
    fontSize: 14.0,
    color: textDark,
  );

  static const TextStyle inputTextStyle = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w500, // Medium
    fontSize: 15.0,
    color: textDark,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w600, // SemiBold
    fontSize: 15.0,
    color: Colors.white,
  );

  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      fontFamily: fontFamily,
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: primary,
        selectionColor: primaryDisabled,
        selectionHandleColor: primary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        hintStyle: TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w500, // Medium
          fontSize: 15.0,
          color: textGrey.withAlpha(204),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: borderGrey, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: borderActive, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: errorRed, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: errorRed, width: 2.0),
        ),
        errorStyle: const TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w500, // Medium
          fontSize: 12.0,
          color: errorRed,
        ),
      ),
    );
  }
}
