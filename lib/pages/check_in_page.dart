import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../config/app_theme.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';
import '../widgets/checkin/checkin_calendar.dart';
import '../widgets/checkin/consecutive_card.dart';
import '../widgets/checkin/today_progress.dart';

class CheckInPage extends StatefulWidget {
  final AppUser user;
  const CheckInPage({super.key, required this.user});

  @override
  State<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends State<CheckInPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<String>> _checkInEvents = {};
  int _consecutiveDays = 0;
  int _bestRecord = 28; // 历史最佳，可以从数据库读取

  // 今日数据
  Map<String, bool> _dietStatus = {
    'breakfast': false,
    'lunch': false,
    'dinner': false,
  };
  int _waterCount = 0;
  static const int _waterGoal = 8;
  List<ExerciseRecord> _todayExercises = [];
  double? _currentWeight;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadCheckInData(),
      _loadTodayData(),
    ]);
  }

  Future<void> _loadCheckInData() async {
    final now = DateTime.now();
    final events = <DateTime, List<String>>{};

    // 获取最近30天的记录
    for (int i = 0; i < 30; i++) {
      final day = now.subtract(Duration(days: i));
      final dateKey = DateTime(day.year, day.month, day.day);

      // 检查饮食
      final foodRecords = await SupabaseService.getFoodRecords(widget.user.id, day);
      if (foodRecords.isNotEmpty) {
        events[dateKey] = events[dateKey] ?? [];
        events[dateKey]!.add('饮食');
      }

      // 检查饮水
      final waterCount = await SupabaseService.getWaterRecord(widget.user.id, day);
      if (waterCount >= _waterGoal) {
        events[dateKey] = events[dateKey] ?? [];
        events[dateKey]!.add('饮水');
      }

      // 检查运动
      final exercises = await SupabaseService.getExerciseRecords(widget.user.id, date: day);
      if (exercises.isNotEmpty) {
        events[dateKey] = events[dateKey] ?? [];
        events[dateKey]!.add('运动');
      }
    }

    // 计算连续打卡天数
    int consecutive = 0;
    DateTime checkDate = DateTime(now.year, now.month, now.day);
    while (events.containsKey(checkDate) && events[checkDate]!.isNotEmpty) {
      consecutive++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    if (mounted) {
      setState(() {
        _checkInEvents = events;
        _consecutiveDays = consecutive;
      });
    }
  }

  Future<void> _loadTodayData() async {
    final now = DateTime.now();

    final results = await Future.wait([
      SupabaseService.getFoodRecords(widget.user.id, now),
      SupabaseService.getWaterRecord(widget.user.id, now),
      SupabaseService.getExerciseRecords(widget.user.id, date: now),
      SupabaseService.getWeightRecords(widget.user.id, limit: 1),
    ]);

    final foodRecords = results[0] as List<FoodRecord>;
    final waterCount = results[1] as int;
    final exercises = results[2] as List<ExerciseRecord>;
    final weightRecords = results[3] as List<WeightRecord>;

    if (mounted) {
      setState(() {
        _dietStatus = {
          'breakfast': foodRecords.any((r) => r.mealType == MealType.breakfast),
          'lunch': foodRecords.any((r) => r.mealType == MealType.lunch),
          'dinner': foodRecords.any((r) => r.mealType == MealType.dinner),
        };
        _waterCount = waterCount;
        _todayExercises = exercises;
        _currentWeight = weightRecords.isNotEmpty ? weightRecords.first.weight : null;
        _loading = false;
      });
    }
  }

  int get _completedCount {
    int count = 0;
    if (_dietStatus['breakfast']! && _dietStatus['lunch']! && _dietStatus['dinner']!) count++;
    if (_waterCount >= _waterGoal) count++;
    if (_todayExercises.isNotEmpty) count++;
    if (_currentWeight != null) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('打卡日历'),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAllData,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  // 日历
                  CheckInCalendar(
                    focusedDay: _focusedDay,
                    selectedDay: _selectedDay,
                    events: _checkInEvents,
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onPageChanged: (focusedDay) {
                      setState(() {
                        _focusedDay = focusedDay;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  // 图例
                  const CalendarLegend(),
                  const SizedBox(height: 24),
                  // 连续打卡卡片
                  ConsecutiveCard(
                    consecutiveDays: _consecutiveDays,
                    bestRecord: _bestRecord,
                    improvement: _consecutiveDays > 7 ? 2 : 0,
                  ),
                  const SizedBox(height: 24),
                  // 今日进度
                  TodayProgress(
                    progress: _completedCount / 4,
                    completedCount: _completedCount,
                    totalCount: 4,
                  ),
                  const SizedBox(height: 24),
                  // 今日任务清单
                  TodayChecklist(
                    dietStatus: _dietStatus,
                    waterCount: _waterCount,
                    waterGoal: _waterGoal,
                    exercises: _todayExercises,
                    currentWeight: _currentWeight,
                    onDietTap: () => _navigateToRecord(),
                    onWaterTap: () => _showWaterDialog(),
                    onExerciseTap: () => _showExerciseDialog(),
                    onWeightTap: () => _showWeightDialog(),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  void _navigateToRecord() {
    // 跳转到记录页
    Navigator.pushNamed(context, '/record');
  }

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
          _loadTodayData();
        },
      ),
    );
  }

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
          _loadTodayData();
        },
      ),
    );
  }

  void _showWeightDialog() {
    final controller = TextEditingController(
      text: _currentWeight?.toStringAsFixed(1) ?? '',
    );

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
                  _loadTodayData();
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

// 饮水弹窗
class _WaterDialog extends StatefulWidget {
  final int initialCount;
  final Function(int) onSave;

  const _WaterDialog({required this.initialCount, required this.onSave});

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
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: List.generate(8, (index) {
              final isFilled = index < _count;
              return GestureDetector(
                onTap: () => setState(() => _count = index + 1),
                child: Container(
                  width: 48,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isFilled
                        ? const Color(0xFF2196F3).withValues(alpha: 0.2)
                        : AppTheme.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isFilled ? const Color(0xFF2196F3) : AppTheme.divider,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.water_drop,
                        color: isFilled ? const Color(0xFF2196F3) : AppTheme.textHint,
                        size: 24,
                      ),
                      Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 10,
                          color: isFilled ? const Color(0xFF2196F3) : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: _count > 0 ? () => setState(() => _count--) : null,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$_count 杯',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2196F3),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _count < 8 ? () => setState(() => _count++) : null,
              ),
            ],
          ),
          const SizedBox(height: 24),
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
}

// 运动弹窗
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
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
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
                          ? AppColors.secondary.withValues(alpha: 0.2)
                          : AppTheme.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppColors.secondary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(type.icon, style: const TextStyle(fontSize: 32)),
                        const SizedBox(height: 4),
                        Text(
                          type.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected ? AppColors.secondary : AppTheme.textSecondary,
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
          Text(
            '运动时长: $_duration 分钟',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Slider(
            value: _duration.toDouble(),
            min: 5,
            max: 120,
            divisions: 23,
            label: '$_duration 分钟',
            onChanged: (value) => setState(() => _duration = value.toInt()),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_fire_department, color: AppColors.primary, size: 20),
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