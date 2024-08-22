import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:sp_test/screens/GpChat/Study%20Timer/timerWidget.dart';
import 'package:sp_test/widgets/circularIcon.dart';

class TimerPage extends StatefulWidget {
  final String groupId;

  TimerPage({required this.groupId});

  @override
  _TimerPageState createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  Timer? _timer;
  int _elapsedTime = 0;
  int _breakTime = 0;
  int _breakCount = 0;
  bool _isRunning = false;
  bool _isBreak = false;
  bool _isDeviceMoved = false;
  static const double _movementThreshold = 15;
  static const int _minimumStudyTimeForPoints = 15; // in minutes

  @override
  void initState() {
    super.initState();
    _startDeviceMotionListener();
  }

  void _startDeviceMotionListener() {
    accelerometerEvents.listen((AccelerometerEvent event) {
      if (!_isBreak && _isRunning) {
        double movementMagnitude =
            sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
        if (movementMagnitude > _movementThreshold) {
          if (!_isDeviceMoved) {
            _isDeviceMoved = true;
            _startBreak();
            _showMovementAlert();
          }
        } else {
          _isDeviceMoved = false;
        }
      }
    });
  }

  void _showMovementAlert() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Movement Detected'),
          content: const Text(
              'Significant movement detected, so you are in Break mode.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
      _isBreak = false;
      _isDeviceMoved = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedTime++;
      });
    });
  }

  void _startBreak() {
    setState(() {
      _isBreak = true;
      _breakCount++;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _breakTime++;
      });
    });
  }

  void _endBreakAndResumeTimer() {
    setState(() {
      _isBreak = false;
      _isDeviceMoved = false;
    });
    _timer?.cancel();
    _startTimer();
  }

  void _endTimer() {
    setState(() {
      _isRunning = false;
    });
    _timer?.cancel();
    _saveRecordToFirestore();
    _showRecordCard(context);
  }

  Future<void> _saveRecordToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Convert elapsed time to minutes
      final elapsedTimeInMinutes = _elapsedTime ~/ 60;

      // Save record only if study time exceeds 15 minutes
      if (elapsedTimeInMinutes > _minimumStudyTimeForPoints) {
        final studyRecord = {
          'userId': user.uid,
          'timestamp': Timestamp.now(),
          'totalTime': _elapsedTime,
          'totalBreaks': _breakCount,
          'breakTime': _breakTime,
          'formattedDate': DateFormat.yMMMd().add_jm().format(DateTime.now()),
        };

        try {
          print('Saving record to groupId: ${widget.groupId}');
          await FirebaseFirestore.instance
              .collection('groups')
              .doc(widget.groupId)
              .collection('StudyRecord')
              .add(studyRecord);

          print('Study record saved successfully!');

          // Calculate points starting from 16 minutes
          final points =
              max(0, elapsedTimeInMinutes - _minimumStudyTimeForPoints);

          // Update leaderboard points
          await _updateLeaderboardPoints(user.uid, points);
        } catch (e) {
          print('Error saving study record: $e');
        }
      } else {
        print('Study time does not exceed 15 minutes. Record not saved.');
      }
    } else {
      print('No user is currently logged in.');
    }

    // Update the group's last activity timestamp
    final groupRef =
        FirebaseFirestore.instance.collection('groups').doc(widget.groupId);
    await groupRef.update({
      'lastActivityTimestamp': Timestamp.now(),
    });
  }

  Future<void> _updateLeaderboardPoints(String userId, int points) async {
    try {
      // Navigate to the path for the LeaderBoard subcollection
      final leaderBoardCollection = FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('LeaderBoard');

      final leaderBoardDoc = await leaderBoardCollection
          .where('id', isEqualTo: userId)
          .limit(1)
          .get();

      if (leaderBoardDoc.docs.isNotEmpty) {
        final doc = leaderBoardDoc.docs.first;
        final currentPoints = doc['points'] as int;

        await doc.reference.update({
          'points': currentPoints + points,
        });

        print('Leaderboard points updated successfully!');
      } else {
        print('No Leader Board Exist.');
      }
    } catch (e) {
      print('Error updating leaderboard points: $e');
    }
  }

  void _showRecordCard(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Timer Summary'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total Time: ${_formatTime(_elapsedTime)}'),
              Text('Total Breaks: $_breakCount'),
              Text('Break Time: ${_formatTime(_breakTime)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetTimer();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _resetTimer() {
    setState(() {
      _elapsedTime = 0;
      _breakTime = 0;
      _breakCount = 0;
      _isRunning = false;
      _isBreak = false;
    });
  }

  String _formatTime(int timeInSeconds) {
    int hours = timeInSeconds ~/ 3600;
    int minutes = (timeInSeconds % 3600) ~/ 60;
    int seconds = timeInSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<bool> _onWillPop() async {
    if (_isRunning) {
      bool? shouldLeave = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Are you sure?'),
          content: const Text(
              'If you leave now, all your study time records will be lost.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes'),
            ),
          ],
        ),
      );
      return shouldLeave ?? false;
    }
    return true;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Study Timer'),
          // actions: [
          //   ElevatedButton(
          //     onPressed: () {
          //       Navigator.push(
          //         context,
          //         MaterialPageRoute(
          //           builder: (context) =>
          //               AllStudyRecordsList(groupId: widget.groupId),
          //         ),
          //       );
          //     },
          //     child: const Text('Records'),
          //   ),
          // ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TimerDisplay(elapsedTime: _elapsedTime),
              const SizedBox(height: 40),
              if (!_isRunning) ...[
                ElevatedButton(
                  onPressed: _startTimer,
                  child: const Text('Start Timer'),
                ),
              ],
              if (_isRunning && !_isBreak) ...[
                TimerRunningButtons(
                  onStartBreak: _startBreak,
                  onEndTimer: _endTimer,
                ),
              ],
              if (_isRunning && _isBreak) ...[
                TimerBreakButtons(
                  onEndBreak: _endBreakAndResumeTimer,
                  onEndTimer: _endTimer,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
