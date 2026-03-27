import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:table_calendar/table_calendar.dart';
import 'data/foods.dart';
import 'models/models.dart';
import 'services/supabase_service.dart';

/// 确保 SharedPreferences 初始化完成后再使用
class PreInitializedSharedPreferencesStorage implements GotrueAsyncStorage {
  SharedPreferences? _prefs;
  final Completer<void> _initCompleter = Completer<void>();

  PreInitializedSharedPreferencesStorage() {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    _initCompleter.complete();
  }

  @override
  Future<String?> getItem({required String key}) async {
    await _initCompleter.future;
    return _prefs!.getString(key);
  }

  @override
  Future<void> setItem({required String key, required String value}) async {
    await _initCompleter.future;
    await _prefs!.setString(key, value);
  }

  @override
  Future<void> removeItem({required String key}) async {
    await _initCompleter.future;
    await _prefs!.remove(key);
  }
}

class AppColors {
  static const primary = Color(0xFFFF6B35);
  static const secondary = Color(0xFF4ECDC4);
  static const accent = Color(0xFFFFE66D);
  static const background = Color(0xFFFAFAFA);
  static const cardBg = Colors.white;
  static const darkText = Color(0xFF2D3436);
  static const lightText = Color(0xFF636E72);
  static const success = Color(0xFF00B894);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      title: '轻卡', debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary, primary: AppColors.primary, secondary: AppColors.secondary),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});
  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _loading = true;
  @override
  void initState() { super.initState(); _checkAuth(); }
  void _checkAuth() {
    final user = SupabaseService.currentUser;
    if (user != null && mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainApp(user: user)));
    if (mounted) setState(() => _loading = false);
  }
  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return const LoginPage();
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLogin = true, _loading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() { _emailController.dispose(); _passwordController.dispose(); super.dispose(); }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) { _showMsg('请填写完整'); return; }
    setState(() => _loading = true);
    try {
      AppUser? user;
      String? errMsg;
      if (_isLogin) {
        (user, errMsg) = await SupabaseService.signIn(email, password);
        if (user == null) _showMsg(errMsg ?? '登录失败');
        else if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainApp(user: user!)));
      } else {
        if (password.length < 6) { _showMsg('密码至少6位'); setState(() => _loading = false); return; }
        (user, errMsg) = await SupabaseService.signUp(email, password);
        if (user == null) _showMsg(errMsg ?? '注册失败');
        else if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainApp(user: user!)));
      }
    } catch (e) { _showMsg('操作异常: $e'); }
    if (mounted) setState(() => _loading = false);
  }

  void _showMsg(String msg) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg))); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: 60),
        const Text('✨ 欢迎使用 轻卡', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary), textAlign: TextAlign.center),
        const SizedBox(height: 48),
        TextField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: '邮箱', prefixIcon: const Icon(Icons.email), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
        const SizedBox(height: 16),
        TextField(controller: _passwordController, obscureText: true, decoration: InputDecoration(labelText: '密码', prefixIcon: const Icon(Icons.lock), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
        const SizedBox(height: 24),
        ElevatedButton(onPressed: _loading ? null : _submit, child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(_isLogin ? '登录' : '注册')),
        const SizedBox(height: 16),
        TextButton(onPressed: () => setState(() { _isLogin = !_isLogin; _loading = false; }), child: Text(_isLogin ? '没有账号？注册' : '有账号？登录')),
      ]))),
    );
  }
}

class MainApp extends StatefulWidget {
  final AppUser user;
  const MainApp({super.key, required this.user});
  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _currentIndex = 0;
  final GlobalKey<_HomePageState> _homePageKey = GlobalKey();

