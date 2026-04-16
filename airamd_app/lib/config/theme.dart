import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// airaMD Design System — Warm beige/brown luxury theme
class AiraColors {
  AiraColors._();

  // Primary palette (wood tones)
  static const Color woodDk = Color(0xFF6B4F3A);
  static const Color woodMid = Color(0xFF8B6650);
  static const Color woodLt = Color(0xFFB8957A);
  static const Color woodPale = Color(0xFFD4B89A);
  static const Color woodWash = Color(0xFFEDD9C4);

  // Backgrounds
  static const Color cream = Color(0xFFF7F0E8);
  static const Color creamDk = Color(0xFFEDE4D8);
  static const Color parchment = Color(0xFFFAF5EE);
  static const Color white = Color(0xFFFFFCF8);

  // Text
  static const Color charcoal = Color(0xFF2D1F14);
  static const Color muted = Color(0xFF9A7D6A);

  // Accent
  static const Color sage = Color(0xFF7A9070);
  static const Color terra = Color(0xFFB86848);
  static const Color gold = Color(0xFFC4922A);

  // Safety / Clinical
  static const Color danger = Color(0xFFD32F2F);  // True RED — allergy warnings

  // Functional
  static const Color error = danger;
  static const Color success = sage;
  static const Color warning = gold;
  static const Color info = woodMid;

