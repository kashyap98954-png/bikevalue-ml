// lib/screens/history_screen.dart
// Shows user's past predictions

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/app_theme.dart';
import '../services/api_service.dart';
import '../models/app_models.dart';

class HistoryScreen extends StatefulWidget {
  final UserModel user;
  const HistoryScreen({super.key, required this.user});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<PredictionModel> _predictions = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await ApiService.getHistory(widget.user.userId);
    setState(() { _predictions = data; _loading = false; });
  }

  String _fmt(double v) => '₹${NumberFormat('#,##,###').format(v.round())}';

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppTheme.violet1));

    if (_predictions.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.history_rounded, color: AppTheme.muted, size: 56),
          const SizedBox(height: 16),
          Text('No predictions yet', style: GoogleFonts.playfairDisplay(color: AppTheme.muted, fontSize: 20)),
          const SizedBox(height: 8),
          Text('Your valuation history will appear here',
            style: GoogleFonts.outfit(color: AppTheme.muted, fontSize: 13)),
        ]),
      );
    }

    return RefreshIndicator(
      color: AppTheme.violet1,
      backgroundColor: AppTheme.card,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _predictions.length,
        itemBuilder: (ctx, i) {
          final p = _predictions[i];
          final date = p.createdAt != null
            ? DateFormat('dd MMM yyyy').format(DateTime.parse(p.createdAt!))
            : '';
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Expanded(
                    child: Text('${p.brand} ${p.bikeName}',
                      style: GoogleFonts.outfit(
                        color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700,
                      )),
                  ),
                  if (p.accidentCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.red.withOpacity(0.2)),
                      ),
                      child: Text('⚠️ ${p.accidentCount} acc.',
                        style: GoogleFonts.outfit(color: AppTheme.red, fontSize: 10)),
                    ),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  _chip('${p.engineCc}cc'),
                  const SizedBox(width: 6),
                  _chip('${p.bikeAge}yr'),
                  const SizedBox(width: 6),
                  _chip('${NumberFormat('#,##,###').format(p.kmDriven)} km'),
                ]),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Formula Price', style: GoogleFonts.outfit(color: AppTheme.muted, fontSize: 10)),
                    ShaderMask(
                      shaderCallback: (b) => const LinearGradient(
                        colors: [AppTheme.violet2, AppTheme.blue2],
                      ).createShader(b),
                      child: Text(_fmt(p.predictedPrice),
                        style: GoogleFonts.spaceMono(
                          color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700,
                        )),
                    ),
                  ]),
                  if (p.mlPrice != null)
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('ML Price', style: GoogleFonts.outfit(color: AppTheme.muted, fontSize: 10)),
                      Text(_fmt(p.mlPrice!),
                        style: GoogleFonts.spaceMono(color: AppTheme.green, fontSize: 16, fontWeight: FontWeight.w700)),
                    ]),
                  Text(date, style: GoogleFonts.outfit(color: AppTheme.muted, fontSize: 11)),
                ]),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _chip(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: AppTheme.violet1.withOpacity(0.08),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: AppTheme.border),
    ),
    child: Text(label, style: GoogleFonts.outfit(color: AppTheme.muted, fontSize: 11)),
  );
}
