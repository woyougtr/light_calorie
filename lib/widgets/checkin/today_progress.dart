import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_theme.dart';
import '../../models/models.dart';

/// 今日打卡进度
class TodayProgress extends StatelessWidget {
  final double progress; // 0.0 - 1.0
  final int completedCount;
  final int totalCount;

  const TodayProgress({
    super.key,
    required this.progress,
    required this.completedCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          // 标题行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.track_changes,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '今日打卡进度',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getProgressColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _getProgressColor(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 环形进度条
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: 1,
                  strokeWidth: 10,
                  backgroundColor: AppTheme.background,
                  valueColor: AlwaysStoppedAnimation(AppTheme.divider),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return CircularProgressIndicator(
                      value: value,
                      strokeWidth: 10,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation(_getProgressColor()),
                      strokeCap: StrokeCap.round,
                    );
                  },
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$completedCount/$totalCount',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _getProgressColor(),
                        ),
                      ),
                      Text(
                        '已完成',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor() {
    if (progress >= 1.0) return AppTheme.success;
    if (progress >= 0.7) return AppColors.primary;
    if (progress >= 0.4) return const Color(0xFFFFA000);
    return AppTheme.textHint;
  }
}

/// 今日打卡任务清单
class TodayChecklist extends StatelessWidget {
  final Map<String, dynamic> dietStatus;
  final int waterCount;
  final int waterGoal;
  final List<ExerciseRecord> exercises;
  final double? currentWeight;
  final VoidCallback onDietTap;
  final VoidCallback onWaterTap;
  final VoidCallback onExerciseTap;
  final VoidCallback onWeightTap;

  const TodayChecklist({
    super.key,
    required this.dietStatus,
    required this.waterCount,
    required this.waterGoal,
    required this.exercises,
    this.currentWeight,
    required this.onDietTap,
    required this.onWaterTap,
    required this.onExerciseTap,
    required this.onWeightTap,
  });

  @override
  Widget build(BuildContext context) {
    final completedMeals = (dietStatus['breakfast'] == true ? 1 : 0) +
        (dietStatus['lunch'] == true ? 1 : 0) +
        (dietStatus['dinner'] == true ? 1 : 0);
    final totalMeals = 3;
    // 任意一餐完成就算饮食打卡成功
    final isDietCompleted = completedMeals > 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          // 标题
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.checklist,
                  size: 18,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                const Text(
                  '今日任务',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          // 饮食打卡
          _buildTaskItem(
            icon: '🍱',
            title: '饮食打卡',
            subtitle: completedMeals == 0
                ? '今日未记录'
                : '已记录 ${completedMeals} 餐：'
                    '${dietStatus['breakfast'] == true ? '早餐 ' : ''}'
                    '${dietStatus['lunch'] == true ? '午餐 ' : ''}'
                    '${dietStatus['dinner'] == true ? '晚餐' : ''}',
            isCompleted: isDietCompleted,
            progress: isDietCompleted ? '✓' : '⭕',
            onTap: onDietTap,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          // 饮水打卡
          _buildTaskItem(
            icon: '💧',
            title: '饮水打卡',
            subtitle: waterCount == 0
                ? '今日未记录'
                : waterCount >= waterGoal
                    ? '目标达成 $waterCount/$waterGoal 杯'
                    : '已喝 $waterCount/$waterGoal 杯，再喝 ${waterGoal - waterCount} 杯达标',
            isCompleted: waterCount > 0,
            progress: waterCount > 0 ? '✓' : '⭕',
            onTap: onWaterTap,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          // 运动打卡
          _buildTaskItem(
            icon: '🏃',
            title: '运动打卡',
            subtitle: exercises.isNotEmpty
                ? '${_getTotalMinutes()}分钟 消耗 ${_getTotalCalories().toInt()} 卡'
                : '今日未运动',
            isCompleted: exercises.isNotEmpty,
            progress: exercises.isNotEmpty ? '✓' : '⭕',
            onTap: onExerciseTap,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          // 体重记录
          _buildTaskItem(
            icon: '⚖️',
            title: '体重记录',
            subtitle: currentWeight != null
                ? '${currentWeight!.toStringAsFixed(1)} kg'
                : '未记录',
            isCompleted: currentWeight != null,
            progress: currentWeight != null ? '✓' : '⭕',
            onTap: onWeightTap,
          ),
          // 底部统计
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(AppTheme.radiusLarge),
                bottomRight: Radius.circular(AppTheme.radiusLarge),
              ),
            ),
            child: Text(
              '已完成 ${_getCompletedCount()}/3 项',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem({
    required String icon,
    required String title,
    required String subtitle,
    required bool isCompleted,
    required String progress,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppTheme.success.withValues(alpha: 0.1)
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                progress,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isCompleted ? AppTheme.success : AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: AppTheme.textHint,
            ),
          ],
        ),
      ),
    );
  }

  int _getTotalMinutes() {
    return exercises.fold(0, (sum, e) => sum + e.duration);
  }

  double _getTotalCalories() {
    return exercises.fold(0.0, (sum, e) => sum + e.calorie);
  }

  int _getCompletedCount() {
    int count = 0;
    // 饮食：任意一餐完成就算成功
    if ((dietStatus['breakfast'] ?? false) ||
        (dietStatus['lunch'] ?? false) ||
        (dietStatus['dinner'] ?? false)) {
      count++;
    }
    // 饮水：任意饮水就算成功
    if (waterCount > 0) count++;
    if (exercises.isNotEmpty) count++;
    if (currentWeight != null) count++;
    return count;
  }
}
