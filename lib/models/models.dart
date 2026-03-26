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
    if (id.isNotEmpty) 'id': id,
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
    if (id.isNotEmpty) 'id': id,
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
    if (id.isNotEmpty) 'id': id,
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

// 运动类型 - 卡路里数据参考：运动医学研究及Apple Watch/Google Fit等主流健康应用
enum ExerciseType {
  // 高强度运动
  rope('跳绳', '🪢', 140.0),        // 每10分钟140大卡，高强度
  swimming('游泳', '🏊', 110.0),    // 每10分钟110大卡，全身运动
  basketball('篮球', '🏀', 100.0),  // 每10分钟100大卡，爆发性运动
  running('跑步', '🏃', 95.0),      // 每10分钟95大卡，中等配速8-10km/h
  
  // 中强度运动
  fitness('健身', '💪', 85.0),      // 每10分钟85大卡，力量训练
  badminton('羽毛球', '🏸', 75.0),  // 每10分钟75大卡，间歇性爆发
  cycling('骑行', '🚴', 70.0),      // 每10分钟70大卡，中等速度20-25km/h
  
  // 低强度运动
  walking('健走', '🚶', 45.0),      // 每10分钟45大卡，快走6-7km/h
  yoga('瑜伽', '🧘', 30.0),         // 每10分钟30大卡，舒缓拉伸
  other('其他', '🎯', 60.0);         // 每10分钟60大卡，默认中等强度

  final String label;
  final String icon;
  final double caloriePer10Min; // 每10分钟消耗大卡（基于60-70kg成年人）

  const ExerciseType(this.label, this.icon, this.caloriePer10Min);

  // 计算消耗卡路里
  // 公式：每10分钟消耗 × (分钟数/10)
  // 示例：跑步30分钟 = 95 × 3 = 285大卡
  double calculateCalorie(int minutes) {
    return (caloriePer10Min * minutes / 10);
  }
  
  // 获取描述信息
  String get description {
    return '$label：每10分钟约${caloriePer10Min.toInt()}大卡';
  }
}

// 运动记录
class ExerciseRecord {
  final String id;
  final String userId;
  final ExerciseType type;
  final int duration; // 分钟
  final double calorie;
  final DateTime date;
  final String? note;
  final DateTime createdAt;

  ExerciseRecord({
    required this.id,
    required this.userId,
    required this.type,
    required this.duration,
    required this.calorie,
    required this.date,
    this.note,
    required this.createdAt,
  });

  factory ExerciseRecord.fromJson(Map<String, dynamic> json) {
    return ExerciseRecord(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      type: ExerciseType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ExerciseType.other,
      ),
      duration: json['duration'] ?? 0,
      calorie: (json['calorie'] ?? 0).toDouble(),
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      note: json['note'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    if (id.isNotEmpty) 'id': id,
    'user_id': userId,
    'type': type.name,
    'duration': duration,
    'calorie': calorie,
    'date': date.toIso8601String().split('T')[0],
    'note': note,
    'created_at': createdAt.toIso8601String(),
  };
}