  void _onNavChanged(int index) {
    // 从记录页(1)或其他页面切换回首页(0)时刷新数据
    if (index == 0 && _currentIndex != 0) {
      _homePageKey.currentState?.loadTodayData();
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: [
        HomePage(key: _homePageKey, user: widget.user),
        RecordPage(user: widget.user),
        CheckInPage(user: widget.user),
        ProfilePage(user: widget.user),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onNavChanged,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: '首页'),
          NavigationDestination(icon: Icon(Icons.edit), label: '记录'),
          NavigationDestination(icon: Icon(Icons.calendar_today), label: '打卡'),
          NavigationDestination(icon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final AppUser user;
  const HomePage({super.key, required this.user});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<FoodRecord> _todayRecords = [];
  List<WeightRecord> _weightRecords = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    loadTodayData();
  }

  /// 加载今日数据，可以被外部调用刷新
  Future<void> loadTodayData() async {
    setState(() => _loading = true);
    final records = await SupabaseService.getFoodRecords(widget.user.id, DateTime.now());
    final weights = await SupabaseService.getWeightRecords(widget.user.id, limit: 30);
    if (mounted) setState(() { _todayRecords = records; _weightRecords = weights; _loading = false; });
  }

  /// 获取当前体重（最近一次记录）
  double? get _currentWeight => _weightRecords.isNotEmpty ? _weightRecords.first.weight : null;

  /// 获取本周体重变化
  double? get _weeklyWeightChange {
    if (_weightRecords.length < 2) return null;
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final recentWeights = _weightRecords.where((r) => r.date.isAfter(weekAgo)).toList();
    if (recentWeights.length < 2) return null;
    return recentWeights.last.weight - recentWeights.first.weight;
  }

  double get _totalCalories => _todayRecords.fold(0, (sum, r) => sum + r.calorie);

  /// 获取各餐次记录状态
  Map<MealType, bool> getMealStatus() {
    final Set<MealType> recordedMeals = _todayRecords.map((r) => r.mealType).toSet();
    return {
      MealType.breakfast: recordedMeals.contains(MealType.breakfast),
      MealType.lunch: recordedMeals.contains(MealType.lunch),
      MealType.dinner: recordedMeals.contains(MealType.dinner),
      MealType.snack: recordedMeals.contains(MealType.snack),
    };
  }

  /// 计算今日营养素总量
  ({double carbs, double protein, double fat}) getNutritionTotals() {
    double carbs = 0, protein = 0, fat = 0;
    for (final record in _todayRecords) {
      // 根据 foodId 查找食物数据
      final food = foodDatabase.where((f) => f.id == record.foodId).firstOrNull;
      if (food != null) {
        final factor = record.grams / 100;
        carbs += food.carbPer100g * factor;
        protein += food.proteinPer100g * factor;
        fat += food.fatPer100g * factor;
      }
    }
    return (carbs: carbs, protein: protein, fat: fat);
  }

  @override
  Widget build(BuildContext context) {
    final goal = widget.user.dailyCalorieGoal;
    final consumed = _totalCalories;
    final progress = goal > 0 ? (consumed / goal).clamp(0.0, 1.0) : 0.0;
    final mealStatus = getMealStatus();
    final completedMeals = mealStatus.values.where((v) => v).length;
    final nutrition = getNutritionTotals();

    return Scaffold(
      appBar: AppBar(title: const Text('轻卡')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(onRefresh: loadTodayData, child: ListView(padding: const EdgeInsets.all(16), children: [
              // 今日打卡进度卡片
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('📊 今日打卡进度', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: completedMeals / 4,
                  backgroundColor: Colors.grey[200],
                  color: AppColors.secondary,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                Text('$completedMeals / 4 餐', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(spacing: 16, runSpacing: 8, children: [
                  _buildMealChip(MealType.breakfast, mealStatus[MealType.breakfast]!),
                  _buildMealChip(MealType.lunch, mealStatus[MealType.lunch]!),
                  _buildMealChip(MealType.dinner, mealStatus[MealType.dinner]!),
                  _buildMealChip(MealType.snack, mealStatus[MealType.snack]!),
                ]),
              ]))),
              const SizedBox(height: 16),
              // 体重趋势卡片
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('📈 体重趋势', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  if (_currentWeight != null)
                    Text('当前: ${_currentWeight!.toStringAsFixed(1)}kg', style: const TextStyle(color: AppColors.lightText)),
                ]),
                const SizedBox(height: 12),
                _weightRecords.isEmpty
                    ? _buildEmptyWeightChart()
                    : SizedBox(
                        height: 150,
                        child: _buildWeightChart(),
                      ),
                if (_weeklyWeightChange != null) ...[
                  const SizedBox(height: 8),
                  Row(children: [
                    Icon(_weeklyWeightChange! <= 0 ? Icons.trending_down : Icons.trending_up,
                      size: 16, color: _weeklyWeightChange! <= 0 ? AppColors.success : AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      _weeklyWeightChange! <= 0
                        ? '本周下降 ${_weeklyWeightChange!.abs().toStringAsFixed(1)}kg'
                        : '本周上升 ${_weeklyWeightChange!.toStringAsFixed(1)}kg',
                      style: TextStyle(color: _weeklyWeightChange! <= 0 ? AppColors.success : AppColors.primary, fontWeight: FontWeight.w500),
                    ),
                  ]),
                ],
              ]))),
              const SizedBox(height: 16),
              // 今日热量摄入卡片
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('🔥 今日摄入', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Center(child: Text(
                  '$consumed / $goal 大卡',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: consumed > goal ? AppColors.primary : AppColors.darkText,
                  ),
                )),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[200],
                  color: consumed > goal ? AppColors.primary : AppColors.secondary,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                if (consumed > goal) Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('⚠️ 已超出目标 ${(consumed - goal).toInt()} 大卡', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                ),
              ]))),
              const SizedBox(height: 16),
              // 营养素分解卡片
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('🥗 营养素分解', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  _buildNutrientItem('碳水', nutrition.carbs, '🌾', const Color(0xFFFFB347)),
                  _buildNutrientItem('蛋白质', nutrition.protein, '🥚', const Color(0xFF87CEEB)),
                  _buildNutrientItem('脂肪', nutrition.fat, '🥑', const Color(0xFF98D8C8)),
                ]),
              ]))),
              const SizedBox(height: 16),
              // 今日记录列表
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('🍽️ 今日记录 ${_todayRecords.length} 条', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                if (_todayRecords.isEmpty) const Text('暂无记录，点击底部"记录"添加', style: TextStyle(color: Colors.grey)),
                for (final r in _todayRecords) ListTile(
                  dense: true, contentPadding: EdgeInsets.zero,
                  leading: Text(r.mealType.icon, style: const TextStyle(fontSize: 20)),
                  title: Text(r.foodName),
                  subtitle: Text('${r.grams.toInt()}g'),
                  trailing: Text('${r.calorie.toInt()} kcal', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
              ]))),
            ])),
    );
  }

  Widget _buildMealChip(MealType meal, bool completed) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(completed ? Icons.check_circle : Icons.radio_button_unchecked,
        size: 18, color: completed ? AppColors.success : Colors.grey),
      const SizedBox(width: 4),
      Text('${meal.icon} ${meal.label}',
        style: TextStyle(fontSize: 13, color: completed ? AppColors.darkText : Colors.grey)),
    ]);
  }

  Widget _buildNutrientItem(String label, double value, String icon, Color color) {
    return Column(children: [
      Text(icon, style: const TextStyle(fontSize: 24)),
      const SizedBox(height: 4),
      Text('${value.toInt()}g', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.lightText)),
    ]);
  }

  /// 体重趋势空状态
  Widget _buildEmptyWeightChart() {
    return Container(
      height: 150,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 8),
          const Text('暂无体重记录', style: TextStyle(color: AppColors.lightText)),
          const SizedBox(height: 4),
          Text('在"我的"页面记录体重', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        ],
      ),
    );
  }

  /// 绘制体重趋势折线图
  Widget _buildWeightChart() {
    // 按日期排序（从旧到新）
    final sortedRecords = _weightRecords.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // 计算数据点
    final spots = <FlSpot>[];
    for (int i = 0; i < sortedRecords.length; i++) {
      spots.add(FlSpot(i.toDouble(), sortedRecords[i].weight));
    }

    // 计算 Y 轴范围
    final weights = sortedRecords.map((r) => r.weight).toList();
    final minWeight = weights.reduce((a, b) => a < b ? a : b);
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);
    final yMin = (minWeight - 2).floorToDouble();
    final yMax = (maxWeight + 2).ceilToDouble();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 2,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey[200]!,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: (spots.length > 7 ? 7 : 1).toDouble(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= sortedRecords.length) return const Text('');
                final date = sortedRecords[index].date;
                return Text(
                  '${date.month}/${date.day}',
                  style: const TextStyle(color: AppColors.lightText, fontSize: 10),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 2,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt()}',
                style: const TextStyle(color: AppColors.lightText, fontSize: 10),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (spots.length - 1).toDouble().clamp(0, double.infinity),
        minY: yMin,
        maxY: yMax,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.secondary,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 3,
                color: AppColors.secondary,
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.secondary.withValues(alpha: 0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                if (index < 0 || index >= sortedRecords.length) return null;
                final record = sortedRecords[index];
                return LineTooltipItem(
                  '${record.date.month}/${record.date.day}: ${record.weight.toStringAsFixed(1)}kg',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}

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

class ProfilePage extends StatefulWidget {
  final AppUser user;
  const ProfilePage({super.key, required this.user});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  List<WeightRecord> _weightRecords = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadWeightRecords();
  }

  Future<void> _loadWeightRecords() async {
    final records = await SupabaseService.getWeightRecords(widget.user.id, limit: 30);
    if (mounted) setState(() { _weightRecords = records; _loading = false; });
  }

  double? get _currentWeight => _weightRecords.isNotEmpty ? _weightRecords.first.weight : null;
  double? get _initialWeight => widget.user.initialWeight;
  double? get _targetWeight => widget.user.targetWeight;
  double? get _weightChange => (_currentWeight != null && _initialWeight != null) ? _initialWeight! - _currentWeight! : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadWeightRecords,
              child: ListView(padding: const EdgeInsets.all(16), children: [
                // 用户头像卡片
                Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
                  const CircleAvatar(radius: 40, child: Text('👤', style: TextStyle(fontSize: 40))),
                  const SizedBox(height: 16),
                  Text(widget.user.nickname ?? '轻卡用户', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ]))),
                const SizedBox(height: 16),
                // 体重数据卡片
                Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('📊 我的数据', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    TextButton.icon(
                      onPressed: () => _showWeightDialog(),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('记录体重'),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _buildDataItem('初始', _initialWeight)),
                    Expanded(child: _buildDataItem('当前', _currentWeight, highlight: true)),
                    Expanded(child: _buildDataItem('目标', _targetWeight)),
                  ]),
                  if (_weightChange != null) ...[
                    const SizedBox(height: 12),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(_weightChange! >= 0 ? Icons.trending_down : Icons.trending_up,
                        color: _weightChange! >= 0 ? AppColors.success : AppColors.primary, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '已${_weightChange! >= 0 ? "减" : "增"}重 ${_weightChange!.abs().toStringAsFixed(1)}kg',
                        style: TextStyle(color: _weightChange! >= 0 ? AppColors.success : AppColors.primary, fontWeight: FontWeight.w500),
                      ),
                    ]),
                  ],
                ]))),
                const SizedBox(height: 16),
                // 功能菜单
                Card(child: Column(children: [
                  ListTile(leading: const Text('⚖️'), title: const Text('体重历史'), trailing: const Icon(Icons.chevron_right), onTap: () => _showWeightHistory()),
                  ListTile(leading: const Text('👤'), title: const Text('个人资料'), trailing: const Icon(Icons.chevron_right)),
                  ListTile(leading: const Text('🎯'), title: const Text('目标设置'), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GoalsPage(user: widget.user)))),
                  ListTile(leading: const Text('🔔'), title: const Text('提醒设置'), trailing: const Icon(Icons.chevron_right)),
                  ListTile(leading: const Text('❓'), title: const Text('帮助反馈'), trailing: const Icon(Icons.chevron_right)),
                ])),
                const SizedBox(height: 24),
                OutlinedButton(onPressed: () async { await SupabaseService.signOut(); if (context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage())); }, child: const Text('退出登录')),
              ]),
            ),
    );
  }

  Widget _buildDataItem(String label, double? value, {bool highlight = false}) {
    return Column(children: [
      Text(value != null ? '${value.toStringAsFixed(1)}kg' : '--', style: TextStyle(
        fontSize: highlight ? 18 : 14,
        fontWeight: FontWeight.bold,
        color: highlight ? AppColors.primary : AppColors.darkText,
      )),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.lightText)),
    ]);
  }

  void _showWeightDialog() {
    final controller = TextEditingController(text: _currentWeight?.toStringAsFixed(1) ?? '65.0');
    DateTime selectedDate = DateTime.now();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('记录体重'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 日期选择
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text('${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}'),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) setDialogState(() => selectedDate = date);
                },
              ),
              // 体重输入
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: '体重 (kg)',
                  suffixText: 'kg',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              // 快捷选择
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _buildQuickWeightBtn(controller, -0.5),
                _buildQuickWeightBtn(controller, -0.1),
                _buildQuickWeightBtn(controller, 0.1),
                _buildQuickWeightBtn(controller, 0.5),
              ]),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
            ElevatedButton(
              onPressed: () async {
                final weight = double.tryParse(controller.text);
                if (weight == null || weight <= 0 || weight > 300) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入有效体重')));
                  return;
                }
                final record = WeightRecord(
                  id: '',
                  oderId: widget.user.id,
                  weight: weight,
                  date: selectedDate,
                  createdAt: DateTime.now(),
                );
                final success = await SupabaseService.addWeightRecord(record);
                if (success && mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已记录 ${weight.toStringAsFixed(1)}kg')));
                  _loadWeightRecords();
                }
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickWeightBtn(TextEditingController controller, double delta) {
    return InkWell(
      onTap: () {
        final current = double.tryParse(controller.text) ?? 65.0;
        controller.text = (current + delta).toStringAsFixed(1);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          delta > 0 ? '+${delta}' : '$delta',
          style: TextStyle(color: delta > 0 ? AppColors.primary : AppColors.success),
        ),
      ),
    );
  }

  void _showWeightHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('体重历史', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: _weightRecords.isEmpty
                  ? const Center(child: Text('暂无记录', style: TextStyle(color: AppColors.lightText)))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: _weightRecords.length,
                      itemBuilder: (context, index) {
                        final r = _weightRecords[index];
                        return ListTile(
                          leading: const Icon(Icons.monitor_weight, color: AppColors.secondary),
                          title: Text('${r.weight.toStringAsFixed(1)} kg'),
                          subtitle: Text('${r.date.year}-${r.date.month.toString().padLeft(2, '0')}-${r.date.day.toString().padLeft(2, '0')}'),
                          trailing: index < _weightRecords.length - 1
                              ? Text(
                                  '${r.weight >= _weightRecords[index + 1].weight ? '+' : ''}${(r.weight - _weightRecords[index + 1].weight).toStringAsFixed(1)}kg',
                                  style: TextStyle(color: r.weight >= _weightRecords[index + 1].weight ? AppColors.primary : AppColors.success),
                                )
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class GoalsPage extends StatefulWidget {
  final AppUser user;
  const GoalsPage({super.key, required this.user});
  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  double _targetWeight = 65.0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('目标设置')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('🎯 目标体重', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Text('${_targetWeight.toInt()} kg', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
          Slider(value: _targetWeight, min: 40, max: 100, divisions: 60, onChanged: (v) => setState(() => _targetWeight = v)),
        ]))),
        const SizedBox(height: 24),
        ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('保存')),
      ]),
    );
  }
}
