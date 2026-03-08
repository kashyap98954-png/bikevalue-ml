// lib/screens/admin_screen.dart
// Admin dashboard — mirrors admin.php

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/app_theme.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../models/app_models.dart';
import 'login_screen.dart';

class AdminScreen extends StatefulWidget {
  final UserModel user;
  const AdminScreen({super.key, required this.user});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _tab = 0;
  AdminStats? _stats;
  List<PredictionModel> _allPreds = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final stats = await ApiService.getAdminStats();
    final preds = await ApiService.getAllPredictions();
    setState(() { _stats = stats; _allPreds = preds; _loading = false; });
  }

  Future<void> _logout() async {
    await SessionService.clear();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  String _fmt(double v) => '₹${NumberFormat('#,##,###').format(v.round())}';

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
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('BikeValue', style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
            Text('Administration', style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.muted, letterSpacing: 1)),
          ]),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.muted),
            onPressed: _load,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.red),
            onPressed: _logout,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.border),
        ),
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: AppTheme.violet1))
        : Column(
            children: [
              // Segmented tab bar
              Container(
                color: AppTheme.surface,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(children: [
                  _tabBtn('Dashboard', 0, Icons.dashboard_rounded),
                  const SizedBox(width: 8),
                  _tabBtn('Users', 1, Icons.people_rounded),
                  const SizedBox(width: 8),
                  _tabBtn('Logs', 2, Icons.list_alt_rounded),
                ]),
              ),
              const Divider(height: 1, color: AppTheme.border),
              Expanded(child: IndexedStack(
                index: _tab,
                children: [_dashboardTab(), _usersTab(), _logsTab()],
              )),
            ],
          ),
    );
  }

  Widget _tabBtn(String label, int index, IconData icon) => Expanded(
    child: GestureDetector(
      onTap: () => setState(() => _tab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: _tab == index ? AppTheme.violet1.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _tab == index ? AppTheme.violet1.withOpacity(0.4) : AppTheme.border),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 14, color: _tab == index ? AppTheme.violet2 : AppTheme.muted),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.outfit(
            color: _tab == index ? AppTheme.violet2 : AppTheme.muted,
            fontWeight: _tab == index ? FontWeight.w700 : FontWeight.normal,
            fontSize: 12,
          )),
        ]),
      ),
    ),
  );

  // ── DASHBOARD TAB ──────────────────────────────────
  Widget _dashboardTab() {
    if (_stats == null) return _emptyState('No data available');
    final s = _stats!;
    return RefreshIndicator(
      color: AppTheme.violet1, backgroundColor: AppTheme.card,
      onRefresh: _load,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.7,
              children: [
                _statCard('👥', s.totalUsers.toString(), 'Total Users', AppTheme.green),
                _statCard('📈', s.totalPreds.toString(), 'Predictions', AppTheme.violet2),
                _statCard('⚠️', s.withAcc.toString(), 'With Accidents', AppTheme.red),
                _statCard('💰', _fmt(s.avgPrice), 'Avg Price', AppTheme.cyan),
                _statCard('🤖', s.mlCount.toString(), 'ML Predictions', const Color(0xFFA78BFA)),
              ],
            ),
            const SizedBox(height: 24),

            // Bar chart
            if (s.brandData.isNotEmpty) ...[
              Text('PREDICTIONS BY BRAND', style: GoogleFonts.outfit(
                color: AppTheme.violet2, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Container(
                height: 220,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                ),
                child: BarChart(BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= s.brandData.length) return const SizedBox();
                        final brand = s.brandData[i]['brand']?.toString() ?? '';
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(brand.length > 4 ? brand.substring(0, 4) : brand,
                            style: GoogleFonts.outfit(color: AppTheme.muted, fontSize: 9)),
                        );
                      },
                    )),
                    leftTitles: AxisTitles(sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                        style: GoogleFonts.outfit(color: AppTheme.muted, fontSize: 9)),
                    )),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.border, strokeWidth: 0.5),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: s.brandData.asMap().entries.map((e) => BarChartGroupData(
                    x: e.key,
                    barRods: [BarChartRodData(
                      toY: double.tryParse(e.value['cnt'].toString()) ?? 0,
                      gradient: const LinearGradient(
                        begin: Alignment.bottomCenter, end: Alignment.topCenter,
                        colors: [AppTheme.violet1, AppTheme.blue2],
                      ),
                      width: 18, borderRadius: BorderRadius.circular(4),
                    )],
                  )).toList(),
                )),
              ),
              const SizedBox(height: 24),
            ],

            // Recent predictions
            Text('RECENT PREDICTIONS', style: GoogleFonts.outfit(
              color: AppTheme.violet2, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...s.recentPreds.map((p) => _predRow(p)),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String icon, String value, String label, Color accent) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.card,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppTheme.border),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        Container(width: 3, height: 24, decoration: BoxDecoration(
          color: accent, borderRadius: BorderRadius.circular(2))),
      ]),
      const Spacer(),
      Text(value, style: GoogleFonts.playfairDisplay(
        color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
      Text(label, style: GoogleFonts.outfit(color: AppTheme.muted, fontSize: 10, letterSpacing: 1)),
    ]),
  );

  // ── USERS TAB ──────────────────────────────────────
  Widget _usersTab() {
    final users = _stats?.users ?? [];
    if (users.isEmpty) return _emptyState('No users yet');
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (ctx, i) {
        final u = users[i];
        final date = u['created_at'] != null
          ? DateFormat('dd MMM yyyy').format(DateTime.parse(u['created_at']))
          : '';
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppTheme.violet1.withOpacity(0.2),
              child: Text(
                (u['user_id'] ?? '?')[0].toString().toUpperCase(),
                style: GoogleFonts.outfit(color: AppTheme.violet2, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(u['user_id'] ?? '', style: GoogleFonts.outfit(
                color: AppTheme.violet2, fontWeight: FontWeight.w700, fontSize: 14)),
              Text(u['email'] ?? '', style: GoogleFonts.outfit(color: AppTheme.muted, fontSize: 12)),
            ])),
            Text(date, style: GoogleFonts.outfit(color: AppTheme.muted, fontSize: 11)),
          ]),
        );
      },
    );
  }

  // ── LOGS TAB ───────────────────────────────────────
  Widget _logsTab() {
    if (_allPreds.isEmpty) return _emptyState('No prediction logs yet');
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _allPreds.length,
      itemBuilder: (ctx, i) => _predRow(_allPreds[i]),
    );
  }

  Widget _predRow(PredictionModel p) {
    final date = p.createdAt != null
      ? DateFormat('dd MMM yy').format(DateTime.parse(p.createdAt!))
      : '';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${p.brand} ${p.bikeName}',
            style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 2),
          Text('${p.userId}  •  ${p.engineCc}cc  •  ${NumberFormat('#,##,###').format(p.kmDriven)}km',
            style: GoogleFonts.outfit(color: AppTheme.muted, fontSize: 11)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(colors: [AppTheme.violet2, AppTheme.blue2]).createShader(b),
            child: Text(_fmt(p.predictedPrice),
              style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
          ),
          if (p.accidentCount > 0)
            Text('${p.accidentCount} acc.', style: GoogleFonts.outfit(color: AppTheme.red, fontSize: 10)),
          Text(date, style: GoogleFonts.outfit(color: AppTheme.muted, fontSize: 10)),
        ]),
      ]),
    );
  }

  Widget _emptyState(String msg) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.inbox_rounded, color: AppTheme.muted, size: 48),
      const SizedBox(height: 12),
      Text(msg, style: GoogleFonts.outfit(color: AppTheme.muted, fontSize: 14)),
    ]),
  );
}
