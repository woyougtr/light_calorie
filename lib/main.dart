import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'data/foods.dart';
import 'models/models.dart';
import 'services/supabase_service.dart';

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
    authOptions: FlutterAuthClientOptions(
      pkceAsyncStorage: SharedPreferencesGotrueAsyncStorage(),
    ),
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: [HomePage(user: widget.user), RecordPage(user: widget.user), CheckInPage(user: widget.user), ProfilePage(user: widget.user)]),
      bottomNavigationBar: NavigationBar(selectedIndex: _currentIndex, onDestinationSelected: (i) => setState(() => _currentIndex = i), destinations: const [
        NavigationDestination(icon: Icon(Icons.home), label: '首页'),
        NavigationDestination(icon: Icon(Icons.edit), label: '记录'),
        NavigationDestination(icon: Icon(Icons.calendar_today), label: '打卡'),
        NavigationDestination(icon: Icon(Icons.person), label: '我的'),
      ]),
    );
  }
}

class HomePage extends StatelessWidget {
  final AppUser user;
  const HomePage({super.key, required this.user});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('轻卡')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('📊 今日进度', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: 0.6, backgroundColor: Colors.grey[200], color: AppColors.secondary),
        ]))),
        const SizedBox(height: 16),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('🔥 今日摄入', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          const Center(child: Text('780 / 1800 大卡', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
        ]))),
      ]),
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

  @override
  void initState() {
    super.initState();
    _todayRecords = [
      FoodRecord(id: '1', oderId: widget.user.id, foodId: 'f001', foodName: '糙米饭', grams: 200, calorie: 220, mealType: MealType.breakfast, createdAt: DateTime.now()),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('饮食记录')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        for (final r in _todayRecords) Card(child: ListTile(title: Text(r.foodName), subtitle: Text('${r.grams.toInt()}g'), trailing: Text('${r.calorie.toInt()}kcal', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)))),
      ]),
      floatingActionButton: FloatingActionButton.small(onPressed: () => _showAddFoodDialog(), backgroundColor: AppColors.primary, child: const Icon(Icons.add, color: Colors.white)),
    );
  }

  void _showAddFoodDialog() {
    showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(initialChildSize: 0.9, minChildSize: 0.5, maxChildSize: 0.95, expand: false, builder: (context, scrollController) => Column(children: [
        const SizedBox(height: 8),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: TextField(decoration: InputDecoration(hintText: '搜索食物...', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
        const SizedBox(height: 16),
        Expanded(child: ListView.builder(controller: scrollController, itemCount: 5, itemBuilder: (context, i) => ListTile(leading: Text('🍚'), title: Text('测试食物$i')))),
      ])));
  }
}

class CheckInPage extends StatelessWidget {
  final AppUser user;
  const CheckInPage({super.key, required this.user});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('打卡日历')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          const Text('🏆', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          const Text('连续打卡 12 天', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
        ]))),
        const SizedBox(height: 16),
        ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.camera_alt), label: const Text('拍照打卡')),
      ]),
    );
  }
}

class ProfilePage extends StatelessWidget {
  final AppUser user;
  const ProfilePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
          const CircleAvatar(radius: 40, child: Text('👤', style: TextStyle(fontSize: 40))),
          const SizedBox(height: 16),
          Text(user.nickname ?? '轻卡用户', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ]))),
        const SizedBox(height: 16),
        Card(child: Column(children: [
          ListTile(leading: const Text('👤'), title: const Text('个人资料'), trailing: const Icon(Icons.chevron_right)),
          ListTile(leading: const Text('🎯'), title: const Text('目标设置'), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GoalsPage(user: user)))),
          ListTile(leading: const Text('🔔'), title: const Text('提醒设置'), trailing: const Icon(Icons.chevron_right)),
          ListTile(leading: const Text('❓'), title: const Text('帮助反馈'), trailing: const Icon(Icons.chevron_right)),
        ])),
        const SizedBox(height: 24),
        OutlinedButton(onPressed: () async { await SupabaseService.signOut(); if (context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage())); }, child: const Text('退出登录')),
      ]),
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
