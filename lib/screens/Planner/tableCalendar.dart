import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class TableCalendarWidget extends StatefulWidget {
  final DateTime selectedDay;
  final CalendarFormat calendarFormat;
  final Map<DateTime, List<Map<String, dynamic>>> events;
  final Function(DateTime) onDaySelected;

  const TableCalendarWidget({
    Key? key,
    required this.selectedDay,
    required this.calendarFormat,
    required this.events,
    required this.onDaySelected,
  }) : super(key: key);

  @override
  _TableCalendarWidgetState createState() => _TableCalendarWidgetState();
}

class _TableCalendarWidgetState extends State<TableCalendarWidget> {
  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      focusedDay: widget.selectedDay,
      firstDay: DateTime(2000),
      lastDay: DateTime(2100),
      calendarFormat: widget.calendarFormat,
      selectedDayPredicate: (day) => isSameDay(widget.selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        widget.onDaySelected(selectedDay);
      },
      eventLoader: (day) {
        DateTime roundedDate = DateTime(day.year, day.month, day.day);
        return widget.events[roundedDate] ?? [];
      },
      onFormatChanged: (format) {
        setState(() {
          // Update calendar format
        });
      },
      availableCalendarFormats: const {
        CalendarFormat.week: 'Week',
      },
      calendarStyle: CalendarStyle(
        markersAlignment: Alignment.bottomCenter,
        todayDecoration: BoxDecoration(
          color: Colors.deepPurple.shade400,
          shape: BoxShape.circle,
        ),
        selectedDecoration: const BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: const TextStyle(color: Colors.white),
        todayTextStyle: const TextStyle(color: Colors.white),
      ),
      daysOfWeekStyle: const DaysOfWeekStyle(
        weekendStyle: TextStyle(color: Colors.red),
      ),
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
    );
  }
}
