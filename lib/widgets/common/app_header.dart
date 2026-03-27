import 'dart:ui';
import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_theme.dart';

/// 首页顶部栏 - 毛玻璃效果
class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String dateStr;
  final String nickname;
  final VoidCallback? onNotificationTap;

  const HomeAppBar({
    super.key,
    required this.dateStr,
    required this.nickname,
    this.onNotificationTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 60 + MediaQuery.of(context).padding.top,
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            border: Border(
              bottom: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.15),
                width: 2,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // 日期
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '轻卡',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // 通知
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.notifications_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    onPressed: onNotificationTap,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                ),
                const SizedBox(width: 8),
                // 头像
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    nickname.isNotEmpty ? nickname.substring(0, 1) : '你',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 打卡页顶部栏 - 毛玻璃效果
class CheckInAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int consecutiveDays;
  final double progress; // 0.0 ~ 1.0
  final int completed;
  final int total;

  const CheckInAppBar({
    super.key,
    required this.consecutiveDays,
    required this.progress,
    required this.completed,
    required this.total,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 60 + MediaQuery.of(context).padding.top,
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            border: Border(
              bottom: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.15),
                width: 2,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // 左侧：标题
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '打卡',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            size: 13,
                            color: Colors.orange[400],
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '连续 $consecutiveDays 天',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // 右侧：进度信息
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 2.5,
                          backgroundColor: AppTheme.divider,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$completed/$total',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 记录页顶部栏 - 毛玻璃效果
class RecordAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String dateStr;
  final VoidCallback? onDateTap;

  const RecordAppBar({
    super.key,
    required this.dateStr,
    this.onDateTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 60 + MediaQuery.of(context).padding.top,
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            border: Border(
              bottom: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.15),
                width: 2,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '饮食记录',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // 日期选择
                GestureDetector(
                  onTap: onDateTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
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
      ),
    );
  }
}

/// 我的页顶部栏 - 毛玻璃效果
class ProfileAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String nickname;
  final int consecutiveDays;
  final int level;
  final VoidCallback? onSettingsTap;

  const ProfileAppBar({
    super.key,
    required this.nickname,
    required this.consecutiveDays,
    required this.level,
    this.onSettingsTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 60 + MediaQuery.of(context).padding.top,
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            border: Border(
              bottom: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.15),
                width: 2,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // 头像
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    nickname.isNotEmpty ? nickname.substring(0, 1) : '你',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        nickname.isNotEmpty ? nickname : '用户',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Lv.$level',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.bolt,
                            size: 12,
                            color: Colors.amber[600],
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '$consecutiveDays 天',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // 设置按钮
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.textSecondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.settings_outlined,
                      color: AppTheme.textSecondary,
                      size: 20,
                    ),
                    onPressed: onSettingsTap,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