  // Gradient (primary button)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [woodMid, woodDk],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient progressGradient = LinearGradient(
    colors: [woodLt, woodMid],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Premium gradients
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF5A3F2C), Color(0xFF7A5840), Color(0xFFA8806A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldenGradient = LinearGradient(
    colors: [Color(0xFFD6B585), Color(0xFFC4922A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGlow = LinearGradient(
    colors: [Color(0xFFFFFCF8), Color(0xFFFAF5EE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Premium font system — Playfair Display (headings) + Plus Jakarta Sans (body) + Space Grotesk (numbers)
class AiraFonts {
  AiraFonts._();

  /// Heading font — Playfair Display: elegant serif for titles
  static TextStyle heading({
    double fontSize = 36,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.playfairDisplay(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? AiraColors.charcoal,
        height: height,
        letterSpacing: letterSpacing,
      );

  /// Body font — Plus Jakarta Sans: modern clean sans-serif
  static TextStyle body({
    double fontSize = 26,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? AiraColors.charcoal,
        height: height,
        letterSpacing: letterSpacing,
      );

  /// Numeric display font — Space Grotesk: geometric, stunning numbers
  static TextStyle numeric({
    double fontSize = 36,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.spaceGrotesk(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? AiraColors.charcoal,
        height: height,
        letterSpacing: letterSpacing ?? -0.5,
      );

  /// Small label font
  static TextStyle label({
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? AiraColors.muted,
      );
}

/// Standard spacing & sizing constants
class AiraSizes {
  AiraSizes._();

  // Padding
  static const double sectionPadding = 20.0;
  static const double cardPadding = 16.0;
  static const double cardPaddingLg = 20.0;
  static const double pagePadding = 24.0;

  // Border radius
  static const double radiusSm = 12.0;
  static const double radiusMd = 18.0;
  static const double radiusLg = 24.0;

  // Card
  static const double cardGap = 16.0;

  // Heights
  static const double buttonHeight = 52.0;
  static const double inputHeight = 48.0;
  static const double tabHeight = 44.0;
  static const double bottomNavHeight = 72.0;
  static const double appBarHeight = 64.0;
  static const double fabSize = 56.0;

  // Icons
  static const double iconNav = 24.0;
  static const double iconAction = 20.0;

  // Avatars
  static const double avatarList = 48.0;
  static const double avatarProfile = 80.0;

  // Touch target (iPad minimum)
  static const double touchTarget = 44.0;
}

/// Card shadow from design system
class AiraShadows {
  AiraShadows._();

  static List<BoxShadow> get card => [
        BoxShadow(
          color: AiraColors.woodDk.withValues(alpha: 0.10),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get cardHover => [
        BoxShadow(
          color: AiraColors.woodDk.withValues(alpha: 0.15),
          blurRadius: 28,
          offset: const Offset(0, 6),
        ),
      ];
}

/// Main theme builder
class AiraTheme {
  AiraTheme._();

  static ThemeData get light {
    final headingFont = GoogleFonts.playfairDisplay();
    final bodyFont = GoogleFonts.plusJakartaSans();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AiraColors.cream,
      colorScheme: const ColorScheme.light(
        primary: AiraColors.woodDk,
        primaryContainer: AiraColors.woodPale,
        secondary: AiraColors.woodMid,
        secondaryContainer: AiraColors.woodWash,
        surface: AiraColors.white,
        error: AiraColors.terra,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AiraColors.charcoal,
        onError: Colors.white,
        outline: AiraColors.woodPale,
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AiraColors.cream,
        foregroundColor: AiraColors.charcoal,
        centerTitle: false,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 29,
          fontWeight: FontWeight.w700,
          color: AiraColors.charcoal,
        ),
      ),

      // Text theme
      textTheme: TextTheme(
        displayLarge: headingFont.copyWith(
          fontSize: 50,
          fontWeight: FontWeight.w700,
          color: AiraColors.charcoal,
        ),
        displayMedium: headingFont.copyWith(
          fontSize: 43,
          fontWeight: FontWeight.w700,
          color: AiraColors.charcoal,
        ),
        displaySmall: headingFont.copyWith(
          fontSize: 38,
          fontWeight: FontWeight.w600,
          color: AiraColors.charcoal,
        ),
        headlineMedium: headingFont.copyWith(
          fontSize: 33,
          fontWeight: FontWeight.w600,
          color: AiraColors.charcoal,
        ),
        titleLarge: bodyFont.copyWith(
          fontSize: 31,
          fontWeight: FontWeight.w600,
          color: AiraColors.charcoal,
        ),
        titleMedium: bodyFont.copyWith(
          fontSize: 29,
          fontWeight: FontWeight.w500,
          color: AiraColors.charcoal,
        ),
        titleSmall: bodyFont.copyWith(
          fontSize: 26,
          fontWeight: FontWeight.w500,
          color: AiraColors.charcoal,
        ),
        bodyLarge: bodyFont.copyWith(
          fontSize: 29,
          color: AiraColors.charcoal,
        ),
        bodyMedium: bodyFont.copyWith(
          fontSize: 26,
          color: AiraColors.charcoal,
        ),
        bodySmall: bodyFont.copyWith(
          fontSize: 24,
          color: AiraColors.muted,
        ),
        labelLarge: bodyFont.copyWith(
          fontSize: 26,
          fontWeight: FontWeight.w600,
          color: AiraColors.charcoal,
        ),
        labelMedium: bodyFont.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w500,
          color: AiraColors.muted,
        ),
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AiraColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AiraSizes.radiusSm),
          borderSide: const BorderSide(color: AiraColors.woodPale),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AiraSizes.radiusSm),
          borderSide: const BorderSide(color: AiraColors.woodPale),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AiraSizes.radiusSm),
          borderSide: const BorderSide(
            color: AiraColors.woodMid,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AiraSizes.radiusSm),
          borderSide: const BorderSide(color: AiraColors.terra),
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: AiraColors.muted,
          fontSize: 21,
        ),
      ),

      // Elevated button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AiraColors.woodDk,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, AiraSizes.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AiraSizes.radiusSm),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 23,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AiraColors.woodDk,
          side: const BorderSide(color: AiraColors.woodPale),
          minimumSize: const Size(double.infinity, AiraSizes.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AiraSizes.radiusSm),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 23,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Bottom nav
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AiraColors.white,
        selectedItemColor: AiraColors.woodDk,
        unselectedItemColor: AiraColors.muted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 19,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 19),
      ),

      // Card
      cardTheme: CardThemeData(
        color: AiraColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AiraSizes.radiusMd),
        ),
        margin: EdgeInsets.zero,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AiraColors.woodWash,
        selectedColor: AiraColors.woodDk,
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AiraColors.creamDk,
        thickness: 1,
        space: 1,
      ),

      // FloatingActionButton
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AiraColors.woodDk,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // TimePicker — prevent clock face number overlap from global font bump
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AiraColors.white,
        hourMinuteTextStyle: GoogleFonts.spaceGrotesk(fontSize: 40, fontWeight: FontWeight.w600),
        dayPeriodTextStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
        helpTextStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AiraColors.charcoal),
        dialTextStyle: GoogleFonts.plusJakartaSans(fontSize: 14),
        hourMinuteShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),

      // DatePicker — same fix for date picker dialogs
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AiraColors.white,
        headerHelpStyle: GoogleFonts.plusJakartaSans(fontSize: 14),
        weekdayStyle: GoogleFonts.plusJakartaSans(fontSize: 13),
        dayStyle: GoogleFonts.plusJakartaSans(fontSize: 14),
        yearStyle: GoogleFonts.plusJakartaSans(fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}
