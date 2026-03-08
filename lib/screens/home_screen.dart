// lib/screens/home_screen.dart
// Main user screen with bottom nav: Predict + History

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_theme.dart';
import '../services/session_service.dart';
import '../models/app_models.dart';
import 'predict_screen.dart';
import 'history_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final UserModel user;
  const HomeScreen({super.key, required this.user});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      PredictScreen(user: widget.user),
      HistoryScreen(user: widget.user),
    ];
  }

  Future<void> _logout() async {
    await SessionService.clear();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(colors: [AppTheme.violet1, AppTheme.blue1]),
            ),
            child: const Center(child: Text('⚡', style: TextStyle(fontSize: 16))),
          ),
          const SizedBox(width: 10),
          Text('BikeValue', style: GoogleFonts.playfairDisplay(
            color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w800,
          )),
        ]),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: PopupMenuButton<String>(
              color: AppTheme.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppTheme.border),
              ),
              onSelected: (v) { if (v == 'logout') _logout(); },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'info',
                  enabled: false,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.user.userId, style: GoogleFonts.outfit(color: AppTheme.violet2, fontWeight: FontWeight.w700)),
                    Text(widget.user.email, style: GoogleFonts.outfit(color: AppTheme.muted, fontSize: 11)),
                  ]),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(children: [
                    const Icon(Icons.logout, color: AppTheme.red, size: 16),
                    const SizedBox(width: 8),
                    Text('Logout', style: GoogleFonts.outfit(color: AppTheme.red)),
                  ]),
                ),
              ],
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.violet1.withOpacity(0.2),
                child: Text(
                  widget.user.userId[0].toUpperCase(),
                  style: GoogleFonts.outfit(color: AppTheme.violet2, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.border),
        ),
      ),
      body: IndexedStack(index: _tab, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: _tab,
          onTap: (i) => setState(() => _tab = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.search_rounded), label: 'Predict'),
            BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'History'),
          ],
        ),
      ),
    );
  }
}
