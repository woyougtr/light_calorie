import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../config/app_theme.dart';
import '../data/foods.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';
import '../widgets/record/timeline_view.dart';

class RecordPage extends StatefulWidget {
  final AppUser user;
  final MealType? initialMealType;

  const RecordPage({
    super.key,
    required this.user,
    this.initialMealType,
  });

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  List<FoodRecord> _todayRecords = [];
  bool _loading = true;
  DateTime _currentDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadRecordsForDate(_currentDate);
  }

  Future<void> _loadRecordsForDate(DateTime date) async {
    final records = await SupabaseService.getFoodRecords(widget.user.id, date);
    if (mounted) {
      setState(() {
        _todayRecords = records;
        _loading = false;
      });
    }
  }

  Future<void> _loadTodayRecords() async {
    await _loadRecordsForDate(_currentDate);
  }

  Map<MealType, List<FoodRecord>> get _recordsByMeal {
    final Map<MealType, List<FoodRecord>> result = {};
    for (final r in _todayRecords) {
      result.putIfAbsent(r.mealType, () => []).add(r);
    }
    return result;
  }

  int get _totalCalories =>
      _todayRecords.fold(0, (sum, r) => sum + r.calorie.toInt());

  int get _remainingCalories =>
      widget.user.dailyCalorieGoal - _totalCalories;

  @override
  Widget build(BuildContext context) {
    final isToday = _isToday(_currentDate);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('饮食记录'),
        actions: [
          TextButton.icon(
            onPressed: () => _selectDate(),
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(
              isToday ? '今天' : '${_currentDate.month}/${_currentDate.day}',
              style: const TextStyle(fontSize: 14),
            ),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadTodayRecords,
                    child: TimelineView(
                      recordsByMeal: _recordsByMeal,
                      onAddMeal: _showAddFoodSheet,
                      onDelete: _deleteRecord,
                    ),
                  ),
                ),
                // 底部总计栏
                _buildBottomSummary(),
              ],
            ),
    );
  }

  Widget _buildBottomSummary() {
    final progress = (_totalCalories / widget.user.dailyCalorieGoal).clamp(0.0, 1.0);
    final isOver = _totalCalories > widget.user.dailyCalorieGoal;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 拖动指示条
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // 热量数字
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$_totalCalories',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isOver ? AppTheme.danger : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '/ ${widget.user.dailyCalorieGoal}',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'kcal',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 进度条
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: AppTheme.divider,
                valueColor: AlwaysStoppedAnimation(
                  isOver ? AppTheme.danger : AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // 剩余/超标提示
            Text(
              isOver
                  ? '已超标 ${-_remainingCalories} kcal'
                  : '还可摄入 $_remainingCalories kcal',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isOver ? AppTheme.danger : AppTheme.success,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _currentDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        _currentDate = pickedDate;
        _loading = true;
      });
      await _loadRecordsForDate(pickedDate);
    }
  }

  void _showAddFoodSheet(MealType mealType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddFoodSheet(
        mealType: mealType,
        onAdd: _addFoodRecord,
      ),
    );
  }

  Future<void> _addFoodRecord(Food food, double grams, MealType mealType) async {
    final record = FoodRecord(
      id: '',
      oderId: widget.user.id,
      foodId: food.id,
      foodName: food.name,
      grams: grams,
      calorie: food.calorieFor(grams),
      mealType: mealType,
      createdAt: DateTime.now(),
    );

    final (success, _) = await SupabaseService.addFoodRecord(record);
    if (success && mounted) {
      _loadTodayRecords();
    }
  }

  Future<void> _deleteRecord(FoodRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 ${record.foodName} 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await SupabaseService.deleteFoodRecord(record.id);
      _loadTodayRecords();
    }
  }
}

/// 简化版添加食物弹窗
class _AddFoodSheet extends StatefulWidget {
  final MealType mealType;
  final Function(Food food, double grams, MealType mealType) onAdd;

  const _AddFoodSheet({
    required this.mealType,
    required this.onAdd,
  });

  @override
  State<_AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends State<_AddFoodSheet> {
  late MealType _selectedMealType;
  String _searchKeyword = '';

  @override
  void initState() {
    super.initState();
    _selectedMealType = widget.mealType;
  }

  List<Food> get _filteredFoods {
    if (_searchKeyword.isEmpty) return [];
    return searchFoods(_searchKeyword);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // 拖动条
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          // 标题
          Text(
            '添加${_selectedMealType.label}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          // 餐次切换
          _buildMealSwitcher(),
          const SizedBox(height: 20),
          // 搜索框
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: '搜索食物...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppTheme.background,
              ),
              onChanged: (v) => setState(() => _searchKeyword = v),
            ),
          ),
          const SizedBox(height: 20),
          // 内容区域
          Expanded(
            child: _searchKeyword.isNotEmpty
                ? _buildSearchResults()
                : _buildQuickAddGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildMealSwitcher() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: MealType.values.map((meal) {
          final isSelected = _selectedMealType == meal;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedMealType = meal),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppTheme.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  meal.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_filteredFoods.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: AppTheme.textHint),
            const SizedBox(height: 12),
            Text(
              '未找到食物',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _filteredFoods.length,
      itemBuilder: (context, index) {
        final food = _filteredFoods[index];
        return ListTile(
          leading: Text(food.icon, style: const TextStyle(fontSize: 24)),
          title: Text(food.name),
          subtitle: Text('${food.caloriePer100g.toInt()} kcal/100g'),
          onTap: () => _showQuickAddDialog(food),
        );
      },
    );
  }

  Widget _buildQuickAddGrid() {
    final quickFoods = [
      foodDatabase.firstWhere((f) => f.id == 'f002', orElse: () => foodDatabase[0]),
      foodDatabase.firstWhere((f) => f.id == 'f201', orElse: () => foodDatabase[1]),
      foodDatabase.firstWhere((f) => f.id == 'f601', orElse: () => foodDatabase[2]),
      foodDatabase.firstWhere((f) => f.id == 'f005', orElse: () => foodDatabase[3]),
      foodDatabase.firstWhere((f) => f.id == 'f501', orElse: () => foodDatabase[4]),
      foodDatabase.firstWhere((f) => f.id == 'f401', orElse: () => foodDatabase[5]),
    ];

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: quickFoods.length,
      itemBuilder: (context, index) {
        final food = quickFoods[index];
        return InkWell(
          onTap: () => _showQuickAddDialog(food),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(food.icon, style: const TextStyle(fontSize: 32)),
                const SizedBox(height: 4),
                Text(
                  food.name,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${food.caloriePer100g.toInt()}kcal',
                  style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showQuickAddDialog(Food food) {
    final controller = TextEditingController(text: '100');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('添加 ${food.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${food.icon} ${food.name}'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '重量 (g)',
                suffixText: 'g',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [50, 100, 150, 200].map((g) {
                return ActionChip(
                  label: Text('${g}g'),
                  onPressed: () => controller.text = g.toString(),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final grams = double.tryParse(controller.text) ?? 100;
              widget.onAdd(food, grams, _selectedMealType);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}
