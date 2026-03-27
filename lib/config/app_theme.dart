import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 应用主题扩展
class AppTheme {
  // 颜色变体
  static Color get primaryLight => const Color(0xFFFF8A65);
  static Color get primaryDark => const Color(0xFFE65100);
  static Color get success => const Color(0xFF00C853);
  static Color get warning => const Color(0xFFFFB300);
  static Color get danger => const Color(0xFFFF1744);
  static Color get info => const Color(0xFF00B0FF);
  
  // 背景色
  static Color get background => const Color(0xFFF5F5F5);
  static Color get surface => Colors.white;
  static Color get divider => const Color(0xFFE0E0E0);
  
  // 文字色
  static Color get textPrimary => const Color(0xFF212121);
  static Color get textSecondary => const Color(0xFF757575);
  static Color get textHint => const Color(0xFFBDBDBD);
  
  // 阴影
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> get floatShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];
  
  // 圆角
  static double get radiusSmall => 8;
  static double get radiusMedium => 12;
  static double get radiusLarge => 16;
  static double get radiusXLarge => 24;
  
  // 间距
  static double get spacingXs => 4;
  static double get spacingSm => 8;
  static double get spacingMd => 16;
  static double get spacingLg => 24;
  static double get spacingXl => 32;
}

/// 渐变定义
class AppGradients {
  static LinearGradient get primary => LinearGradient(
    colors: [AppColors.primary, AppTheme.primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient get success => LinearGradient(
    colors: [AppTheme.success, const Color(0xFF69F0AE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient get calorie => LinearGradient(
    colors: [AppColors.primary, const Color(0xFFFF9800)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
