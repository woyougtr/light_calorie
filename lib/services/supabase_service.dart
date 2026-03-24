import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class SupabaseService {
  static const String url = 'https://cbsjlqnfwqtbydubcrpj.supabase.co';
  static const String key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNic2pscW5md3F0YnlkdWJjcnBqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQwMTQ4ODUsImV4cCI6MjA4OTU5MDg4NX0.AZZCotXt-EZP3hl1RoW_PUjWPfcnmdbAvYIxtFN7h2Q';

  static final SupabaseClient _client = SupabaseClient(url, key);

  static SupabaseClient get client => _client;

  // 获取当前用户
  static AppUser? get currentUser {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return AppUser(
      id: user.id,
      email: user.email ?? '',
      createdAt: DateTime.now(),
    );
  }

  // 邮箱注册
  static Future<AppUser?> signUp(String email, String password) async {
    try {
      final res = await _client.auth.signUp(
        email: email,
        password: password,
      );
      if (res.user == null) return null;
      return AppUser(id: res.user!.id, email: email, createdAt: DateTime.now());
    } catch (e) {
      return null;
    }
  }

  // 邮箱登录 - 使用 signInWithPassword
  static Future<AppUser?> signIn(String email, String password) async {
    try {
      final res = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (res.user == null) return null;
      return AppUser(id: res.user!.id, email: email, createdAt: DateTime.now());
    } catch (e) {
      return null;
    }
  }

  // 退出登录
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // 监听登录状态变化
  static Stream<AppUser?> get authStateChanges {
    return _client.auth.onAuthStateChange.map((event) {
      if (event.session?.user == null) return null;
      return AppUser(
        id: event.session!.user.id,
        email: event.session!.user.email ?? '',
        createdAt: DateTime.now(),
      );
    });
  }

  // 保存用户配置
  static Future<bool> saveProfile(AppUser user) async {
    try {
      await _client.from('profiles').upsert(user.toJson());
      return true;
    } catch (e) {
      return false;
    }
  }

  // 获取用户配置
  static Future<AppUser?> getProfile(String oderId) async {
    try {
      final data = await _client.from('profiles').select().eq('id', oderId).maybeSingle();
      if (data == null) return null;
      return AppUser.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  // 添加食物记录
  static Future<bool> addFoodRecord(FoodRecord record) async {
    try {
      await _client.from('food_records').insert(record.toJson());
      return true;
    } catch (e) {
      return false;
    }
  }

  // 获取食物记录
  static Future<List<FoodRecord>> getFoodRecords(String oderId, DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final data = await _client
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
      await _client.from('food_records').delete().eq('id', id);
      return true;
    } catch (e) {
      return false;
    }
  }

  // 添加打卡记录
  static Future<bool> addCheckIn(CheckIn checkIn) async {
    try {
      await _client.from('check_ins').insert(checkIn.toJson());
      return true;
    } catch (e) {
      return false;
    }
  }

  // 获取打卡记录
  static Future<List<CheckIn>> getCheckIns(String oderId, {int limit = 30}) async {
    try {
      final data = await _client
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
      await _client.from('weight_records').insert(record.toJson());
      return true;
    } catch (e) {
      return false;
    }
  }

  // 获取体重记录
  static Future<List<WeightRecord>> getWeightRecords(String oderId, {int limit = 30}) async {
    try {
      final data = await _client
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
