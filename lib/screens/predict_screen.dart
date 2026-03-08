// lib/screens/predict_screen.dart
// Main prediction form — mirrors website predict.php

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/app_theme.dart';
import '../services/api_service.dart';
import '../services/app_theme.dart' show BikeData;
import '../models/app_models.dart';
import 'result_screen.dart';

class PredictScreen extends StatefulWidget {
  final UserModel user;
  const PredictScreen({super.key, required this.user});
  @override
  State<PredictScreen> createState() => _PredictScreenState();
}

class _PredictScreenState extends State<PredictScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _brand;
  String? _bikeName;
  String? _city;
  String? _ownerType = '1st';
  String _accidentHistory = 'none';

  final _engineCtrl   = TextEditingController();
  final _ageCtrl      = TextEditingController();
  final _kmCtrl       = TextEditingController();
  final _accCountCtrl = TextEditingController(text: '0');

  bool _loading = false;

  List<String> get _bikeNames => _brand != null ? (BikeData.bikesByBrand[_brand] ?? []) : [];

  double _calcFallbackPrice() {
    final cc  = double.tryParse(_engineCtrl.text) ?? 0;
    final age = double.tryParse(_ageCtrl.text) ?? 0;
    final km  = double.tryParse(_kmCtrl.text) ?? 0;
    final acc = double.tryParse(_accCountCtrl.text) ?? 0;
    double price = cc * 120;
    price -= price * 0.15 * age;
    price -= km / 100;
    final ownerPenalty = {'1st': 0, '2nd': 0.08, '3rd': 0.15, '4th+': 0.22};
    price -= price * (ownerPenalty[_ownerType] ?? 0);
    if (acc > 0) price -= price * (0.10 * acc);
    return price.clamp(5000, double.infinity);
  }

  Future<void> _predict() async {
    if (!_formKey.currentState!.validate()) return;
    if (_brand == null || _bikeName == null || _city == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please select Brand, Bike Name and City.', style: GoogleFonts.outfit()),
        backgroundColor: AppTheme.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      return;
    }

    setState(() => _loading = true);

    final engineCc  = int.tryParse(_engineCtrl.text) ?? 0;
    final bikeAge   = int.tryParse(_ageCtrl.text) ?? 0;
    final kmDriven  = int.tryParse(_kmCtrl.text) ?? 0;
    final accCount  = int.tryParse(_accCountCtrl.text) ?? 0;
    final accHist   = accCount == 0 ? 'none' : _accidentHistory;

    // Try ML API
    final mlRes = await ApiService.getMLPrice(
      bikeName: _bikeName!,
      brand: _brand!,
      kmsDriver: kmDriven.toDouble(),
      owner: double.tryParse(_ownerType?.replaceAll(RegExp(r'[^\d]'), '') ?? '1') ?? 1,
      age: bikeAge.toDouble(),
      city: _city!,
      engineCapacity: engineCc.toDouble(),
      accidentCount: accCount.toDouble(),
      accidentHistory: accHist,
    );

    double finalPrice;
    double? mlPrice;
    double? mlAdjusted;

    if (mlRes.containsKey('predicted_price')) {
      mlPrice    = (mlRes['predicted_price'] as num).toDouble();
      mlAdjusted = mlRes['predicted_adjusted'] != null ? (mlRes['predicted_adjusted'] as num).toDouble() : null;
      finalPrice = mlPrice;
    } else {
      finalPrice = _calcFallbackPrice();
    }

    // Save to DB
    await ApiService.savePrediction(
      userId: widget.user.userId,
      bikeName: _bikeName!,
      brand: _brand!,
      engineCc: engineCc,
      bikeAge: bikeAge,
      ownerType: _ownerType ?? '1st',
      kmDriven: kmDriven,
      accidentCount: accCount,
      accidentHistory: accHist,
      predictedPrice: finalPrice,
      mlPrice: mlPrice,
    );

    setState(() => _loading = false);

    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => ResultScreen(
      bikeName: _bikeName!,
      brand: _brand!,
      engineCc: engineCc,
      bikeAge: bikeAge,
      kmDriven: kmDriven,
      city: _city!,
      accidentCount: accCount,
      predictedPrice: finalPrice,
      mlPrice: mlPrice,
      mlAdjusted: mlAdjusted,
      mlOnline: mlRes.containsKey('predicted_price'),
    )));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('🏍️ Bike Details'),
            const SizedBox(height: 14),

            // Brand
            _dropdown('Select Brand', BikeData.brands, _brand, (v) {
              setState(() { _brand = v; _bikeName = null; });
            }),
            const SizedBox(height: 14),

            // Bike Name
            _dropdown(
              _brand == null ? 'Select Brand first' : 'Select Bike Model',
              _bikeNames, _bikeName,
              _brand == null ? null : (v) => setState(() => _bikeName = v),
            ),
            const SizedBox(height: 14),

            // Engine CC
            _textField(_engineCtrl, 'Engine Capacity (cc)', TextInputType.number, 'e.g. 350'),
            const SizedBox(height: 14),

            // City
            _dropdown('Select City', BikeData.cities, _city, (v) => setState(() => _city = v)),
            const SizedBox(height: 24),

            _sectionHeader('📋 Ownership Details'),
            const SizedBox(height: 14),

            // Owner type
            _dropdown('Owner Type', BikeData.ownerTypes, _ownerType, (v) => setState(() => _ownerType = v)),
            const SizedBox(height: 14),

            // Age
            _textField(_ageCtrl, 'Bike Age (years)', TextInputType.number, 'e.g. 3'),
            const SizedBox(height: 14),

            // KM driven
            _textField(_kmCtrl, 'KM Driven', TextInputType.number, 'e.g. 25000'),
            const SizedBox(height: 24),

            _sectionHeader('⚠️ Accident History'),
            const SizedBox(height: 14),

            // Accident count
            _textField(_accCountCtrl, 'Number of Accidents', TextInputType.number, '0',
              onChanged: (v) => setState(() {})),
            const SizedBox(height: 14),

            // Accident type (only if count > 0)
            if ((int.tryParse(_accCountCtrl.text) ?? 0) > 0) ...[
              _dropdown('Accident Severity', BikeData.accidentTypes.where((e) => e != 'none').toList(),
                _accidentHistory == 'none' ? null : _accidentHistory,
                (v) => setState(() => _accidentHistory = v ?? 'minor')),
              const SizedBox(height: 24),
            ] else
              const SizedBox(height: 10),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _loading ? null : _predict,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.violet1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _loading
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.calculate_rounded, size: 20),
                      const SizedBox(width: 10),
                      Text('Get Valuation', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700)),
                    ]),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String text) => Row(children: [
    Text(text, style: GoogleFonts.outfit(
      color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700,
    )),
    const SizedBox(width: 12),
    Expanded(child: Container(height: 1, color: AppTheme.border)),
  ]);

  Widget _dropdown(String hint, List<String> items, String? value, ValueChanged<String?>? onChanged) =>
    DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(hintText: hint),
      dropdownColor: AppTheme.card,
      style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 14),
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.muted),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );

  Widget _textField(
    TextEditingController ctrl,
    String label,
    TextInputType type,
    String hint, {
    ValueChanged<String>? onChanged,
  }) =>
    TextFormField(
      controller: ctrl,
      keyboardType: type,
      onChanged: onChanged,
      style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 14),
      inputFormatters: type == TextInputType.number ? [FilteringTextInputFormatter.digitsOnly] : [],
      decoration: InputDecoration(labelText: label, hintText: hint),
      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
    );
}
