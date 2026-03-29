import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class SupabaseService {
  static const String url = 'https://pjtakguinniaeaymncob.supabase.co';
  static const String key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBqdGFrZ3Vpbm5pYWVheW1uY29iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQzODIzOTEsImV4cCI6MjA4OTk1ODM5MX0.lta1aCGilkqLCc2UdY_PKM3-M-zYRGKcidMtZenuuvQ';

  static String? _accessToken;
  static AppUser? _currentUser;

  /// 将 Supabase Auth 错误转换为友好的中文提示
  static String _friendlyAuthError(String error) {
    final lower = error.toLowerCase();
    
    // 登录相关
    if (lower.contains('invalid login credentials')) {
      return '邮箱或密码错误，请检查后重试';
    }
    if (lower.contains('email not confirmed') || 
        (lower.contains('email') && lower.contains('confirm'))) {
      return '邮箱尚未确认，请查收邮件并点击确认链接';
    }
    
    // 注册相关
    if (lower.contains('user already registered') || 
        lower.contains('already exists')) {
      return '该邮箱已注册，请直接登录';
    }
    if (lower.contains('password should be at least') || 
        lower.contains('password is too short')) {
      return '密码长度不能少于6位';
    }
    if (lower.contains('unable to validate email') || 
        lower.contains('invalid email')) {
      return '邮箱格式不正确，请输入有效的邮箱地址';
    }
    if (lower.contains('email address is invalid')) {
      return '邮箱格式不正确';
    }
    
    // 通用错误
    if (lower.contains('network') || lower.contains('connection')) {
      return '网络连接失败，请检查网络后重试';
    }
    if (lower.contains('timeout')) {
      return '连接超时，请稍后重试';
    }
    if (lower.contains('rate limit')) {
      return '操作过于频繁，请稍后再试';
    }
    if (lower.contains('server error')) {
      return '服务器繁忙，请稍后重试';
    }
    
    // 默认返回原文
    return error;
  }

  // 使用 Supabase 全局实例，确保会话状态正确持久化
  static SupabaseClient get client => Supabase.instance.client;

  // 获取当前用户（如果内存中没有但从 session 中有，自动恢复）
  static AppUser? get currentUser {
    if (_currentUser != null) return _currentUser;
    // 尝试从 Supabase session 恢复
    final sessionUser = client.auth.currentUser;
    if (sessionUser != null) {
      _currentUser = AppUser(
        id: sessionUser.id,
        email: sessionUser.email ?? '',
        createdAt: DateTime.now(),
      );
      return _currentUser;
    }
    return null;
  }

    // 邮箱注册（使用 SDK ）

    static Future<(AppUser?, String?)> signUp(String email, String password) async {

      try {

        final res = await client.auth.signUp(email: email, password: password);

        if (res.user != null) {

          // 检查 session 是否存在：有 session 说明邮箱已确认或不需要确认，无 session 说明需要邮箱确认

          if (res.session == null) {

            // 需要邮箱确认

            return (null, '注册成功！请去邮箱点击链接完成确认，然后再登录');

          }

          // 有 session，可以直接登录

          _accessToken = res.session?.accessToken;

          _currentUser = AppUser(

            id: res.user!.id,

            email: email,

            createdAt: DateTime.now(),

          );

          return (_currentUser, null);

        }

        return (null, '注册失败，请稍后重试');

      } on AuthException catch (e) {

        return (null, _friendlyAuthError(e.message));

      } catch (e) {

        return (null, '网络异常，请检查网络后重试');

      }

    }

  

    // 邮箱登录（使用 SDK ）

    static Future<(AppUser?, String?)> signIn(String email, String password) async {

      try {

        final res = await client.auth.signInWithPassword(email: email, password: password);

        if (res.user != null) {

          _accessToken = res.session?.accessToken;

          _currentUser = AppUser(

            id: res.user!.id,

            email: email,

            createdAt: DateTime.now(),

          );

          return (_currentUser, null);

        }

        return (null, '登录失败，请稍后重试');

      } on AuthException catch (e) {

        return (null, _friendlyAuthError(e.message));

      } catch (e) {

        return (null, '网络异常，请检查网络后重试');

      }

    }

  // 退出登录
  static Future<void> signOut() async {
    await client.auth.signOut();
    _accessToken = null;
    _currentUser = null;
  }

  // 监听登录状态变化
  static Stream<AppUser?> get authStateChanges {
    return client.auth.onAuthStateChange.map((event) {
      if (event.session?.user != null) {
        _currentUser = AppUser(
          id: event.session!.user.id,
          email: event.session!.user.email ?? '',
          createdAt: DateTime.now(),
        );
      } else {
        _currentUser = null;
      }
      return _currentUser;
    });
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

  // 添加运动记录
  static Future<(bool, String?)> addExerciseRecord(ExerciseRecord record) async {
    try {
      // 检查是否已登录
      final session = client.auth.currentSession;
      final user = client.auth.currentUser;
      if (session == null || user == null) {
        return (false, '未登录：请先登录');
      }

      // 检查用户ID是否匹配
      if (record.userId != user.id) {
        return (false, '用户ID不匹配：record.userId=${record.userId}, auth.userId=${user.id}');
      }

      final data = record.toJson();
      await client.from('exercise_records').insert(data);
      return (true, null);
    } on PostgrestException catch (e) {
      // RLS 权限错误
      if (e.code == '42501') {
        return (false, '权限不足：RLS策略阻止了插入，请检查策略配置');
      }
      // JWT 错误
      if (e.message.contains('JWT') || e.message.contains('token')) {
        return (false, '认证过期，请重新登录');
      }
      return (false, '数据库错误: ${e.message} (code: ${e.code})');
    } catch (e) {
      return (false, '未知错误: $e');
    }
  }

  // 获取运动记录
  static Future<List<ExerciseRecord>> getExerciseRecords(String userId, {DateTime? date, int limit = 30}) async {
    try {
      final query = client
          .from('exercise_records')
          .select();
      
      if (date != null) {
        final dateStr = date.toIso8601String().split('T')[0];
        final data = await query
            .eq('user_id', userId)
            .eq('date', dateStr)
            .order('created_at', ascending: false);
        return (data as List).map((e) => ExerciseRecord.fromJson(e as Map<String, dynamic>)).toList();
      }
      
      final data = await query
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);
      return (data as List).map((e) => ExerciseRecord.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  // 获取今日运动总消耗
  static Future<double> getTodayExerciseCalorie(String userId) async {
    try {
      final today = DateTime.now();
      final dateStr = today.toIso8601String().split('T')[0];
      final data = await client
          .from('exercise_records')
          .select('calorie')
          .eq('user_id', userId)
          .eq('date', dateStr);

      if (data.isEmpty) return 0.0;

      double total = 0.0;
      for (final item in data as List) {
        if (item['calorie'] != null) {
          total += (item['calorie'] as num).toDouble();
        }
      }
      return total;
    } catch (e) {
      return 0.0;
    }
  }

  // ===== 饮水记录 =====

  // 保存饮水记录（更新当日饮水量）
  static Future<bool> saveWaterRecord(String oderId, int count, DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      // 先查询当日是否有记录
      final existing = await client
          .from('water_records')
          .select()
          .eq('user_id', oderId)
          .eq('date', dateStr)
          .maybeSingle();

      if (existing != null) {
        // 更新
        await client.from('water_records').update({
          'count': count,
        }).eq('id', existing['id']);
      } else {
        // 新增
        await client.from('water_records').insert({
          'user_id': oderId,
          'count': count,
          'date': dateStr,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  // 获取指定日期饮水记录
  static Future<int> getWaterRecord(String oderId, DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final data = await client
          .from('water_records')
          .select('count')
          .eq('user_id', oderId)
          .eq('date', dateStr)
          .maybeSingle();

      if (data == null) return 0;
      return (data['count'] as num?)?.toInt() ?? 0;
    } catch (e) {
      return 0;
    }
  }
}
