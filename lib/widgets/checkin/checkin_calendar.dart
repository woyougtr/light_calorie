import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../config/app_colors.dart';
import '../../config/app_theme.dart';

/// 打卡日历组件
class CheckInCalendar extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final Map<DateTime, List<String>> events;
  final Function(DateTime, DateTime) onDaySelected;
  final Function(DateTime) onPageChanged;

  const CheckInCalendar({
    super.key,
    required this.focusedDay,
    this.selectedDay,
    required this.events,
    required this.onDaySelected,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: TableCalendar(
          firstDay: DateTime(2024),
          lastDay: DateTime.now(),
          focusedDay: focusedDay,
          selectedDayPredicate: (day) => isSameDay(selectedDay, day),
          onDaySelected: onDaySelected,
          onPageChanged: onPageChanged,
          calendarFormat: CalendarFormat.month,
          availableCalendarFormats: const {
            CalendarFormat.month: 'Month',
          },
          headerStyle: HeaderStyle(
            titleCentered: true,
            formatButtonVisible: false,
            leftChevronIcon: Icon(Icons.chevron_left, color: AppTheme.textSecondary),
            rightChevronIcon: Icon(Icons.chevron_right, color: AppTheme.textSecondary),
            titleTextStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
            weekendStyle: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          calendarStyle: CalendarStyle(
            cellMargin: const EdgeInsets.all(4),
            defaultDecoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.background,
            ),
            weekendDecoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.background,
            ),
            selectedDecoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
            ),
            todayDecoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.2),
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            outsideDaysVisible: false,
            cellPadding: const EdgeInsets.all(8),
          ),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focusedDay) {
              return _buildDayCell(day, false);
            },
            todayBuilder: (context, day, focusedDay) {
              return _buildDayCell(day, true);
            },
            selectedBuilder: (context, day, focusedDay) {
              return _buildDayCell(day, isSameDay(day, DateTime.now()));
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDayCell(DateTime day, bool isToday) {
    final dateKey = DateTime(day.year, day.month, day.day);
    final dayEvents = events[dateKey] ?? [];

    // 判断打卡状态
    final hasDiet = dayEvents.contains('饮食');
    final hasWater = dayEvents.contains('饮水');
    final hasExercise = dayEvents.contains('运动');
    final hasCheckIn = dayEvents.isNotEmpty;

    // 选择图标 - 只有完成的日子才显示图标
    String? icon;
    Color? iconColor;

    if (hasDiet && hasWater && hasExercise) {
      // 全部完成：火焰
      icon = '🔥';
      iconColor = const Color(0xFFFF5722);
    } else if (hasDiet) {
      // 有饮食：餐具
      icon = '🍱';
      iconColor = const Color(0xFFFFA000);
    } else if (hasWater) {
      // 有饮水：水滴
      icon = '💧';
      iconColor = const Color(0xFF2196F3);
    } else if (hasExercise) {
      // 有运动：跑步
      icon = '🏃';
      iconColor = const Color(0xFF4CAF50);
    } else if (isToday) {
      // 今天但无记录：星星
      icon = '⭐';
      iconColor = AppColors.primary;
    }
    // 其他日子无记录：不显示图标

    return Container(
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.day}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              color: isToday ? AppColors.primary : AppTheme.textPrimary,
            ),
          ),
          if (icon != null) ...[
            const SizedBox(height: 2),
            Text(
              icon,
              style: TextStyle(fontSize: 14, color: iconColor),
            ),
          ],
        ],
      ),
    );
  }
}

/// 日历图例
class CalendarLegend extends StatelessWidget {
  const CalendarLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          _buildLegendItem('🔥', '全部完成', const Color(0xFFFF5722)),
          _buildLegendItem('🍱', '饮食', const Color(0xFFFFA000)),
          _buildLegendItem('💧', '饮水', const Color(0xFF2196F3)),
          _buildLegendItem('🏃', '运动', const Color(0xFF4CAF50)),
          _buildLegendItem('⭐', '今日', AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
