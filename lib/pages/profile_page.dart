import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';
import 'login_page.dart';

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
