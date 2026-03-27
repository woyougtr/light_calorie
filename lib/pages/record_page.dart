import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../data/foods.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';

class RecordPage extends StatefulWidget {
  final AppUser user;
  const RecordPage({super.key, required this.user});
  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  List<FoodRecord> _todayRecords = [];
  bool _loading = true;
  String _searchKeyword = '';
  MealType _selectedMealType = MealType.breakfast;

  DateTime _selectedDate = DateTime.now();
  DateTime _currentDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _recentFoods = <Food>[];
    _loadRecordsForDate(_currentDate);
  }

  Future<void> _loadRecordsForDate(DateTime date) async {
    final records = await SupabaseService.getFoodRecords(widget.user.id, date);
    if (mounted) setState(() { _todayRecords = records; _loading = false; });
  }

  Future<void> _loadTodayRecords() async {
    await _loadRecordsForDate(_currentDate);
  }

  /// 按餐次分组记录
  Map<MealType, List<FoodRecord>> get _recordsByMeal {
    final Map<MealType, List<FoodRecord>> result = {};
    for (final r in _todayRecords) {
      result.putIfAbsent(r.mealType, () => []).add(r);
    }
    return result;
  }

  /// 搜索食物
  List<Food> get _filteredFoods {
    if (_searchKeyword.isEmpty) return foodDatabase.toList();
    return searchFoods(_searchKeyword);
  }
  
  /// 按分类获取食物
  Map<String, List<Food>> get _foodsByCategory {
    if (_searchKeyword.isNotEmpty) return {};
    return getFoodsByCategory();
  }

  @override
  Widget build(BuildContext context) {
    final recordsByMeal = _recordsByMeal;
    final totalCalorie = _todayRecords.fold(0.0, (sum, r) => sum + r.calorie);

    final isToday = _currentDate.year == DateTime.now().year &&
                    _currentDate.month == DateTime.now().month &&
                    _currentDate.day == DateTime.now().day;

    return Scaffold(
      appBar: AppBar(
        title: const Text('饮食记录'),
        actions: [
          TextButton.icon(
            onPressed: () async {
                                                              final pickedDate = await showDatePicker(
                                                              context: context,
                                                              initialDate: _currentDate,
                                                              firstDate: DateTime(2024),
                                                              lastDate: DateTime.now(),
                                                            );
                                                            if (pickedDate != null) {
                                                              setState(() => _currentDate = pickedDate);
                                                              _loadRecordsForDate(pickedDate);
                                                            }
                                                          },
                                                          icon: const Icon(Icons.calendar_today, size: 18),
                                                          label: Text(
                                                            isToday ? '今天' : '${_currentDate.month}/${_currentDate.day}',              style: const TextStyle(fontSize: 14),
            ),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTodayRecords,
              child: ListView(padding: const EdgeInsets.all(16), children: [
                // 按餐次分组显示
                for (final mealType in [MealType.breakfast, MealType.lunch, MealType.dinner, MealType.snack]) ...[
                  _buildMealSection(mealType, recordsByMeal[mealType] ?? []),
                  const SizedBox(height: 12),
                ],
                // 今日总计
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('今日总计：', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      Text('${totalCalorie.toInt()} kcal', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                ),
              ]),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddFoodSheet(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildMealSection(MealType mealType, List<FoodRecord> records) {
    final mealCalorie = records.fold(0.0, (sum, r) => sum + r.calorie);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${mealType.icon} ${mealType.label}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                if (records.isNotEmpty)
                  Text('${mealCalorie.toInt()} kcal', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ],
            ),
            if (records.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: TextButton.icon(
                    onPressed: () {
                      _selectedMealType = mealType;
                      _showAddFoodSheet();
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: Text('添加${mealType.label}'),
                  ),
                ),
              )
            else
              ...records.map((r) {
                // 根据 foodId 查找食物图标
                final food = foodDatabase.where((f) => f.id == r.foodId).firstOrNull;
                final icon = food?.icon ?? mealType.icon;
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  leading: Text(icon, style: const TextStyle(fontSize: 18)),
                  title: Text(r.foodName),
                  subtitle: Text('${r.grams.toInt()}g'),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('${r.calorie.toInt()} kcal', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                      onPressed: () => _deleteRecord(r.id),
                    ),
                  ]),
                );
              }),
          ],
        ),
      ),
    );
  }

  // 最近添加的食物记录（用于快捷选择）- 静态变量避免 web 构建问题
  static List<Food> _recentFoods = [];

  void _showAddFoodSheet() {
    _searchKeyword = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              // 拖动条
              const SizedBox(height: 8),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              // 标题
              const Text('添加食物', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              // 搜索框
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: '搜索食物...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchKeyword.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setSheetState(() => _searchKeyword = ''))
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onChanged: (v) => setSheetState(() => _searchKeyword = v),
                ),
              ),
              const SizedBox(height: 16),
              // 餐次选择（横向滚动）
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('${_selectedMealType.icon} ${_selectedMealType.label}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [MealType.breakfast, MealType.lunch, MealType.dinner, MealType.snack].map((meal) {
                            final isSelected = _selectedMealType == meal;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ActionChip(
                                avatar: Text(meal.icon, style: const TextStyle(fontSize: 14)),
                                label: Text(meal.label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87)),
                                backgroundColor: isSelected ? AppColors.primary : Colors.grey[200],
                                onPressed: () => setSheetState(() => _selectedMealType = meal),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // 搜索模式：直接显示结果
              if (_searchKeyword.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredFoods.length,
                    itemBuilder: (context, index) => _buildFoodItemWithQuickAdd(_filteredFoods[index]),
                  ),
                )
              else
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      // 最近使用
                      if (_recentFoods.isNotEmpty) ...[
                        const Text('最近使用', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.lightText)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _recentFoods.take(8).map((food) => _buildQuickFoodChip(food)).toList(),
                        ),
                        const SizedBox(height: 20),
                      ],
                      // 快捷添加（高频食物）
                      const Text('快捷添加', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.lightText)),
                      const SizedBox(height: 8),
                      _buildQuickAddGrid(),
                      const SizedBox(height: 20),
                      // 分类浏览
                      const Text('分类浏览', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.lightText)),
                      const SizedBox(height: 8),
                      _buildCategoryGrid(setSheetState),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // 快捷食物 Chip
  Widget _buildQuickFoodChip(Food food) {
    return ActionChip(
      avatar: Text(food.icon, style: const TextStyle(fontSize: 16)),
      label: Text(food.name),
      onPressed: () => _showQuickAddDialog(food),
    );
  }

  // 快捷添加网格（高频食物）
  Widget _buildQuickAddGrid() {
    // 常用高频食物
    final quickFoods = [
      foodDatabase.firstWhere((f) => f.id == 'f002', orElse: () => foodDatabase[0]), // 白米饭
      foodDatabase.firstWhere((f) => f.id == 'f001', orElse: () => foodDatabase[1]), // 糙米饭
      foodDatabase.firstWhere((f) => f.id == 'f201', orElse: () => foodDatabase[20]), // 煮鸡蛋
      foodDatabase.firstWhere((f) => f.id == 'f601', orElse: () => foodDatabase[60]), // 牛奶
      foodDatabase.firstWhere((f) => f.id == 'f005', orElse: () => foodDatabase[4]), // 全麦面包
      foodDatabase.firstWhere((f) => f.id == 'f501', orElse: () => foodDatabase[50]), // 苹果
    ].where((f) => f != null).toList();
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: quickFoods.length,
      itemBuilder: (context, index) {
        final food = quickFoods[index];
        return _buildQuickAddCard(food);
      },
    );
  }

  // 快捷添加卡片
  Widget _buildQuickAddCard(Food food) {
    return InkWell(
      onTap: () => _showQuickAddDialog(food),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(food.icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 4),
            Text(food.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('${food.caloriePer100g.toInt()}kcal', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  // 分类网格
  Widget _buildCategoryGrid(void Function(void Function()) setSheetState) {
    final categories = {
      '🍚 主食': [FoodCategory.staple],
      '🥩 肉类': [FoodCategory.meat, FoodCategory.seafood],
      '🥚 蛋奶': [FoodCategory.egg, FoodCategory.dairy],
      '🥬 蔬菜': [FoodCategory.vegetable],
      '🍎 水果': [FoodCategory.fruit],
      '🥤 饮料': [FoodCategory.drink, FoodCategory.snack],
    };
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final entry = categories.entries.elementAt(index);
        return InkWell(
          onTap: () {
            // 显示该分类的食物
            final foods = foodDatabase.where((f) => entry.value.contains(f.category)).toList();
            _showCategoryFoods(entry.key, foods);
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(entry.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        );
      },
    );
  }

  // 显示分类下的食物
  void _showCategoryFoods(String categoryName, List<Food> foods) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text(categoryName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: foods.length,
                itemBuilder: (context, index) => _buildFoodItemWithQuickAdd(foods[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 带快捷添加的食物项
  Widget _buildFoodItemWithQuickAdd(Food food) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Text(food.icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(food.name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                  Text('${food.caloriePer100g.toInt()} kcal/100g · ${food.category}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            // 快捷份量按钮
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMiniGramBtn(food, 50),
                _buildMiniGramBtn(food, 100),
                _buildMiniGramBtn(food, 200),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 迷你份量按钮
  Widget _buildMiniGramBtn(Food food, double grams) {
    return InkWell(
      onTap: () => _addFoodRecordAndClose(food, grams),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        margin: const EdgeInsets.only(left: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text('${grams.toInt()}g', style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500)),
      ),
    );
  }

  // 快速添加对话框（带份量和营养信息）
  void _showQuickAddDialog(Food food) {
    double selectedGrams = 100;
    
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
              Text(food.icon, style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(food.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('${food.caloriePer100g.toInt()} kcal / 100g', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 24),
              // 份量选择
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildGramChoice(setDialogState, 50, selectedGrams, (g) => selectedGrams = g),
                  _buildGramChoice(setDialogState, 100, selectedGrams, (g) => selectedGrams = g),
                  _buildGramChoice(setDialogState, 150, selectedGrams, (g) => selectedGrams = g),
                  _buildGramChoice(setDialogState, 200, selectedGrams, (g) => selectedGrams = g),
                ],
              ),
              const SizedBox(height: 20),
              // 自定义克数滑块
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('自定义克数', style: TextStyle(fontSize: 14, color: AppColors.lightText)),
                        Text('${selectedGrams.toInt()}g', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ],
                    ),
                    Slider(
                      value: selectedGrams,
                      min: 10,
                      max: 500,
                      divisions: 49,
                      label: '${selectedGrams.toInt()}g',
                      onChanged: (value) => setDialogState(() => selectedGrams = value),
                    ),
                    // 快捷调整按钮
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildGramAdjustBtn(setDialogState, selectedGrams, -50, (g) => selectedGrams = g),
                        _buildGramAdjustBtn(setDialogState, selectedGrams, -10, (g) => selectedGrams = g),
                        _buildGramAdjustBtn(setDialogState, selectedGrams, 10, (g) => selectedGrams = g),
                        _buildGramAdjustBtn(setDialogState, selectedGrams, 50, (g) => selectedGrams = g),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // 营养预览
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNutrientPreview('热量', '${food.calorieFor(selectedGrams).toStringAsFixed(0)}', 'kcal'),
                    _buildNutrientPreview('碳水', '${(food.carbPer100g * selectedGrams / 100).toInt()}', 'g'),
                    _buildNutrientPreview('蛋白质', '${(food.proteinPer100g * selectedGrams / 100).toInt()}', 'g'),
                    _buildNutrientPreview('脂肪', '${(food.fatPer100g * selectedGrams / 100).toInt()}', 'g'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _addFoodRecordAndClose(food, selectedGrams);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('添加 ${selectedGrams.toInt()}g', style: const TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 份量选择按钮
  Widget _buildGramChoice(void Function(void Function()) setState, double grams, double selected, void Function(double) onSelect) {
    final isSelected = selected == grams;
    return InkWell(
      onTap: () {
        setState(() {
          onSelect(grams);
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${grams.toInt()}g', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87)),
          ],
        ),
      ),
    );
  }

  // 克数调整按钮
  Widget _buildGramAdjustBtn(void Function(void Function()) setState, double currentGrams, double delta, void Function(double) onSelect) {
    final newGrams = (currentGrams + delta).clamp(10, 500).toDouble();
    return InkWell(
      onTap: () {
        setState(() {
          onSelect(newGrams);
        });
      },
      borderRadius: BorderRadius.circular(4),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          delta > 0 ? '+${delta.toInt()}' : '${delta.toInt()}',
          style: TextStyle(fontSize: 12, color: delta > 0 ? AppColors.success : AppColors.primary, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  // 营养预览项
  Widget _buildNutrientPreview(String label, String value, String unit) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
        Text(unit, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }

  // 添加食物并关闭弹窗
  Future<void> _addFoodRecordAndClose(Food food, double grams) async {
    await _addFoodRecord(food, grams);
    // 添加到最近使用列表
    if (!_recentFoods.contains(food)) {
      _recentFoods.insert(0, food);
      if (_recentFoods.length > 10) _recentFoods.removeLast();
    }
    Navigator.pop(context);
  }

  Future<void> _addFoodRecord(Food food, double grams) async {
    final calorie = food.calorieFor(grams);
    final record = FoodRecord(
      id: '',
      oderId: widget.user.id,
      foodId: food.id,
      foodName: food.name,
      grams: grams,
      calorie: calorie,
      mealType: _selectedMealType,
      createdAt: DateTime.now(),
    );
    
    final (success, errorMsg) = await SupabaseService.addFoodRecord(record);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已添加 ${food.name} ${grams.toInt()}g')),
      );
      _loadTodayRecords();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg ?? '添加失败，请重试')),
      );
    }
  }

  Future<void> _deleteRecord(String recordId) async {
    final success = await SupabaseService.deleteFoodRecord(recordId);
    if (success && mounted) {
      _loadTodayRecords();
    }
  }
}