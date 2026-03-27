import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 确保 SharedPreferences 初始化完成后再使用
class PreInitializedSharedPreferencesStorage implements GotrueAsyncStorage {
  SharedPreferences? _prefs;
  final Completer<void> _initCompleter = Completer<void>();

  PreInitializedSharedPreferencesStorage() {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    _initCompleter.complete();
  }

  @override
  Future<String?> getItem({required String key}) async {
    await _initCompleter.future;
    return _prefs!.getString(key);
  }

  @override
  Future<void> setItem({required String key, required String value}) async {
    await _initCompleter.future;
    await _prefs!.setString(key, value);
  }

  @override
  Future<void> removeItem({required String key}) async {
    await _initCompleter.future;
    await _prefs!.remove(key);
  }
}
