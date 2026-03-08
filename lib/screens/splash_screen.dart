// lib/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.2),
            radius: 1.4,
            colors: [Color(0x337C5CFC), AppTheme.bg],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.violet1, AppTheme.blue1],
                    ),
                    boxShadow: [BoxShadow(color: AppTheme.violet1.withOpacity(0.4), blurRadius: 32, spreadRadius: 4)],
                  ),
                  child: const Center(child: Text('⚡', style: TextStyle(fontSize: 40))),
                ),
                const SizedBox(height: 28),
                Text('BIKEVALUE',
                  style: GoogleFonts.playfairDisplay(
                    color: AppTheme.textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6,
                  )),
                const SizedBox(height: 8),
                Text('PRECISION VALUATION',
                  style: GoogleFonts.outfit(
                    color: AppTheme.muted,
                    fontSize: 11,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w500,
                  )),
                const SizedBox(height: 48),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.violet1.withOpacity(0.7)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
