// lib/services/app_theme.dart
// BikeValue dark purple theme — matches website

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color bg = Color(0xFF04040E);
  static const Color surface = Color(0xFF0A081C);
  static const Color card = Color(0xFF0D0B22);
  static const Color violet1 = Color(0xFF7C5CFC);
  static const Color violet2 = Color(0xFF9B7EFF);
  static const Color blue1 = Color(0xFF4A90D9);
  static const Color blue2 = Color(0xFF5BB3FF);
  static const Color cyan = Color(0xFF22D3EE);
  static const Color green = Color(0xFF34D399);
  static const Color red = Color(0xFFF87171);
  static const Color muted = Color(0xFF6B6B9A);
  static const Color textPrimary = Color(0xFFE8E4FF);
  static const Color textSecondary = Color(0xFF9A96C0);
  static const Color border = Color(0x1F7C5CFC);

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.dark(
          primary: violet1,
          secondary: cyan,
          surface: surface,
          error: red,
        ),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
          displayLarge: GoogleFonts.playfairDisplay(color: textPrimary, fontWeight: FontWeight.w800),
          displayMedium: GoogleFonts.playfairDisplay(color: textPrimary, fontWeight: FontWeight.w700),
          titleLarge: GoogleFonts.outfit(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 20),
          titleMedium: GoogleFonts.outfit(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 16),
          bodyLarge: GoogleFonts.outfit(color: textPrimary, fontSize: 15),
          bodyMedium: GoogleFonts.outfit(color: textSecondary, fontSize: 13),
          labelSmall: GoogleFonts.outfit(color: muted, letterSpacing: 2, fontSize: 10),
        ),
        cardTheme: CardTheme(
          color: card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: border, width: 1),
          ),
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: violet1, width: 1.5),
          ),
          labelStyle: GoogleFonts.outfit(color: muted, fontSize: 13),
          hintStyle: GoogleFonts.outfit(color: muted, fontSize: 13),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: violet1,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 0.5),
            elevation: 0,
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xCC04040E),
          elevation: 0,
          titleTextStyle: GoogleFonts.playfairDisplay(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          iconTheme: const IconThemeData(color: textPrimary),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: surface,
          selectedItemColor: violet2,
          unselectedItemColor: muted,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
      );
}

// Bike data constants (matching your website exactly)
class BikeData {
  static const List<String> brands = [
    'Royal Enfield','Yamaha','Honda','Bajaj','TVS',
    'KTM','Suzuki','Kawasaki','Hero','Triumph'
  ];

  static const Map<String, List<String>> bikesByBrand = {
    'Royal Enfield': ['Classic 350','Classic 500','Bullet 350','Bullet 500','Thunderbird 350','Thunderbird 500','Himalayan','Meteor 350','Hunter 350'],
    'Yamaha':        ['FZ-S V3','FZ25','R15 V4','MT-15','R3','FZS-FI','Fazer 25','YZF R15','Ray ZR','Fascino','Alpha','SZ-RR'],
    'Honda':         ['CB Shine','CB Hornet 160R','CB350','CB500F','CBR650R','Activa 6G','Unicorn','Livo','SP 125','Shine SP','CB200X','NX200'],
    'Bajaj':         ['Pulsar 150','Pulsar 180','Pulsar 220F','Pulsar NS200','Pulsar RS200','Dominar 400','Avenger 220','CT100','Platina','Pulsar N250','Pulsar F250','Dominar 250'],
    'TVS':           ['Apache RTR 160','Apache RTR 200','Apache RR 310','Jupiter','NTorq 125','Raider 125','Ronin','iQube Electric','Star City+','Sport','HLX 125','Radeon'],
    'KTM':           ['Duke 200','Duke 250','Duke 390','RC 200','RC 390','Adventure 250','Adventure 390','Duke 125','RC 125'],
    'Suzuki':        ['Gixxer SF','Gixxer 250','V-Strom 650','Access 125','Burgman Street','Intruder 150','Avenis 125'],
    'Kawasaki':      ['Ninja 300','Ninja 400','Ninja 650','Z650','Versys 650','W175','Vulcan S'],
    'Hero':          ['Splendor Plus','Passion Pro','HF Deluxe','Glamour','Xtreme 160R','Xpulse 200','Maestro Edge','Destini 125','Super Splendor'],
    'Triumph':       ['Tiger 660','Trident 660'],
  };

  static const List<String> cities = [
    'Mumbai','Delhi','Bangalore','Chennai','Hyderabad',
    'Pune','Kolkata','Ahmedabad','Jaipur','Lucknow','Chandigarh','Kochi'
  ];

  static const List<String> accidentTypes = ['none','minor','major','severe'];
  static const List<String> ownerTypes = ['1st','2nd','3rd','4th+'];
}
