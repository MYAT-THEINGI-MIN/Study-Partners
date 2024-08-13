import 'package:flutter/material.dart';

class TimerDisplay extends StatelessWidget {
  final int elapsedTime;

  TimerDisplay({required this.elapsedTime});

  String _formatTime(int timeInSeconds) {
    int hours = timeInSeconds ~/ 3600;
    int minutes = (timeInSeconds % 3600) ~/ 60;
    int seconds = timeInSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blue[100],
      ),
      child: Center(
        child: Text(
          _formatTime(elapsedTime),
          style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class TimerRunningButtons extends StatelessWidget {
  final VoidCallback onStartBreak;
  final VoidCallback onEndTimer;

  TimerRunningButtons({required this.onStartBreak, required this.onEndTimer});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: onStartBreak,
          child: Text('Take a Break'),
        ),
        SizedBox(width: 20),
        ElevatedButton(
          onPressed: onEndTimer,
          child: Text('End Timer'),
        ),
      ],
    );
  }
}

class TimerBreakButtons extends StatelessWidget {
  final VoidCallback onEndBreak;
  final VoidCallback onEndTimer;

  TimerBreakButtons({required this.onEndBreak, required this.onEndTimer});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: onEndBreak,
          child: Text('End Break'),
        ),
        SizedBox(width: 20),
        ElevatedButton(
          onPressed: onEndTimer,
          child: Text('End Timer'),
        ),
      ],
    );
  }
}
