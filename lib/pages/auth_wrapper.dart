import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import 'login_page.dart';
import 'main_app.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});
  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _loading = true;
  bool _isLoggedIn = false;
  
  @override
  void initState() {
    super.initState();
    _initAuth();
  }
  
  Future<void> _initAuth() async {
    // 等待 session 恢复完成
    final session = Supabase.instance.client.auth.currentSession;
    
    if (session != null) {
      // 检查 session 是否过期，尝试刷新
      if (session.isExpired) {
        try {
          await Supabase.instance.client.auth.refreshSession();
        } catch (e) {
          // 刷新失败，需要重新登录
          if (mounted) {
            setState(() {
              _loading = false;
              _isLoggedIn = false;
            });
          }
          return;
        }
      }
      
      // 获取当前用户
      final user = SupabaseService.currentUser;
      if (user != null && mounted) {
        setState(() {
          _loading = false;
          _isLoggedIn = true;
        });
        _navigateToMain(user);
        return;
      }
    }
    
    if (mounted) {
      setState(() => _loading = false);
    }
  }
  
  void _navigateToMain(dynamic user) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => MainApp(user: user)),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return const LoginPage();
  }
}
