import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_theme.dart';

/// 连续打卡卡片
class ConsecutiveCard extends StatelessWidget {
  final int consecutiveDays;
  final int bestRecord;
  final int improvement; // 比上周多几天

  const ConsecutiveCard({
    super.key,
    required this.consecutiveDays,
    required this.bestRecord,
    this.improvement = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.secondary.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // 标题行
          Row(
            children: [
              Icon(Icons.emoji_events, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                '连续打卡',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 天数大数字
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$consecutiveDays',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '天',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 激励语
          Text(
            _getEncouragement(),
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (improvement > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '比上周多坚持 $improvement 天',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          // 星星展示
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              consecutiveDays.clamp(0, 12),
              (index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  Icons.star,
                  size: 20,
                  color: index < consecutiveDays
                      ? const Color(0xFFFFD700)
                      : AppTheme.divider,
                ),
              ),
            ),
          ),
          if (consecutiveDays > 12) ...[
            const SizedBox(height: 4),
            Text(
              '+${consecutiveDays - 12}',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          // 历史最佳
          Text(
            '历史最佳: $bestRecord 天',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textHint,
            ),
          ),
        ],
      ),
    );
  }

  String _getEncouragement() {
    if (consecutiveDays == 0) {
      return '从今天开始，坚持就是胜利 💪';
    } else if (consecutiveDays < 7) {
      return '继续保持，养成好习惯！';
    } else if (consecutiveDays < 14) {
      return '一周达成！你比想象中更棒 ✨';
    } else if (consecutiveDays < 21) {
      return '两周坚持！已经看到改变 🌟';
    } else if (consecutiveDays < 30) {
      return '即将满月！你的坚持值得骄傲 🎉';
    } else {
      return '$consecutiveDays天！这就是自律的力量 🔥';
    }
  }
}
