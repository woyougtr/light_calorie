import 'package:flutter/material.dart';
import '../models/models.dart';
import '../widgets/common/tab_bar.dart';
import 'home_page.dart';
import 'record_page.dart';
import 'check_in_page.dart';
import 'profile_page.dart';

class MainApp extends StatefulWidget {
  final AppUser user;
  const MainApp({super.key, required this.user});
  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _currentIndex = 0;
  final GlobalKey _homePageKey = GlobalKey();
  final GlobalKey _checkInPageKey = GlobalKey();
  final GlobalKey _profilePageKey = GlobalKey();

  void _onNavChanged(int index) {
    // 切换 tab 时刷新对应页面的数据
    if (index == _currentIndex) return;

    if (index == 0) {
      // 切换到首页
      try {
        (_homePageKey.currentState as dynamic).loadTodayData();
      } catch (_) {}
    } else if (index == 2) {
      // 切换到打卡页
      try {
        (_checkInPageKey.currentState as dynamic).loadAllData();
      } catch (_) {}
    } else if (index == 3) {
      // 切换到我的页
      try {
        (_profilePageKey.currentState as dynamic).loadAllData();
      } catch (_) {}
    }

    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: [
        HomePage(key: _homePageKey, user: widget.user),
        RecordPage(user: widget.user),
        CheckInPage(key: _checkInPageKey, user: widget.user),
        ProfilePage(key: _profilePageKey, user: widget.user),
      ]),
      bottomNavigationBar: CapsuleTabBar(
        currentIndex: _currentIndex,
        onTap: _onNavChanged,
      ),
    );
  }
}
