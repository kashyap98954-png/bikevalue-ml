// lib/services/api_service.dart
// All HTTP calls to PHP backend and Flask ML API

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/app_models.dart';

class ApiService {
  // ══════════════════════════════════════════════════
  // ⚠️  CHANGE THESE TWO URLS BEFORE RUNNING THE APP
  // ══════════════════════════════════════════════════

  // Your PHP site hosted online (e.g. InfinityFree, cPanel, 000webhost)
  // Example: 'https://bikevalue.infinityfreeapp.com/api.php'
  static const String baseUrl = 'https://YOUR-HOSTED-SITE.com/bikevalue/api.php';

  // Your Flask ML API — run ml_api.py locally and expose with ngrok
  // Example: 'https://abc123.ngrok-free.app/predict'
  static const String mlUrl = 'https://YOUR-NGROK-URL.ngrok-free.app/predict';

  // ── AUTH ─────────────────────────────────────────

  static Future<Map<String, dynamic>> signup({
    required String userId,
    required String email,
    required String password,
  }) async {
    try {
      final res = await http.post(
        Uri.parse(baseUrl),
        body: {'action': 'signup', 'user_id': userId, 'email': email, 'password': password},
      ).timeout(const Duration(seconds: 10));
      return json.decode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await http.post(
        Uri.parse(baseUrl),
        body: {'action': 'login', 'email': email, 'password': password},
      ).timeout(const Duration(seconds: 10));
      return json.decode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> adminLogin({
    required String email,
    required String password,
  }) async {
    try {
      final res = await http.post(
        Uri.parse(baseUrl),
        body: {'action': 'admin_login', 'email': email, 'password': password},
      ).timeout(const Duration(seconds: 10));
      return json.decode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ── ML PREDICTION ────────────────────────────────

  static Future<Map<String, dynamic>> getMLPrice({
    required String bikeName,
    required String brand,
    required double kmsDriver,
    required double owner,
    required double age,
    required String city,
    required double engineCapacity,
    required double accidentCount,
    required String accidentHistory,
  }) async {
    try {
      final res = await http.post(
        Uri.parse(mlUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'bike_name': bikeName.toLowerCase(),
          'brand': brand.toLowerCase(),
          'kms_driven': kmsDriver,
          'owner': owner,
          'age': age,
          'city': city.toLowerCase(),
          'engine_capacity': engineCapacity,
          'accident_count': accidentCount,
          'accident_history': accidentHistory,
        }),
      ).timeout(const Duration(seconds: 5));
      return json.decode(res.body);
    } catch (e) {
      return {'error': 'ML API offline'};
    }
  }

  // ── SAVE PREDICTION ───────────────────────────────

  static Future<Map<String, dynamic>> savePrediction({
    required String userId,
    required String bikeName,
    required String brand,
    required int engineCc,
    required int bikeAge,
    required String ownerType,
    required int kmDriven,
    required int accidentCount,
    required String accidentHistory,
    required double predictedPrice,
    double? mlPrice,
  }) async {
    try {
      final body = {
        'action': 'save_prediction',
        'user_id': userId,
        'bike_name': bikeName,
        'brand': brand,
        'engine_cc': engineCc.toString(),
        'bike_age': bikeAge.toString(),
        'owner_type': ownerType,
        'km_driven': kmDriven.toString(),
        'accident_count': accidentCount.toString(),
        'accident_history': accidentHistory,
        'predicted_price': predictedPrice.toString(),
        if (mlPrice != null) 'ml_price': mlPrice.toString(),
      };
      final res = await http.post(Uri.parse(baseUrl), body: body).timeout(const Duration(seconds: 10));
      return json.decode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to save: $e'};
    }
  }

  // ── PREDICTION HISTORY ────────────────────────────

  static Future<List<PredictionModel>> getHistory(String userId) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl?action=history&user_id=$userId'),
      ).timeout(const Duration(seconds: 10));
      final data = json.decode(res.body);
      if (data['success'] == true) {
        return (data['data'] as List).map((e) => PredictionModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ── ADMIN STATS ───────────────────────────────────

  static Future<AdminStats?> getAdminStats() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl?action=admin_stats'),
      ).timeout(const Duration(seconds: 10));
      final data = json.decode(res.body);
      if (data['success'] == true) return AdminStats.fromJson(data['data']);
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<List<PredictionModel>> getAllPredictions() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl?action=all_predictions'),
      ).timeout(const Duration(seconds: 10));
      final data = json.decode(res.body);
      if (data['success'] == true) {
        return (data['data'] as List).map((e) => PredictionModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
