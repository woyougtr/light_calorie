import 'package:flutter/material.dart';
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
