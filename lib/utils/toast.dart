import 'package:flutter/material.dart';

/// 居中显示的 Toast 提示
class Toast {
  static OverlayEntry? _currentToast;

  /// 显示 Toast
  /// [context] BuildContext
  /// [message] 提示消息
  /// [duration] 显示时长，默认 2 秒
  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(milliseconds: 2000),
  }) {
    // 如果已有 Toast，先移除
    hide();

    final overlay = Overlay.of(context);
    _currentToast = OverlayEntry(
      builder: (context) => Center(
        child: IgnorePointer(
          child: Material(
            color: Colors.transparent,
            child: AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_currentToast!);

    // 自动隐藏
    Future.delayed(duration, () {
      hide();
    });
  }

  /// 隐藏当前 Toast
  static void hide() {
    if (_currentToast != null) {
      _currentToast!.remove();
      _currentToast = null;
    }
  }
}
