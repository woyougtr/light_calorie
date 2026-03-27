import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';
import 'main_app.dart';

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
