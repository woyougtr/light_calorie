import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/app_colors.dart';
import 'pages/auth_wrapper.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化日期格式化（中文）
  await initializeDateFormatting('zh_CN', null);

  await Supabase.initialize(
    url: SupabaseService.url,
    anonKey: SupabaseService.key,
  );
  runApp(const LightCalorieApp());
}

class LightCalorieApp extends StatelessWidget {
  const LightCalorieApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '轻卡',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}
