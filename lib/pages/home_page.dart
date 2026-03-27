import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/app_colors.dart';
import '../config/app_theme.dart';
import '../data/foods.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';
import '../widgets/home/calorie_card.dart';
import '../widgets/home/health_dashboard.dart';
import '../widgets/home/meal_buttons.dart';
import '../widgets/home/smart_suggestions.dart';
import '../widgets/home/today_records_list.dart';
import 'check_in_page.dart';
import 'record_page.dart';

class HomePage extends StatefulWidget {
  final AppUser user;
  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 数据状态
  List<FoodRecord> _todayRecords = [];
  List<WeightRecord> _weightRecords = [];
  int _waterCount = 0;
  List<ExerciseRecord> _todayExercises = [];
  double _todayExerciseCalorie = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    loadTodayData();
  }

  /// 加载今日数据
  Future<void> loadTodayData() async {
    setState(() => _loading = true);

    final now = DateTime.now();

    final results = await Future.wait([
      SupabaseService.getFoodRecords(widget.user.id, now),
      SupabaseService.getWeightRecords(widget.user.id, limit: 1),
      SupabaseService.getWaterRecord(widget.user.id, now),
      SupabaseService.getExerciseRecords(widget.user.id, date: now),
    ]);

    final foodRecords = results[0] as List<FoodRecord>;
    final weightRecords = results[1] as List<WeightRecord>;
    final waterCount = results[2] as int;
    final exercises = results[3] as List<ExerciseRecord>;

    double totalExerciseCalorie = 0;
    for (final e in exercises) {
      totalExerciseCalorie += e.calorie;
    }

    if (mounted) {
      setState(() {
        _todayRecords = foodRecords;
        _weightRecords = weightRecords;
        _waterCount = waterCount;
        _todayExercises = exercises;
        _todayExerciseCalorie = totalExerciseCalorie;
        _loading = false;
      });
    }
  }

  /// 获取当前体重
  double? get _currentWeight =>
      _weightRecords.isNotEmpty ? _weightRecords.first.weight : null;

  /// 获取总热量
  int get _totalCalories =>
      _todayRecords.fold(0, (sum, r) => sum + r.calorie.toInt());

  /// 获取餐次状态
  Map<MealType, bool> get _mealStatus {
    final recordedMeals = _todayRecords.map((r) => r.mealType).toSet();
    return {
      MealType.breakfast: recordedMeals.contains(MealType.breakfast),
      MealType.lunch: recordedMeals.contains(MealType.lunch),
      MealType.dinner: recordedMeals.contains(MealType.dinner),
      MealType.snack: recordedMeals.contains(MealType.snack),
    };
  }

  /// 获取今日运动分钟数
  int get _exerciseMinutes =>
      _todayExercises.fold(0, (sum, e) => sum + e.duration);

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEEE, M月d日', 'zh_CN').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadTodayData,
              child: CustomScrollView(
                slivers: [
                  // 顶部 App Bar
                  SliverAppBar(
                    floating: true,
                    backgroundColor: AppTheme.background,
                    elevation: 0,
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const Text(
                          '轻卡',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        onPressed: () {},
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primary.withOpacity(0.2),
                          child: Text(
                            widget.user.nickname?.substring(0, 1) ?? '👤',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // 内容区域
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        // 热量概览卡片
                        CalorieCard(
                          consumed: _totalCalories,
                          goal: widget.user.dailyCalorieGoal,
                          onTap: () => _navigateToRecordPage(),
                        ),

                        const SizedBox(height: 24),

                        // 快捷餐次按钮
                        MealButtons(
                          mealStatus: _mealStatus,
                          onMealTap: _onMealTap,
                        ),

                        const SizedBox(height: 24),

                        // 健康仪表盘
                        HealthDashboard(
                          waterCount: _waterCount,
                          waterGoal: 8,
                          onWaterTap: _showWaterDialog,
                          exerciseMinutes: _exerciseMinutes,
                          exerciseCalorie: _todayExerciseCalorie,
                          onExerciseTap: _showExerciseDialog,
                          currentWeight: _currentWeight,
                          onWeightTap: _showWeightDialog,
                        ),

                        const SizedBox(height: 24),

                        // 智能建议
                        SmartSuggestions(
                          consumed: _totalCalories,
                          goal: widget.user.dailyCalorieGoal,
                          waterCount: _waterCount,
                          waterGoal: 8,
                          exerciseMinutes: _exerciseMinutes,
                          onAddExercise: _showExerciseDialog,
                        ),

                        const SizedBox(height: 24),

                        // 今日记录列表
                        TodayRecordsList(
                          records: _todayRecords,
                          onViewAll: () => _navigateToRecordPage(),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// 点击餐次按钮
  void _onMealTap(MealType mealType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecordPage(
          user: widget.user,
          initialMealType: mealType,
        ),
      ),
    ).then((_) => loadTodayData());
  }

  /// 跳转到记录页
  void _navigateToRecordPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecordPage(user: widget.user),
      ),
    ).then((_) => loadTodayData());
  }

  /// 显示饮水弹窗
  void _showWaterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _WaterDialog(
        initialCount: _waterCount,
        onSave: (count) async {
          await SupabaseService.saveWaterRecord(
            widget.user.id,
            count,
            DateTime.now(),
          );
          loadTodayData();
        },
      ),
    );
  }

  /// 显示运动弹窗
  void _showExerciseDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ExerciseDialog(
        onSave: (type, duration) async {
          final record = ExerciseRecord(
            id: '',
            userId: widget.user.id,
            type: type,
            duration: duration,
            calorie: type.calculateCalorie(duration),
            date: DateTime.now(),
            createdAt: DateTime.now(),
          );
          await SupabaseService.addExerciseRecord(record);
          loadTodayData();
        },
      ),
    );
  }

  /// 显示体重弹窗
  void _showWeightDialog() {
    final controller =
        TextEditingController(text: _currentWeight?.toStringAsFixed(1) ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('记录体重'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '体重 (kg)',
            suffixText: 'kg',
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
              final weight = double.tryParse(controller.text);
              if (weight != null && weight > 0 && weight < 300) {
                final record = WeightRecord(
                  id: '',
                  oderId: widget.user.id,
                  weight: weight,
                  date: DateTime.now(),
                  createdAt: DateTime.now(),
                );
                await SupabaseService.addWeightRecord(record);
                if (mounted) {
                  Navigator.pop(context);
                  loadTodayData();
                }
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}

/// 饮水记录弹窗
class _WaterDialog extends StatefulWidget {
  final int initialCount;
  final Function(int) onSave;

  const _WaterDialog({
    required this.initialCount,
    required this.onSave,
  });

  @override
  State<_WaterDialog> createState() => _WaterDialogState();
}

class _WaterDialogState extends State<_WaterDialog> {
  late int _count;

  @override
  void initState() {
    super.initState();
    _count = widget.initialCount;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '💧 饮水记录',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '目标: 8杯',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          // 水杯显示
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: List.generate(8, (index) {
              final isFilled = index < _count;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _count = index + 1;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isFilled
                        ? AppTheme.info.withOpacity(0.2)
                        : AppTheme.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isFilled ? AppTheme.info : AppTheme.divider,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.water_drop,
                        color: isFilled ? AppTheme.info : AppTheme.textHint,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 10,
                          color: isFilled
                              ? AppTheme.info
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 32),
          // 快捷按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildQuickButton(Icons.remove, () {
                if (_count > 0) setState(() => _count--);
              }),
              const SizedBox(width: 24),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$_count 杯',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.info,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              _buildQuickButton(Icons.add, () {
                if (_count < 8) setState(() => _count++);
              }),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onSave(_count);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('保存记录'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: AppTheme.background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.textSecondary),
        ),
      ),
    );
  }
}

