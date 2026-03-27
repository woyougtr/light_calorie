import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_theme.dart';
import '../../models/models.dart';

/// 快捷餐次按钮组
class MealButtons extends StatelessWidget {
  final Map<MealType, bool> mealStatus;
  final Function(MealType) onMealTap;

  const MealButtons({
    super.key,
    required this.mealStatus,
    required this.onMealTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildMealButton(
            MealType.breakfast,
            '早餐',
            '🍳',
            const Color(0xFFFFECB3),
            const Color(0xFFFFA000),
          ),
          const SizedBox(width: 12),
          _buildMealButton(
            MealType.lunch,
            '午餐',
            '🍱',
            const Color(0xFFFFCDD2),
            const Color(0xFFE53935),
          ),
          const SizedBox(width: 12),
          _buildMealButton(
            MealType.dinner,
            '晚餐',
            '🍜',
            const Color(0xFFE1BEE7),
            const Color(0xFF8E24AA),
          ),
          const SizedBox(width: 12),
          _buildMealButton(
            MealType.snack,
            '加餐',
            '🍪',
            const Color(0xFFFFF9C4),
            const Color(0xFFFBC02D),
          ),
        ],
      ),
    );
  }

  Widget _buildMealButton(
    MealType type,
    String label,
    String emoji,
    Color bgColor,
    Color accentColor,
  ) {
    final isCompleted = mealStatus[type] ?? false;

    return Expanded(
      child: GestureDetector(
        onTap: () => onMealTap(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 96, // 固定高度
          decoration: BoxDecoration(
            color: isCompleted ? accentColor : bgColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            boxShadow: isCompleted ? AppTheme.cardShadow : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    emoji,
                    style: TextStyle(
                      fontSize: 28,
                      color: isCompleted ? Colors.white : accentColor,
                    ),
                  ),
                  if (isCompleted)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle,
                          size: 16,
                          color: accentColor,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isCompleted ? Colors.white : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
