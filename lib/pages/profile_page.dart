import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';
import '../widgets/common/app_header.dart';
import '../widgets/profile/achievement_badges.dart';
import '../widgets/profile/settings_list.dart';
import '../widgets/profile/weight_trend_chart.dart';
import '../widgets/profile/weekly_stats_grid.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  final AppUser user;
  const ProfilePage({super.key, required this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  List<WeightRecord> _weightRecords = [];
  int _consecutiveDays = 0;
  int _waterStreak = 0;
  int _totalExerciseMinutes = 0;
  
  // 本周数据
  int _weeklyCalories = 0;
  double _weeklyExerciseCalories = 0;
  int _weeklyCheckInDays = 0;
  
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadWeightRecords(),
      _loadCheckInData(),
      _loadWeeklyStats(),
    ]);
  }

  Future<void> _loadWeightRecords() async {
    final records = await SupabaseService.getWeightRecords(widget.user.id, limit: 30);
    if (mounted) {
      setState(() {
        _weightRecords = records;
      });
    }
  }

  Future<void> _loadCheckInData() async {
    final now = DateTime.now();
    final events = <DateTime, List<String>>{};
    int totalExerciseMinutes = 0;

    // 获取最近30天的记录
    for (int i = 0; i < 30; i++) {
      final day = now.subtract(Duration(days: i));
      final dateKey = DateTime(day.year, day.month, day.day);

      final foodRecords = await SupabaseService.getFoodRecords(widget.user.id, day);
      if (foodRecords.isNotEmpty) {
        events[dateKey] = events[dateKey] ?? [];
        events[dateKey]!.add('饮食');
      }

      final waterCount = await SupabaseService.getWaterRecord(widget.user.id, day);
      if (waterCount >= 8) {
        events[dateKey] = events[dateKey] ?? [];
        events[dateKey]!.add('饮水');
      }

      final exercises = await SupabaseService.getExerciseRecords(widget.user.id, date: day);
      if (exercises.isNotEmpty) {
        events[dateKey] = events[dateKey] ?? [];
        events[dateKey]!.add('运动');
        for (final e in exercises) {
          totalExerciseMinutes += e.duration;
        }
      }
    }

    // 计算连续打卡天数
    int consecutive = 0;
    DateTime checkDate = DateTime(now.year, now.month, now.day);
    while (events.containsKey(checkDate) && events[checkDate]!.isNotEmpty) {
      consecutive++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    // 计算饮水连续天数
    int waterStreak = 0;
    checkDate = DateTime(now.year, now.month, now.day);
    while (true) {
      final count = await SupabaseService.getWaterRecord(widget.user.id, checkDate);
      if (count >= 8) {
        waterStreak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    if (mounted) {
      setState(() {
        _consecutiveDays = consecutive;
        _waterStreak = waterStreak;
        _totalExerciseMinutes = totalExerciseMinutes;
      });
    }
  }

  Future<void> _loadWeeklyStats() async {
    final now = DateTime.now();
    int totalCalories = 0;
    double totalExerciseCalories = 0;
    int checkInDays = 0;

    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: i));
      
      final foodRecords = await SupabaseService.getFoodRecords(widget.user.id, day);
      if (foodRecords.isNotEmpty) {
        checkInDays++;
        for (final r in foodRecords) {
          totalCalories += r.calorie.toInt();
        }
      }

      final exercises = await SupabaseService.getExerciseRecords(widget.user.id, date: day);
      for (final e in exercises) {
        totalExerciseCalories += e.calorie;
      }
    }

    if (mounted) {
      setState(() {
        _weeklyCalories = totalCalories;
        _weeklyExerciseCalories = totalExerciseCalories;
        _weeklyCheckInDays = checkInDays;
        _loading = false;
      });
    }
  }

  double? get _currentWeight => _weightRecords.isNotEmpty ? _weightRecords.first.weight : null;
  double? get _initialWeight => widget.user.initialWeight;
  double? get _weightChange => (_currentWeight != null && _initialWeight != null)
      ? _initialWeight! - _currentWeight!
      : null;

  int get _level {
    if (_consecutiveDays < 7) return 1;
    if (_consecutiveDays < 14) return 2;
    if (_consecutiveDays < 30) return 3;
    if (_consecutiveDays < 60) return 4;
    return 5;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: ProfileAppBar(
        nickname: widget.user.nickname ?? '',
        consecutiveDays: _consecutiveDays,
        level: _level,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAllData,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  const SizedBox(height: 24),
                  // 本周数据概览
                  WeeklyStatsGrid(
                    totalCalories: _weeklyCalories,
                    exerciseCalories: _weeklyExerciseCalories,
                    currentWeight: _currentWeight,
                    weightChange: _weightChange,
                    checkInDays: _weeklyCheckInDays,
                  ),
                  const SizedBox(height: 24),
                  // 成就徽章
                  AchievementBadges(
                    consecutiveDays: _consecutiveDays,
                    waterStreak: _waterStreak,
                    totalExerciseMinutes: _totalExerciseMinutes,
                    weightChange: _weightChange,
                  ),
                  const SizedBox(height: 24),
                  // 体重趋势图
                  WeightTrendChart(weightRecords: _weightRecords),
                  const SizedBox(height: 24),
                  // 快捷设置
                  SettingsList(
                    onProfileTap: () => _showProfileDialog(),
                    onGoalsTap: () => _showGoalsDialog(),
                    onRemindersTap: () {},
                    onStatsTap: () {},
                    onExportTap: () {},
                    onHelpTap: () {},
                  ),
                  const SizedBox(height: 24),
                  // 退出登录
                  LogoutButton(
                    onTap: () async {
                      await SupabaseService.signOut();
                      if (mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  void _showProfileDialog() {
    final nicknameController = TextEditingController(text: widget.user.nickname);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑个人资料'),
        content: TextField(
          controller: nicknameController,
          decoration: const InputDecoration(
            labelText: '昵称',
            hintText: '请输入昵称',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              // 保存昵称到数据库
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showGoalsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('目标设置'),
        content: const Text('功能开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}