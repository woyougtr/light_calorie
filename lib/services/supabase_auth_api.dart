import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

/// 直接通过 HTTP 调用 Supabase Auth API，绕过 supabase_flutter 的 PKCE auth SDK 问题
class SupabaseAuthApi {
  static const String _url = 'https://pjtakguinniaeaymncob.supabase.co';
  static const String _anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBqdGFrZ3Vpbm5pYWVheW1uY29iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQzODIzOTEsImV4cCI6MjA4OTk1ODM5MX0.lta1aCGilkqLCc2UdY_PKM3-M-zYRGKcidMtZenuuvQ';

  static final Map<String, String> _headers = {
    'apikey': _anonKey,
    'Authorization': 'Bearer $_anonKey',
    'Content-Type': 'application/json',
  };

  static String _str(dynamic v) => v?.toString() ?? '';
  static String? _ostr(dynamic v) => v?.toString();

  /// 注册
  static Future<(AppUser?, String?, String?)> signUp(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$_url/auth/v1/signup'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      final data = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200 || res.statusCode == 201) {
        // 如果有 session 说明注册成功直接登录了
        final session = data['session'] as Map<String, dynamic>?;
        final accessToken = session?['access_token']?.toString();
        if (data['session'] != null) {
          final user = data['user'] as Map<String, dynamic>?;
          if (user != null) {
            return (AppUser(id: user['id'].toString(), email: email, createdAt: DateTime.now()), accessToken, null);
          }
        }
        // 有 id 但没有 session，说明邮箱需要确认
        final id = data['id'];
        if (id != null) {
          return (null, null, '注册成功！请去邮箱点击链接完成确认，然后再登录');
        }
        return (null, null, _ostr(data['msg']) ?? '注册失败');
      } else {
        return (null, null, _ostr(data['msg']) ?? _ostr(data['error']) ?? '注册失败 (${res.statusCode})');
      }
    } catch (e) {
      return (null, null, '网络异常');
    }
  }

  /// 登录
  static Future<(AppUser?, String?, String?)> signIn(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$_url/auth/v1/token?grant_type=password'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      final data = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200) {
        final user = data['user'] as Map<String, dynamic>?;
        // access_token 直接在根级别，不在 session 嵌套中
        final accessToken = data['access_token']?.toString();
        if (user != null && accessToken != null) {
          final userId = user['id'];
          final userEmail = user['email'] ?? email;
          return (AppUser(id: userId.toString(), email: userEmail.toString(), createdAt: DateTime.now()), accessToken, null);
        }
        return (null, null, '登录失败：未获取到认证信息');
      } else {
        // 邮箱未确认时返回友好提示
        final msg = _ostr(data['msg']) ?? _ostr(data['error_description']) ?? '';
        if (msg.toLowerCase().contains('email') && msg.toLowerCase().contains('confirm')) {
          return (null, null, '请先去邮箱点击确认链接，然后再登录');
        }
        return (null, null, msg.isNotEmpty ? msg : '登录失败 (${res.statusCode})');
      }
    } catch (e) {
      return (null, null, '网络异常');
    }
  }
}
