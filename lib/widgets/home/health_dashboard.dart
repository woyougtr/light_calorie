import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_theme.dart';
import '../circular_progress.dart';

/// 健康状态仪表盘
class HealthDashboard extends StatelessWidget {
  final int waterCount;
  final int waterGoal;
  final VoidCallback onWaterTap;

  final int exerciseMinutes;
  final double exerciseCalorie;
  final VoidCallback onExerciseTap;

  final double? currentWeight;
  final VoidCallback onWeightTap;

  const HealthDashboard({
    super.key,
    required this.waterCount,
    required this.waterGoal,
    required this.onWaterTap,
    required this.exerciseMinutes,
    required this.exerciseCalorie,
    required this.onExerciseTap,
    this.currentWeight,
    required this.onWeightTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // 饮水卡片
          Expanded(
            child: _buildDashboardCard(
              title: '饮水',
              icon: Icons.water_drop,
              iconColor: AppTheme.info,
              value: '$waterCount',
              unit: '/$waterGoal 杯',
              progress: waterCount / waterGoal,
              onTap: onWaterTap,
            ),
          ),
          const SizedBox(width: 12),
          // 运动卡片
          Expanded(
            child: _buildDashboardCard(
              title: '运动',
              icon: Icons.directions_run,
              iconColor: AppColors.secondary,
              value: '$exerciseMinutes',
              unit: '分钟',
              subtitle: exerciseCalorie > 0 ? '消耗 ${exerciseCalorie.toInt()} 卡' : '今日未运动',
              progress: exerciseMinutes > 0 ? (exerciseMinutes >= 30 ? 1.0 : exerciseMinutes / 30) : 0,
              onTap: onExerciseTap,
            ),
          ),
          const SizedBox(width: 12),
          // 体重卡片
          Expanded(
            child: _buildDashboardCard(
              title: '体重',
              icon: Icons.monitor_weight,
              iconColor: AppColors.primary,
              value: currentWeight?.toStringAsFixed(1) ?? '--',
              unit: 'kg',
              subtitle: currentWeight != null ? '当前体重' : '未记录',
              progress: currentWeight != null ? 1.0 : 0,
              onTap: onWeightTap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String value,
    required String unit,
    String? subtitle,
    required double progress,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          children: [
            // 标题和图标
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 数值
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: progress > 0 ? iconColor : AppTheme.textHint,
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            // 进度条
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: iconColor.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation(iconColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
