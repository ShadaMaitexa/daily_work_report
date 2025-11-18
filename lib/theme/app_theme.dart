import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AcadenoTheme {
  static const Color primary = Color(0xFF5C2EDB);
  static const Color primaryDark = Color(0xFF4823A7);
  static const Color secondary = Color(0xFF18B6F6);
  static const Color accent = Color(0xFFFF7A18);
  static const Color midnight = Color(0xFF0E1024);
  static const Color background = Color(0xFFF5F4FF);

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4C1CC2), primary, Color(0xFF18B6F6), accent],
    stops: [0.0, 0.45, 0.75, 1.0],
  );

  static const LinearGradient auroraGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x145C2EDB), Color(0x1118B6F6), Color(0x10FF7A18)],
  );

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.poppinsTextTheme(),
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: Colors.white,
        primaryContainer: primary.withOpacity(0.15),
        onPrimaryContainer: primaryDark,
        secondary: secondary,
        onSecondary: Colors.white,
        secondaryContainer: secondary.withOpacity(0.16),
        onSecondaryContainer: midnight,
        tertiary: accent,
        onTertiary: Colors.white,
        tertiaryContainer: accent.withOpacity(0.2),
        onTertiaryContainer: midnight,
        error: Colors.redAccent,
        onError: Colors.white,
        background: background,
        onBackground: midnight,
        surface: Colors.white,
        onSurface: const Color(0xFF1A1930),
        surfaceVariant: const Color(0xFFE3E1F6),
        onSurfaceVariant: const Color(0xFF4B4A65),
        outline: const Color(0xFFBEBAD8),
        outlineVariant: const Color(0xFFDCD7F2),
        shadow: Colors.black.withOpacity(0.08),
        scrim: Colors.black87,
      ),
    );

    final colorScheme = base.colorScheme;

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: colorScheme.onBackground,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: colorScheme.onBackground,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 6,
        shadowColor: Colors.black.withOpacity(0.08),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF7F6FF),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.3),
        ),
        labelStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: colorScheme.secondaryContainer,
        selectedColor: primary.withOpacity(0.15),
        labelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: colorScheme.primary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE2DFF6),
        thickness: 1,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(primary.withOpacity(0.4)),
        radius: const Radius.circular(12),
      ),
    );
  }
}
