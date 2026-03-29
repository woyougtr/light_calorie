import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_theme.dart';

/// 快捷设置列表
class SettingsList extends StatelessWidget {
  final VoidCallback? onProfileTap;
  final VoidCallback? onGoalsTap;
  final VoidCallback? onRemindersTap;
  final VoidCallback? onStatsTap;
  final VoidCallback? onExportTap;
  final VoidCallback? onHelpTap;
  final VoidCallback? onLogoutTap;
  final VoidCallback? onDeleteAccountTap;

  const SettingsList({
    super.key,
    this.onProfileTap,
    this.onGoalsTap,
    this.onRemindersTap,
    this.onStatsTap,
    this.onExportTap,
    this.onHelpTap,
    this.onLogoutTap,
    this.onDeleteAccountTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          _buildSettingItem(
            icon: Icons.person_outline,
            title: '个人资料',
            onTap: onProfileTap,
          ),
          const Divider(height: 1, indent: 56),
          _buildSettingItem(
            icon: Icons.track_changes,
            title: '目标设置',
            onTap: onGoalsTap,
          ),
          const Divider(height: 1, indent: 56),
          _buildSettingItem(
            icon: Icons.notifications_outlined,
            title: '提醒设置',
            onTap: onRemindersTap,
          ),
          const Divider(height: 1, indent: 56),
          _buildSettingItem(
            icon: Icons.analytics_outlined,
            title: '详细统计',
            onTap: onStatsTap,
          ),
          const Divider(height: 1, indent: 56),
          _buildSettingItem(
            icon: Icons.download_outlined,
            title: '数据导出',
            onTap: onExportTap,
          ),
          const Divider(height: 1, indent: 56),
          _buildSettingItem(
            icon: Icons.help_outline,
            title: '帮助与反馈',
            onTap: onHelpTap,
          ),
          const Divider(height: 1, indent: 56),
          _buildDangerItem(
            icon: Icons.delete_forever_outlined,
            title: '注销账号',
            onTap: onDeleteAccountTap,
          ),
        ],
      ),
    );
  }

  Widget _buildDangerItem({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.red,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: Colors.red.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
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
}

/// 退出登录按钮
class LogoutButton extends StatelessWidget {
  final VoidCallback onTap;

  const LogoutButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: AppTheme.divider),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.logout,
              size: 18,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              '退出登录',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
