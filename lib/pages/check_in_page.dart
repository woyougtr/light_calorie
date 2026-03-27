import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../config/app_colors.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';

class CheckInPage extends StatefulWidget {
  final AppUser user;
  const CheckInPage({super.key, required this.user});
  @override
  State<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends State<CheckInPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<String>> _checkInEvents = {}; // 日期 -> 打卡类型列表
  int _consecutiveDays = 0;
  int _totalCheckIns = 0;

  // 饮水记录
  int _waterCount = 0;
  static const int _dailyWaterGoal = 8; // 每日8杯水目标

  // 运动记录
  List<ExerciseRecord> _todayExercises = [];
  double _todayExerciseCalorie = 0.0;

  // 选中日期的运动记录（用于日历选择其他日期时显示）
  List<ExerciseRecord> _selectedDayExercises = [];

  // 食物记录缓存（用于判断饮食打卡）
  Map<DateTime, List<FoodRecord>> _foodRecordsCache = {};

  // 安全检查运动列表是否为空
  bool get _hasExercises => _todayExercises.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadCheckInData(),
      _loadWaterData(),
      _loadExerciseData(),
    ]);
  }

  Future<void> _loadCheckInData() async {
    // 1. 加载打卡记录（用于日历显示）
    final checkIns = await SupabaseService.getCheckIns(widget.user.id);
    final Map<DateTime, List<String>> events = {};

    for (final checkIn in checkIns) {
      final date = DateTime(checkIn.date.year, checkIn.date.month, checkIn.date.day);
      events[date] = events[date] ?? [];
      events[date]!.add('打卡');
    }

    // 2. 加载食物记录（用于判断饮食打卡）
    // 获取最近30天的食物记录
    final now = DateTime.now();
    for (int i = 0; i < 30; i++) {
      final day = now.subtract(Duration(days: i));
      final records = await SupabaseService.getFoodRecords(widget.user.id, day);
      if (records.isNotEmpty) {
        final dateKey = DateTime(day.year, day.month, day.day);
        _foodRecordsCache[dateKey] = records;
        // 只要有食物记录就算饮食打卡
        events[dateKey] = events[dateKey] ?? [];
        if (!events[dateKey]!.contains('饮食')) {
          events[dateKey]!.add('饮食');
        }
      }
    }

    // 计算连续打卡天数（基于饮食打卡）
    int consecutive = 0;
    DateTime checkDate = DateTime(now.year, now.month, now.day);
    while (events.containsKey(checkDate)) {
      consecutive++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    if (mounted) {
      setState(() {
        _checkInEvents = events;
        _consecutiveDays = consecutive;
        _totalCheckIns = checkIns.length;
      });
    }
  }

  Future<void> _loadWaterData() async {
    // 从数据库加载今日饮水记录
    final count = await SupabaseService.getWaterRecord(widget.user.id, DateTime.now());
    if (mounted) {
      setState(() => _waterCount = count);
    }
  }

  Future<void> _saveWaterData() async {
    await SupabaseService.saveWaterRecord(widget.user.id, _waterCount, DateTime.now());
    if (mounted) {
      setState(() {}); // 刷新主页面 UI
    }
  }

  Future<void> _loadExerciseData() async {
    // 从数据库加载今日运动记录
    final exercises = await SupabaseService.getExerciseRecords(
      widget.user.id,
      date: DateTime.now(),
    );

    double total = 0.0;
    for (final r in exercises) {
      total += r.calorie;
    }

    if (mounted) {
      setState(() {
        _todayExercises = exercises;
        _todayExerciseCalorie = total;
      });
    }
  }

  // 加载选中日期的运动记录（用于日历选择其他日期时）
  Future<void> _loadSelectedDayExercise() async {
    if (_selectedDay == null) return;
    final exercises = await SupabaseService.getExerciseRecords(
      widget.user.id,
      date: _selectedDay!,
    );
    if (mounted) {
      setState(() => _selectedDayExercises = exercises);
    }
  }

  List<String> _getEventsForDay(DateTime day) {
    return _checkInEvents[DateTime(day.year, day.month, day.day)] ?? [];
  }

  // 检查选中日期是否有饮食打卡（基于食物记录）
  bool _hasFoodForDay(DateTime day) {
    final dateKey = DateTime(day.year, day.month, day.day);
    final records = _foodRecordsCache[dateKey];
    return records != null && records.isNotEmpty;
  }

  // 检查选中日期是否有运动记录
  bool _hasExerciseForDay(DateTime day) {
    // 如果是今天，使用 _todayExercises
    if (day.year == DateTime.now().year &&
        day.month == DateTime.now().month &&
        day.day == DateTime.now().day) {
      return _hasExercises;
    }
    // 其他日期需要查询
    return _selectedDayExercises.isNotEmpty;
  }

  // 获取选中日期的运动记录列表
  List<ExerciseRecord> _getExercisesForDay(DateTime day) {
    // 如果是今天，使用 _todayExercises
    if (day.year == DateTime.now().year &&
        day.month == DateTime.now().month &&
        day.day == DateTime.now().day) {
      return _todayExercises;
    }
    return _selectedDayExercises;
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
    // 加载选中日期的运动记录
    _loadSelectedDayExercise();
  }

  // 显示运动打卡弹窗
  void _showExerciseDialog() {
    ExerciseType selectedType = ExerciseType.running;
    int duration = 30;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text('记录运动', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              
              // 运动类型选择
              const Text('选择运动类型', style: TextStyle(fontSize: 14, color: AppColors.lightText)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ExerciseType.values.map((type) {
                  final isSelected = selectedType == type;
                  return ChoiceChip(
                    avatar: Text(type.icon, style: const TextStyle(fontSize: 16)),
                    label: Text(type.label),
                    selected: isSelected,
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    onSelected: (selected) {
                      if (selected) {
                        setDialogState(() => selectedType = type);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              
              // 时长选择
              const Text('运动时长', style: TextStyle(fontSize: 14, color: AppColors.lightText)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: duration > 5 ? () => setDialogState(() => duration -= 5) : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text('$duration 分钟', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    onPressed: duration < 180 ? () => setDialogState(() => duration += 5) : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Slider(
                value: duration.toDouble(),
                min: 5,
                max: 180,
                divisions: 35,
                label: '$duration分钟',
                onChanged: (value) => setDialogState(() => duration = value.round()),
              ),
              const SizedBox(height: 20),
              
              // 消耗预览
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.local_fire_department, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      '预计消耗 ${selectedType.calculateCalorie(duration).toStringAsFixed(0)} 大卡',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final record = ExerciseRecord(
                        id: '', // 空字符串，让数据库自动生成 UUID
                        userId: widget.user.id,
                        type: selectedType,
                        duration: duration,
                        calorie: selectedType.calculateCalorie(duration),
                        date: DateTime.now(),
                        createdAt: DateTime.now(),
                      );

                      // 保存到数据库
                      final (success, errMsg) = await SupabaseService.addExerciseRecord(record);

                      if (mounted) {
                        Navigator.pop(context);
                        if (success) {
                          _loadExerciseData();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('已记录 ${selectedType.label} $duration 分钟')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('保存失败: $errMsg')),
                          );
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('保存出错: $e')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('确认打卡'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isToday = _selectedDay != null &&
        _selectedDay!.year == DateTime.now().year &&
        _selectedDay!.month == DateTime.now().month &&
        _selectedDay!.day == DateTime.now().day;

    return Scaffold(
      appBar: AppBar(
        title: const Text('打卡'),
        actions: [
          TextButton.icon(
            onPressed: () {
              setState(() => _selectedDay = DateTime.now());
            },
            icon: const Icon(Icons.today, size: 18),
            label: const Text('今天', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadAllData();
        },
        child: ListView(padding: const EdgeInsets.all(16), children: [
          // 顶部统计行
          Row(
            children: [
              Expanded(child: _buildStatCard('🏆', '连续 $_consecutiveDays 天', AppColors.primary)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('📅', '累计 $_totalCheckIns 天', AppColors.secondary)),
            ],
          ),
          const SizedBox(height: 16),

          // 日历卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // 选中日期标题
                  if (_selectedDay != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${_selectedDay!.month}月${_selectedDay!.day}日',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          if (isToday) const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Chip(
                              label: Text('今天', style: TextStyle(fontSize: 10)),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                    ),
                  TableCalendar(
                    firstDay: DateTime.utc(2024, 1, 1),
                    lastDay: DateTime.utc(2026, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: CalendarFormat.month,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: _onDaySelected,
                    onPageChanged: (focusedDay) => setState(() => _focusedDay = focusedDay),
                    eventLoader: _getEventsForDay,
                    calendarStyle: CalendarStyle(
                      markersMaxCount: 1,
                      markerDecoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2x2 卡片网格
          Row(
            children: [
              Expanded(child: _buildModuleCard(
                icon: '📊',
                title: '打卡状态',
                value: isToday ? _getTodayCheckInStatus() : '--',
                subtitle: isToday ? '今日完成情况' : '选择日期查看',
                color: AppColors.secondary,
                onTap: () => _showCheckInDetailSheet(),
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildModuleCard(
                icon: '🏃',
                title: '运动',
                value: isToday ? '${_todayExerciseCalorie.toStringAsFixed(0)} kcal' : (_hasExerciseForDay(_selectedDay!) ? '${_getExercisesForDay(_selectedDay!).fold(0.0, (sum, e) => sum + e.calorie).toStringAsFixed(0)} kcal' : '--'),
                subtitle: isToday ? '${_todayExercises.length} 项运动' : '选择日期查看',
                color: AppColors.primary,
                onTap: _showExerciseDialog,
              )),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildModuleCard(
                icon: '💧',
                title: '饮水',
                value: isToday ? '$_waterCount/$_dailyWaterGoal 杯' : '--',
                subtitle: isToday ? (_waterCount >= _dailyWaterGoal ? '✅ 目标达成' : '再喝${_dailyWaterGoal - _waterCount}杯') : '选择日期查看',
                color: Colors.blue,
                onTap: () => _showWaterSheet(),
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildModuleCard(
                icon: '📈',
                title: '本周',
                value: '${_getWeekCompletionRate()}%',
                subtitle: '习惯完成率',
                color: AppColors.accent,
                onTap: () => _showWeekStatsSheet(),
              )),
            ],
          ),
          const SizedBox(height: 24),

          // 选中日期的打卡详情（如果有记录）
          if (_selectedDay != null && (isToday || _getEventsForDay(_selectedDay!).isNotEmpty || _hasExerciseForDay(_selectedDay!)))
            _buildSelectedDayDetailCard(isToday),
        ]),
      ),
    );
  }

  // 统计卡片
  Widget _buildStatCard(String emoji, String text, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  // 模块卡片
  Widget _buildModuleCard({
    required String icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(icon, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(title, style: const TextStyle(fontSize: 14, color: AppColors.lightText)),
                ],
              ),
              const SizedBox(height: 12),
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.lightText)),
            ],
          ),
        ),
      ),
    );
  }

  // 获取今日打卡状态文字
  String _getTodayCheckInStatus() {
    final today = DateTime.now();
    final hasFood = _checkInEvents.containsKey(DateTime(today.year, today.month, today.day));
    final hasExercise = _hasExercises;
    if (hasFood && hasExercise) return '4/4 完成';
    if (hasFood || hasExercise) return '2/4 进行中';
    return '0/4 未开始';
  }

  // 获取本周完成率
  int _getWeekCompletionRate() {
    final now = DateTime.now();
    int total = 0;
    int completed = 0;
    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: i));
      final key = DateTime(day.year, day.month, day.day);
      total++;
      if (_checkInEvents.containsKey(key)) completed++;
    }
    if (total == 0) return 0;
    return ((completed / total) * 100).round();
  }

  // 选中日期详情卡片
  Widget _buildSelectedDayDetailCard(bool isToday) {
    final exercises = isToday ? _todayExercises : _getExercisesForDay(_selectedDay!);
    final hasCheckIn = isToday || _getEventsForDay(_selectedDay!).isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_selectedDay!.month}月${_selectedDay!.day}日 ${_getWeekdayName(_selectedDay!.weekday)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (hasCheckIn)
                  const Chip(
                    label: Text('已打卡', style: TextStyle(fontSize: 10, color: Colors.white)),
                    backgroundColor: AppColors.success,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (isToday && exercises.isNotEmpty) ...[
              const Text('运动记录', style: TextStyle(fontSize: 12, color: AppColors.lightText)),
              const SizedBox(height: 8),
              ...exercises.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Text(e.type.icon, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(e.type.label),
                    const Spacer(),
                    Text('${e.duration}分钟', style: const TextStyle(color: AppColors.lightText)),
                    const SizedBox(width: 8),
                    Text('${e.calorie.toStringAsFixed(0)}kcal', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ],
                ),
              )),
            ] else if (!isToday && exercises.isNotEmpty) ...[
              const Text('运动记录', style: TextStyle(fontSize: 12, color: AppColors.lightText)),
              const SizedBox(height: 8),
              ...exercises.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Text(e.type.icon, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(e.type.label),
                    const Spacer(),
                    Text('${e.duration}分钟', style: const TextStyle(color: AppColors.lightText)),
                    const SizedBox(width: 8),
                    Text('${e.calorie.toStringAsFixed(0)}kcal', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ],
                ),
              )),
            ] else ...[
              Center(
                child: Column(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey[300], size: 32),
                    const SizedBox(height: 8),
                    Text('当日暂无打卡记录', style: TextStyle(color: Colors.grey[500])),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getWeekdayName(int weekday) {
    const names = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return names[weekday];
  }

  // 显示打卡详情弹窗
  void _showCheckInDetailSheet() {
    final today = DateTime.now();
    final hasFood = _checkInEvents.containsKey(DateTime(today.year, today.month, today.day));
    final hasExercise = _hasExercises;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('今日打卡', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCheckItem('🍽️', '饮食', hasFood),
                _buildCheckItem('🏃', '运动', hasExercise),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              hasFood && hasExercise ? '🎉 今日目标全部完成！' : '继续加油 💪',
              style: TextStyle(fontSize: 16, color: hasFood && hasExercise ? AppColors.success : AppColors.lightText),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckItem(String emoji, String label, bool completed) {
    return Column(
      children: [
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
            color: completed ? AppColors.success.withValues(alpha: 0.1) : Colors.grey[100],
            shape: BoxShape.circle,
            border: Border.all(color: completed ? AppColors.success : Colors.grey[300]!, width: 2),
          ),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 28))),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: completed ? AppColors.success : AppColors.lightText)),
        const SizedBox(height: 4),
        Icon(completed ? Icons.check_circle : Icons.radio_button_unchecked,
          color: completed ? AppColors.success : Colors.grey, size: 20),
      ],
    );
  }

  // 显示饮水记录弹窗
  void _showWaterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text('💧 饮水记录', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('目标: $_dailyWaterGoal 杯', style: TextStyle(color: AppColors.lightText)),
              const SizedBox(height: 20),
              // 水杯进度
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: List.generate(_dailyWaterGoal, (index) {
                  final isFilled = index < _waterCount;
                  return GestureDetector(
                    onTap: () {
                      setSheetState(() {
                        _waterCount = index + 1 > _waterCount ? index : index + 1;
                      });
                      _saveWaterData();
                    },
                    child: Container(
                      width: 48, height: 56,
                      decoration: BoxDecoration(
                        color: isFilled ? Colors.blue.withValues(alpha: 0.2) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isFilled ? Colors.blue : Colors.grey[300]!, width: 2),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.water_drop, color: isFilled ? Colors.blue : Colors.grey[400], size: 24),
                          Text('${index + 1}', style: TextStyle(fontSize: 10, color: isFilled ? Colors.blue : Colors.grey[400])),
                        ],
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _waterCount > 0 ? () {
                      setSheetState(() => _waterCount--);
                      _saveWaterData();
                    } : null,
                    icon: const Icon(Icons.remove),
                    label: const Text('减少'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _waterCount < _dailyWaterGoal ? () {
                      setSheetState(() => _waterCount++);
                      _saveWaterData();
                    } : null,
                    icon: const Icon(Icons.add),
                    label: const Text('添加'),
                  ),
                ],
              ),
              if (_waterCount >= _dailyWaterGoal) ...[
                const SizedBox(height: 16),
                const Text('🎉 今日饮水目标达成！', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // 显示周统计弹窗
  void _showWeekStatsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('📈 本周统计', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeekStatItem('打卡天数', '${_getWeekCheckInDays()}/7', AppColors.primary),
                _buildWeekStatItem('完成率', '${_getWeekCompletionRate()}%', AppColors.secondary),
              ],
            ),
            const SizedBox(height: 20),
            // 本周打卡日历
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (index) {
                final day = DateTime.now().subtract(Duration(days: 6 - index));
                final checked = _checkInEvents.containsKey(DateTime(day.year, day.month, day.day));
                return Column(
                  children: [
                    Text(_getWeekdayName(day.weekday), style: const TextStyle(fontSize: 12, color: AppColors.lightText)),
                    const SizedBox(height: 4),
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: checked ? AppColors.success : Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Center(child: Text('${day.day}', style: TextStyle(fontSize: 12, color: checked ? Colors.white : Colors.grey[600]))),
                    ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.lightText)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  int _getWeekCheckInDays() {
    final now = DateTime.now();
    int count = 0;
    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: i));
      if (_checkInEvents.containsKey(DateTime(day.year, day.month, day.day))) count++;
    }
    return count;
  }
}
