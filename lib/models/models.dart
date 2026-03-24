// 用户模型
class AppUser {
  final String id;
  final String email;
  final String? nickname;
  final double? targetWeight;
  final double? initialWeight;
  final int dailyCalorieGoal;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.email,
    this.nickname,
    this.targetWeight,
    this.initialWeight,
    this.dailyCalorieGoal = 1800,
    required this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      nickname: json['nickname'],
      targetWeight: json['target_weight']?.toDouble(),
      initialWeight: json['initial_weight']?.toDouble(),
      dailyCalorieGoal: json['daily_calorie_goal'] ?? 1800,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'nickname': nickname,
    'target_weight': targetWeight,
    'initial_weight': initialWeight,
    'daily_calorie_goal': dailyCalorieGoal,
  };
}

// 餐饮类型
enum MealType {
  breakfast('早餐', '🍳'),
  lunch('午餐', '🍱'),
  dinner('晚餐', '🍜'),
  snack('加餐', '🍪');

  final String label;
  final String icon;
  const MealType(this.label, this.icon);
}

// 食物记录
class FoodRecord {
  final String id;
  final String oderId;
  final String foodId;
  final String foodName;
  final double grams;
  final double calorie;
  final MealType mealType;
  final DateTime createdAt;

  FoodRecord({
    required this.id,
    required this.oderId,
    required this.foodId,
    required this.foodName,
    required this.grams,
    required this.calorie,
    required this.mealType,
    required this.createdAt,
  });

  factory FoodRecord.fromJson(Map<String, dynamic> json) {
    return FoodRecord(
      id: json['id'] ?? '',
      oderId: json['user_id'] ?? '',
      foodId: json['food_id'] ?? '',
      foodName: json['food_name'] ?? '',
      grams: (json['grams'] ?? 0).toDouble(),
      calorie: (json['calorie'] ?? 0).toDouble(),
      mealType: MealType.values.firstWhere(
        (e) => e.name == json['meal_type'],
        orElse: () => MealType.snack,
      ),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': oderId,
    'food_id': foodId,
    'food_name': foodName,
    'grams': grams,
    'calorie': calorie,
    'meal_type': mealType.name,
    'created_at': createdAt.toIso8601String(),
  };
}

// 打卡记录
class CheckIn {
  final String id;
  final String oderId;
  final DateTime date;
  final String? photoUrl;
  final String? description;
  final List<String> tags;
  final DateTime createdAt;

  CheckIn({
    required this.id,
    required this.oderId,
    required this.date,
    this.photoUrl,
    this.description,
    this.tags = const [],
    required this.createdAt,
  });

  factory CheckIn.fromJson(Map<String, dynamic> json) {
    return CheckIn(
      id: json['id'] ?? '',
      oderId: json['user_id'] ?? '',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      photoUrl: json['photo_url'],
      description: json['description'],
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': oderId,
    'date': date.toIso8601String().split('T')[0],
    'photo_url': photoUrl,
    'description': description,
    'tags': tags,
    'created_at': createdAt.toIso8601String(),
  };
}

// 体重记录
class WeightRecord {
  final String id;
  final String oderId;
  final double weight;
  final DateTime date;
  final DateTime createdAt;

  WeightRecord({
    required this.id,
    required this.oderId,
    required this.weight,
    required this.date,
    required this.createdAt,
  });

  factory WeightRecord.fromJson(Map<String, dynamic> json) {
    return WeightRecord(
      id: json['id'] ?? '',
      oderId: json['user_id'] ?? '',
      weight: (json['weight'] ?? 0).toDouble(),
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': oderId,
    'weight': weight,
    'date': date.toIso8601String().split('T')[0],
    'created_at': createdAt.toIso8601String(),
  };
}

// 每日打卡任务
class DailyTask {
  final String id;
  final String label;
  final String icon;
  final bool isCompleted;
  final String? completedAt;

  DailyTask({
    required this.id,
    required this.label,
    required this.icon,
    this.isCompleted = false,
    this.completedAt,
  });
}
