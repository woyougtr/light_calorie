import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_theme.dart';

/// 成就徽章
class AchievementBadges extends StatelessWidget {
  final int consecutiveDays;
  final int waterStreak;
  final int totalExerciseMinutes;
  final double? weightChange;

  const AchievementBadges({
    super.key,
    required this.consecutiveDays,
    required this.waterStreak,
    required this.totalExerciseMinutes,
    this.weightChange,
  });

  @override
  Widget build(BuildContext context) {
    final badges = _getBadges();
    final unlockedCount = badges.where((b) => b.isUnlocked).length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      size: 18,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '成就徽章',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Text(
                  '$unlockedCount/${badges.length}',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: badges.length,
              itemBuilder: (context, index) {
                return _buildBadgeItem(badges[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Badge> _getBadges() {
    return [
      Badge(
        icon: '🥉',
        name: '新手入门',
        description: '连续打卡3天',
        isUnlocked: consecutiveDays >= 3,
      ),
      Badge(
        icon: '🔥',
        name: '7天坚持',
        description: '连续打卡7天',
        isUnlocked: consecutiveDays >= 7,
      ),
      Badge(
        icon: '💧',
        name: '喝水达人',
        description: '连续7天饮水达标',
        isUnlocked: waterStreak >= 7,
      ),
      Badge(
        icon: '🏃',
        name: '运动健将',
        description: '累计运动1000分钟',
        isUnlocked: totalExerciseMinutes >= 1000,
      ),
      Badge(
        icon: '➖',
        name: '减重先锋',
        description: '累计减重1kg',
        isUnlocked: weightChange != null && weightChange! <= -1,
      ),
      Badge(
        icon: '🌟',
        name: '完美周',
        description: '一周全部打卡',
        isUnlocked: consecutiveDays >= 7,
      ),
    ];
  }

  Widget _buildBadgeItem(Badge badge) {
    return Container(
      width: 70,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: badge.isUnlocked
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppTheme.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: badge.isUnlocked
                    ? AppColors.primary.withValues(alpha: 0.3)
                    : AppTheme.divider,
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                badge.isUnlocked ? badge.icon : '🔒',
                style: TextStyle(
                  fontSize: 24,
                  color: badge.isUnlocked ? null : AppTheme.textHint,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            badge.name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: badge.isUnlocked ? FontWeight.w500 : FontWeight.normal,
              color: badge.isUnlocked ? AppTheme.textPrimary : AppTheme.textHint,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class Badge {
  final String icon;
  final String name;
  final String description;
  final bool isUnlocked;

  Badge({
    required this.icon,
    required this.name,
    required this.description,
    required this.isUnlocked,
  });
}