/// 运动记录弹窗
class _ExerciseDialog extends StatefulWidget {
  final Function(ExerciseType, int) onSave;

  const _ExerciseDialog({required this.onSave});

  @override
  State<_ExerciseDialog> createState() => _ExerciseDialogState();
}

class _ExerciseDialogState extends State<_ExerciseDialog> {
  ExerciseType _selectedType = ExerciseType.running;
  int _duration = 30;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '🏃 记录运动',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          // 运动类型选择
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: ExerciseType.values.length,
              itemBuilder: (context, index) {
                final type = ExerciseType.values[index];
                final isSelected = type == _selectedType;
                return GestureDetector(
                  onTap: () => setState(() => _selectedType = type),
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.secondary.withOpacity(0.2)
                          : AppTheme.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.secondary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          type.icon,
                          style: const TextStyle(fontSize: 32),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          type.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected
                                ? AppColors.secondary
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          // 时长选择
          Text(
            '运动时长: $_duration 分钟',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Slider(
            value: _duration.toDouble(),
            min: 5,
            max: 120,
            divisions: 23,
            label: '$_duration 分钟',
            onChanged: (value) {
              setState(() {
                _duration = value.toInt();
              });
            },
          ),
          const SizedBox(height: 16),
          // 消耗卡路里预览
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '预计消耗 ${_selectedType.calculateCalorie(_duration).toInt()} 大卡',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onSave(_selectedType, _duration);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('保存记录'),
            ),
          ),
        ],
      ),
    );
  }
}