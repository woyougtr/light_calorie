import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_theme.dart';
import '../../data/foods.dart';
import '../../models/models.dart';

/// 今日记录列表
class TodayRecordsList extends StatelessWidget {
  final List<FoodRecord> records;
  final VoidCallback? onViewAll;

  const TodayRecordsList({
    super.key,
    required this.records,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 48,
              color: AppTheme.textHint,
            ),
            const SizedBox(height: 12),
            Text(
              '今天还没有记录饮食',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '点击上方按钮开始记录',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textHint,
              ),
            ),
          ],
        ),
      );
    }

    // 按餐次分组
    final groupedRecords = _groupByMealType(records);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.restaurant,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '今日饮食',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: onViewAll,
                child: const Text('查看全部'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            children: [
              ...groupedRecords.entries.expand((entry) {
                final mealType = entry.key;
                final mealRecords = entry.value;
                final mealCalories = mealRecords.fold<int>(
                  0,
                  (sum, r) => sum + r.calorie.toInt(),
                );

                return [
                  _buildMealSection(mealType, mealRecords, mealCalories),
                  if (mealType != groupedRecords.keys.last)
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: AppTheme.divider,
                    ),
                ];
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Map<MealType, List<FoodRecord>> _groupByMealType(List<FoodRecord> records) {
    final grouped = <MealType, List<FoodRecord>>{};
    for (final record in records) {
      grouped.putIfAbsent(record.mealType, () => []).add(record);
    }
    // 按餐次顺序排序
    final ordered = <MealType, List<FoodRecord>>{};
    for (final type in [MealType.breakfast, MealType.lunch, MealType.dinner, MealType.snack]) {
      if (grouped.containsKey(type)) {
        ordered[type] = grouped[type]!;
      }
    }
    return ordered;
  }

  Widget _buildMealSection(MealType mealType, List<FoodRecord> records, int totalCalories) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 餐次标题
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    mealType.icon,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    mealType.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$totalCalories 卡',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 食物列表
          ...records.map((record) => _buildFoodItem(record)),
        ],
      ),
    );
  }

  Widget _buildFoodItem(FoodRecord record) {
    final food = foodDatabase.where((f) => f.id == record.foodId).firstOrNull;
    final icon = food?.icon ?? record.mealType.icon;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                icon,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.foodName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${record.grams.toInt()}g',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${record.calorie.toInt()} 卡',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
