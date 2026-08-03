import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GoAthleteTypography {
  static TextTheme getTextTheme() {
    return GoogleFonts.openSansTextTheme().copyWith(
      displayLarge: GoogleFonts.openSans(fontSize: 48, fontWeight: FontWeight.w700, letterSpacing: -0.96),
      headlineLarge: GoogleFonts.openSans(fontSize: 32, fontWeight: FontWeight.w600, letterSpacing: -0.32),
      headlineMedium: GoogleFonts.openSans(fontSize: 24, fontWeight: FontWeight.w600),
      bodyLarge: GoogleFonts.openSans(fontSize: 18, fontWeight: FontWeight.w400),
      bodyMedium: GoogleFonts.openSans(fontSize: 16, fontWeight: FontWeight.w400),
      labelMedium: GoogleFonts.openSans(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.14),
      labelSmall: GoogleFonts.openSans(fontSize: 12, fontWeight: FontWeight.w500),
    );
  }
}
