import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'supabase_auth_api.dart';

class SupabaseService {
  static const String url = 'https://pjtakguinniaeaymncob.supabase.co';
  static const String key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBqdGFrZ3Vpbm5pYWVheW1uY29iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQzODIzOTEsImV4cCI6MjA4OTk1ODM5MX0.lta1aCGilkqLCc2UdY_PKM3-M-zYRGKcidMtZenuuvQ';

  static String? _accessToken;
  static AppUser? _currentUser;

  static SupabaseClient get client {
    if (_accessToken != null) {
      return SupabaseClient(
        url,
        key,
        headers: {'Authorization': 'Bearer $_accessToken'},
      );
    }
    return SupabaseClient(url, key);
  }

  // 获取当前用户
  static AppUser? get currentUser => _currentUser;

  // 邮箱注册（直接调 HTTP API，绕过 PKCE 问题）
  static Future<(AppUser?, String?)> signUp(String email, String password) async {
    final (user, token, error) = await SupabaseAuthApi.signUp(email, password);
    if (user != null && token != null) {
      _currentUser = user;
      _accessToken = token;
    }
    return (user, error);
  }

  // 邮箱登录（直接调 HTTP API，绕过 PKCE 问题）
  static Future<(AppUser?, String?)> signIn(String email, String password) async {
    final (user, token, error) = await SupabaseAuthApi.signIn(email, password);
    if (user != null && token != null) {
      _currentUser = user;
      _accessToken = token;
    }
    return (user, error);
  }

  // 退出登录
  static Future<void> signOut() async {
    _accessToken = null;
    _currentUser = null;
  }

  // 监听登录状态变化
  static Stream<AppUser?> get authStateChanges async* {
    // 由于使用自定义登录，这里返回当前用户的变化
    yield _currentUser;
  }

  // 保存用户配置
  static Future<bool> saveProfile(AppUser user) async {
    try {
      await client.from('profiles').upsert(user.toJson());
      return true;
    } catch (e) {
      return false;
    }
  }

  // 获取用户配置
  static Future<AppUser?> getProfile(String oderId) async {
    try {
      final data = await client.from('profiles').select().eq('id', oderId).maybeSingle();
      if (data == null) return null;
      return AppUser.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  // 添加食物记录
  static Future<(bool, String?)> addFoodRecord(FoodRecord record) async {
    try {
      await client.from('food_records').insert(record.toJson());
      return (true, null);
    } on PostgrestException catch (e) {
      // RLS 权限错误
      if (e.code == '42501') {
        return (false, '权限不足：${_accessToken == null ? "未登录" : "RLS策略问题"}');
      }
      // 其他 Postgrest 错误
      return (false, '数据库错误: ${e.message}');
    } catch (e) {
      return (false, '未知错误: $e');
    }
  }

  // 获取食物记录
  static Future<List<FoodRecord>> getFoodRecords(String oderId, DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final data = await client
          .from('food_records')
          .select()
          .eq('user_id', oderId)
          .gte('created_at', '$dateStr 00:00:00')
          .lte('created_at', '$dateStr 23:59:59')
          .order('created_at');
      return (data as List).map((e) => FoodRecord.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  // 删除食物记录
  static Future<bool> deleteFoodRecord(String id) async {
    try {
      await client.from('food_records').delete().eq('id', id);
      return true;
    } catch (e) {
      return false;
    }
  }

  // 添加打卡记录
  static Future<bool> addCheckIn(CheckIn checkIn) async {
    try {
      await client.from('check_ins').insert(checkIn.toJson());
      return true;
    } catch (e) {
      return false;
    }
  }

  // 获取打卡记录
  static Future<List<CheckIn>> getCheckIns(String oderId, {int limit = 30}) async {
    try {
      final data = await client
          .from('check_ins')
          .select()
          .eq('user_id', oderId)
          .order('date', ascending: false)
          .limit(limit);
      return (data as List).map((e) => CheckIn.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  // 添加体重记录
  static Future<bool> addWeightRecord(WeightRecord record) async {
    try {
      await client.from('weight_records').insert(record.toJson());
      return true;
    } catch (e) {
      return false;
    }
  }

  // 获取体重记录
  static Future<List<WeightRecord>> getWeightRecords(String oderId, {int limit = 30}) async {
    try {
      final data = await client
          .from('weight_records')
          .select()
          .eq('user_id', oderId)
          .order('date', ascending: false)
          .limit(limit);
      return (data as List).map((e) => WeightRecord.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }
}
