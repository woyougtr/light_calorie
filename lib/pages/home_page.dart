import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../config/app_colors.dart';
import '../data/foods.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';

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
