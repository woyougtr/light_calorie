import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../config/app_theme.dart';

/// 环形进度条组件
class CircularProgress extends StatelessWidget {
  final double progress; // 0.0 - 1.0
  final double size;
  final double strokeWidth;
  final Color? backgroundColor;
  final Color? progressColor;
  final Widget? center;
  final bool animate;

  const CircularProgress({
    super.key,
    required this.progress,
    this.size = 120,
    this.strokeWidth = 12,
    this.backgroundColor,
    this.progressColor,
    this.center,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? AppColors.primary.withOpacity(0.1);
    final pgColor = progressColor ?? _getProgressColor(progress);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 背景圆环
          CircularProgressIndicator(
            value: 1,
            strokeWidth: strokeWidth,
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation(bgColor),
          ),
          // 进度圆环
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: animate ? const Duration(milliseconds: 800) : Duration.zero,
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return CircularProgressIndicator(
                value: value,
                strokeWidth: strokeWidth,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation(pgColor),
                strokeCap: StrokeCap.round,
              );
            },
          ),
          // 中心内容
          if (center != null)
            Center(child: center!),
        ],
      ),
    );
  }

  Color _getProgressColor(double value) {
    if (value >= 1.0) return AppTheme.danger;
    if (value >= 0.9) return AppTheme.warning;
    if (value >= 0.7) return AppColors.primary;
    return AppTheme.success;
  }
}

/// 小型环形进度（用于饮水等）
class MiniCircularProgress extends StatelessWidget {
  final double progress;
  final double size;
  final IconData icon;
  final Color color;

  const MiniCircularProgress({
    super.key,
    required this.progress,
    this.size = 64,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: 1,
            strokeWidth: 6,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation(color.withOpacity(0.1)),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return CircularProgressIndicator(
                value: value,
                strokeWidth: 6,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation(color),
                strokeCap: StrokeCap.round,
              );
            },
          ),
          Center(
            child: Icon(
              icon,
              size: size * 0.4,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
