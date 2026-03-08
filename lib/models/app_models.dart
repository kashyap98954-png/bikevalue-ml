// lib/models/app_models.dart
// Data models for BikeValue app

class UserModel {
  final String userId;
  final String email;
  final String role;

  UserModel({required this.userId, required this.email, required this.role});

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        userId: json['user_id'] ?? '',
        email: json['email'] ?? '',
        role: json['role'] ?? 'user',
      );
}

class PredictionModel {
  final int? id;
  final String userId;
  final String bikeName;
  final String brand;
  final int engineCc;
  final int bikeAge;
  final String ownerType;
  final int kmDriven;
  final int accidentCount;
  final String accidentHistory;
  final double predictedPrice;
  final double? mlPrice;
  final String? createdAt;

  PredictionModel({
    this.id,
    required this.userId,
    required this.bikeName,
    required this.brand,
    required this.engineCc,
    required this.bikeAge,
    required this.ownerType,
    required this.kmDriven,
    required this.accidentCount,
    required this.accidentHistory,
    required this.predictedPrice,
    this.mlPrice,
    this.createdAt,
  });

  factory PredictionModel.fromJson(Map<String, dynamic> json) => PredictionModel(
        id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
        userId: json['user_id'] ?? '',
        bikeName: json['bike_name'] ?? '',
        brand: json['brand'] ?? '',
        engineCc: int.tryParse(json['engine_cc'].toString()) ?? 0,
        bikeAge: int.tryParse(json['bike_age'].toString()) ?? 0,
        ownerType: json['owner_type'] ?? '1st',
        kmDriven: int.tryParse(json['km_driven'].toString()) ?? 0,
        accidentCount: int.tryParse(json['accident_count'].toString()) ?? 0,
        accidentHistory: json['accident_history'] ?? 'none',
        predictedPrice: double.tryParse(json['predicted_price'].toString()) ?? 0,
        mlPrice: json['ml_price'] != null ? double.tryParse(json['ml_price'].toString()) : null,
        createdAt: json['created_at'],
      );
}

class AdminStats {
  final int totalUsers;
  final int totalPreds;
  final int withAcc;
  final double avgPrice;
  final int mlCount;
  final List<Map<String, dynamic>> brandData;
  final List<PredictionModel> recentPreds;
  final List<Map<String, dynamic>> users;

  AdminStats({
    required this.totalUsers,
    required this.totalPreds,
    required this.withAcc,
    required this.avgPrice,
    required this.mlCount,
    required this.brandData,
    required this.recentPreds,
    required this.users,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) => AdminStats(
        totalUsers: int.tryParse(json['total_users'].toString()) ?? 0,
        totalPreds: int.tryParse(json['total_preds'].toString()) ?? 0,
        withAcc: int.tryParse(json['with_acc'].toString()) ?? 0,
        avgPrice: double.tryParse(json['avg_price'].toString()) ?? 0,
        mlCount: int.tryParse(json['ml_count'].toString()) ?? 0,
        brandData: List<Map<String, dynamic>>.from(json['brand_data'] ?? []),
        recentPreds: (json['recent_preds'] as List? ?? []).map((e) => PredictionModel.fromJson(e)).toList(),
        users: List<Map<String, dynamic>>.from(json['users'] ?? []),
      );
}
