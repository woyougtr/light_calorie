import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_theme.dart';
import '../../data/foods.dart';
import '../../models/models.dart';

/// 时间轴饮食记录视图
class TimelineView extends StatelessWidget {
  final Map<MealType, List<FoodRecord>> recordsByMeal;
  final Function(MealType) onAddMeal;
  final Function(FoodRecord) onDelete;

  const TimelineView({
    super.key,
    required this.recordsByMeal,
    required this.onAddMeal,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasRecords = recordsByMeal.values.any((list) => list.isNotEmpty);

    return Column(
      children: [
        if (!hasRecords)
          Padding(
            padding: const EdgeInsets.only(top: 40, bottom: 20),
            child: _buildEmptyStateHint(),
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: _buildTimelineItems(),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyStateHint() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.restaurant_menu, size: 48, color: AppTheme.textHint),
          const SizedBox(height: 12),
          Text(
            '今天还没有记录饮食',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            '点击下方餐次开始记录',
            style: TextStyle(fontSize: 12, color: AppTheme.textHint),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTimelineItems() {
    final widgets = <Widget>[];
    final mealOrder = [MealType.breakfast, MealType.lunch, MealType.dinner, MealType.snack];

    for (final mealType in mealOrder) {
      final records = recordsByMeal[mealType] ?? [];
      final mealCalories = records.fold<int>(0, (sum, r) => sum + r.calorie.toInt());

      // 时间 + 图标
      widgets.add(_buildTimelineHeader(mealType, mealCalories, records.isNotEmpty));

      // 内容区域
      if (records.isNotEmpty) {
        widgets.add(_buildTimelineContent(mealType, records));
      } else {
        widgets.add(_buildEmptyMealPrompt(mealType));
      }

      widgets.add(const SizedBox(height: 16));
    }

    return widgets;
  }

  Widget _buildTimelineHeader(MealType mealType, int calories, bool hasRecords) {
    final timeStr = _getMealTime(mealType);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 时间
        SizedBox(
          width: 50,
          child: Text(
            timeStr,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        // 时间轴线
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: hasRecords ? _getMealColor(mealType) : AppTheme.divider,
                shape: BoxShape.circle,
                border: Border.all(
                  color: hasRecords ? _getMealColor(mealType) : AppTheme.divider,
                  width: 2,
                ),
              ),
            ),
            Container(
              width: 2,
              height: hasRecords ? 80 : 40,
              color: hasRecords ? _getMealColor(mealType).withOpacity(0.3) : AppTheme.divider,
            ),
          ],
        ),
        const SizedBox(width: 12),
        // 餐次标题
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${mealType.icon} ${mealType.label}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (hasRecords) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getMealColor(mealType).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$calories kcal',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _getMealColor(mealType),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineContent(MealType mealType, List<FoodRecord> records) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 50), // 时间占位
        // 时间轴线延续
        Container(
          width: 12,
          alignment: Alignment.center,
          child: Container(
            width: 2,
            height: records.length * 50 + 60,
            color: _getMealColor(mealType).withOpacity(0.3),
          ),
        ),
        const SizedBox(width: 12),
        // 食物列表
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...records.map((record) => _buildFoodItem(record, mealType)),
                const Divider(height: 24),
                // 小计
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '小计',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      '${records.fold<int>(0, (sum, r) => sum + r.calorie.toInt())} kcal',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _getMealColor(mealType),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 添加按钮
                InkWell(
                  onTap: () => onAddMeal(mealType),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.divider),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, size: 16, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '添加食物',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyMealPrompt(MealType mealType) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 50), // 时间占位
        // 时间轴线延续
        Container(
          width: 12,
          alignment: Alignment.center,
          child: Container(
            width: 2,
            height: 50,
            color: AppTheme.divider,
          ),
        ),
        const SizedBox(width: 12),
        // 空状态提示
        Expanded(
          child: InkWell(
            onTap: () => onAddMeal(mealType),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.divider, style: BorderStyle.solid),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 18, color: AppTheme.textHint),
                  const SizedBox(width: 8),
                  Text(
                    '点击添加${mealType.label}记录',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFoodItem(FoodRecord record, MealType mealType) {
    final food = foodDatabase.where((f) => f.id == record.foodId).firstOrNull;
    final icon = food?.icon ?? mealType.icon;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              record.foodName,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Text(
            '${record.grams.toInt()}g',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${record.calorie.toInt()} kcal',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 16, color: AppTheme.textHint),
            onPressed: () => onDelete(record),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  String _getMealTime(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return '08:30';
      case MealType.lunch:
        return '12:30';
      case MealType.dinner:
        return '18:30';
      case MealType.snack:
        return '15:00';
    }
  }

  Color _getMealColor(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return const Color(0xFFFFA000);
      case MealType.lunch:
        return const Color(0xFFE53935);
      case MealType.dinner:
        return const Color(0xFF8E24AA);
      case MealType.snack:
        return const Color(0xFFFBC02D);
    }
  }
}
