import 'package:flutter/material.dart';
import '../models/models.dart';
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

  void _onNavChanged(int index) {
    // 从记录页(1)或其他页面切换回首页(0)时刷新数据
    if (index == 0 && _currentIndex != 0) {
      // 通过 key 获取状态并调用加载方法
      try {
        (_homePageKey.currentState as dynamic).loadTodayData();
      } catch (_) {
        // 忽略调用失败
      }
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: [
        HomePage(key: _homePageKey, user: widget.user),
        RecordPage(user: widget.user),
        CheckInPage(user: widget.user),
        ProfilePage(user: widget.user),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onNavChanged,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: '首页'),
          NavigationDestination(icon: Icon(Icons.edit), label: '记录'),
          NavigationDestination(icon: Icon(Icons.calendar_today), label: '打卡'),
          NavigationDestination(icon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }
}
