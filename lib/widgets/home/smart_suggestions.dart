import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_theme.dart';

/// 智能建议卡片
class SmartSuggestions extends StatelessWidget {
  final int consumed;
  final int goal;
  final int waterCount;
  final int waterGoal;
  final int exerciseMinutes;
  final VoidCallback? onAddDinner;
  final VoidCallback? onAddExercise;

  const SmartSuggestions({
    super.key,
    required this.consumed,
    required this.goal,
    required this.waterCount,
    required this.waterGoal,
    required this.exerciseMinutes,
    this.onAddDinner,
    this.onAddExercise,
  });

  @override
  Widget build(BuildContext context) {
    final suggestions = _generateSuggestions();

    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                '智能建议',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...suggestions.map((s) => _buildSuggestionCard(s)),
      ],
    );
  }

  List<SuggestionItem> _generateSuggestions() {
    final suggestions = <SuggestionItem>[];
    final remaining = goal - consumed;

    // 晚餐建议
    if (remaining > 200 && remaining < 800) {
      suggestions.add(SuggestionItem(
        icon: '🌙',
        title: '晚餐建议',
        content: '已摄入 $consumed 大卡，建议晚餐控制在 ${(remaining * 0.6).toInt()}-${(remaining * 0.8).toInt()} 大卡',
        actionText: '查看推荐',
        onAction: onAddDinner,
      ));
    }

    // 喝水提醒
    if (waterCount < waterGoal ~/ 2) {
      suggestions.add(SuggestionItem(
        icon: '💧',
        title: '喝水提醒',
        content: '今天才喝了 $waterCount 杯水，记得多喝水促进新陈代谢',
        actionText: '去记录',
        onAction: onAddDinner, // 实际上应该跳到打卡页
      ));
    }

    // 运动建议
    if (exerciseMinutes == 0) {
      suggestions.add(SuggestionItem(
        icon: '💪',
        title: '运动提醒',
        content: '今天还没有运动哦，建议散步 30 分钟消耗约 135 大卡',
        actionText: '立即记录',
        onAction: onAddExercise,
      ));
    }

    return suggestions.take(2).toList();
  }

  Widget _buildSuggestionCard(SuggestionItem suggestion) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Center(
              child: Text(
                suggestion.icon,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  suggestion.content,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (suggestion.onAction != null)
            TextButton(
              onPressed: suggestion.onAction,
              child: Text(suggestion.actionText!),
            ),
        ],
      ),
    );
  }
}

class SuggestionItem {
  final String icon;
  final String title;
  final String content;
  final String? actionText;
  final VoidCallback? onAction;

  SuggestionItem({
    required this.icon,
    required this.title,
    required this.content,
    this.actionText,
    this.onAction,
  });
}
