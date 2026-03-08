// lib/screens/result_screen.dart
// Shows valuation result after prediction

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/app_theme.dart';

class ResultScreen extends StatelessWidget {
  final String bikeName, brand, city;
  final int engineCc, bikeAge, kmDriven, accidentCount;
  final double predictedPrice;
  final double? mlPrice, mlAdjusted;
  final bool mlOnline;

  const ResultScreen({
    super.key,
    required this.bikeName, required this.brand, required this.city,
    required this.engineCc, required this.bikeAge, required this.kmDriven,
    required this.accidentCount, required this.predictedPrice,
    this.mlPrice, this.mlAdjusted, required this.mlOnline,
  });

  String _fmt(double v) => '₹${NumberFormat('#,##,###').format(v.round())}';

  @override
  Widget build(BuildContext context) {
    final hasAccident = accidentCount > 0;
    final impact = (mlPrice != null && mlAdjusted != null) ? mlPrice! - mlAdjusted! : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Valuation Result', style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Main price card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [AppTheme.violet1.withOpacity(0.15), AppTheme.blue1.withOpacity(0.08)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.violet1.withOpacity(0.3)),
                boxShadow: [BoxShadow(color: AppTheme.violet1.withOpacity(0.12), blurRadius: 40, spreadRadius: 4)],
              ),
              child: Column(
                children: [
                  Text('$brand $bikeName',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(color: AppTheme.muted, fontSize: 13, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text('Estimated Market Value',
                    style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 12, letterSpacing: 2)),
                  const SizedBox(height: 16),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [AppTheme.violet2, AppTheme.blue2],
                    ).createShader(bounds),
                    child: Text(_fmt(predictedPrice),
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 44, fontWeight: FontWeight.w900,
                      )),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: mlOnline ? AppTheme.green.withOpacity(0.12) : AppTheme.muted.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: mlOnline ? AppTheme.green.withOpacity(0.3) : AppTheme.border),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(mlOnline ? Icons.smart_toy_outlined : Icons.calculate_outlined,
                        size: 13, color: mlOnline ? AppTheme.green : AppTheme.muted),
                      const SizedBox(width: 6),
                      Text(mlOnline ? 'ML Model Prediction' : 'Formula Estimate',
                        style: GoogleFonts.outfit(
                          color: mlOnline ? AppTheme.green : AppTheme.muted,
                          fontSize: 11, fontWeight: FontWeight.w600,
                        )),
                    ]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Accident impact card (if applicable)
            if (hasAccident && mlAdjusted != null) ...[
              _impactCard(impact),
              const SizedBox(height: 16),
            ],

            // Details grid
            _detailsCard(context),
            const SizedBox(height: 20),

            // Back button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surface,
                  foregroundColor: AppTheme.textPrimary,
                  side: const BorderSide(color: AppTheme.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('New Valuation', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _impactCard(double impact) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppTheme.red.withOpacity(0.06),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.red.withOpacity(0.2)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Accident Impact', style: GoogleFonts.outfit(
        color: AppTheme.red, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Base Value', style: GoogleFonts.outfit(color: AppTheme.muted, fontSize: 11)),
          Text(_fmt(mlPrice!), style: GoogleFonts.spaceMono(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
        ]),
        const Icon(Icons.arrow_forward_rounded, color: AppTheme.muted, size: 18),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('After Accident', style: GoogleFonts.outfit(color: AppTheme.muted, fontSize: 11)),
          Text(_fmt(mlAdjusted!), style: GoogleFonts.spaceMono(color: AppTheme.red, fontSize: 16, fontWeight: FontWeight.w700)),
        ]),
      ]),
      const SizedBox(height: 8),
      Text('Deduction: -${_fmt(impact)}',
        style: GoogleFonts.outfit(color: AppTheme.red, fontSize: 12, fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _detailsCard(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppTheme.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.border),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('BIKE DETAILS', style: GoogleFonts.outfit(
        color: AppTheme.violet2, fontSize: 11, letterSpacing: 2.5, fontWeight: FontWeight.w700)),
      const SizedBox(height: 16),
      _detailRow('Engine', '${engineCc}cc'),
      _detailRow('Age', '$bikeAge year${bikeAge != 1 ? "s" : ""}'),
      _detailRow('KM Driven', NumberFormat('#,##,###').format(kmDriven)),
      _detailRow('City', city),
      _detailRow('Accidents', accidentCount == 0 ? 'None' : '$accidentCount'),
    ]),
  );

  Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.outfit(color: AppTheme.muted, fontSize: 13)),
        Text(value, style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    ),
  );
}
