import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:sp_test/screens/Planner/plannerPg.dart';

class TaskCard extends StatelessWidget {
  final DateTime selectedDay;
  final Map<DateTime, List<Task>> tasks;
  final Function(DateTime, int) onDeleteTask;
  final Function(Task, DateTime, int) onShowTaskDetails;
  final Function(Task) onToggleTaskCompletion;

  TaskCard({
    required this.selectedDay,
    required this.tasks,
    required this.onDeleteTask,
    required this.onShowTaskDetails,
    required this.onToggleTaskCompletion,
  });

  @override
  Widget build(BuildContext context) {
    List<Task> tasksForDay = tasks[selectedDay] ?? [];

    return AnimatedPositioned(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      left: 0,
      right: 0,
      bottom: tasksForDay.isNotEmpty ? 0 : -300, // Adjust as needed
      child: GestureDetector(
        onTap: () {
          // Toggle visibility of task card on tap
          // You can optionally handle tap events here
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Card(
            margin: EdgeInsets.all(8.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            elevation: 4.0,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(8.0),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tasks for ${DateFormat.yMMMd().format(selectedDay)}',
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromRGBO(156, 39, 176, 1),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () {
                              // Optionally handle close button tap
                            },
                          ),
                        ],
                      ),
                      Expanded(
                        child: tasksForDay.isNotEmpty
                            ? ListView.builder(
                                itemCount: tasksForDay.length,
                                itemBuilder: (context, index) {
                                  Task task = tasksForDay[index];
                                  double completionPercent =
                                      (task.completionPercent ?? 0) / 100;

                                  return Dismissible(
                                    key: UniqueKey(),
                                    background: Container(color: Colors.red),
                                    onDismissed: (direction) {
                                      onDeleteTask(selectedDay, index);
                                    },
                                    child: ListTile(
                                      leading: Checkbox(
                                        value: task.isDone,
                                        onChanged: (bool? value) {
                                          onToggleTaskCompletion(task);
                                        },
                                      ),
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              task.title,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Container(
                                            width: 30,
                                            height: 30,
                                            child: Stack(
                                              children: [
                                                CircularProgressIndicator(
                                                  value: completionPercent,
                                                  backgroundColor:
                                                      Colors.grey[300],
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(
                                                    Colors.green,
                                                  ),
                                                ),
                                                Center(
                                                  child: Text(
                                                    '${(task.completionPercent ?? 0).toStringAsFixed(0)}%',
                                                    style: TextStyle(
                                                      fontSize: 8,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      onTap: () {
                                        onShowTaskDetails(
                                            task, selectedDay, index);
                                      },
                                    ),
                                  );
                                },
                              )
                            : Center(
                                child: Text(
                                  "No tasks for ${DateFormat.yMMMd().format(selectedDay)}",
                                  style: const TextStyle(
                                    fontSize: 18.0,
                                    color: Colors.purple,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: FloatingActionButton(
                      onPressed: () {
                        // Optionally handle add task button tap
                      },
                      child: Icon(Icons.add),
                      backgroundColor: Colors.purple.shade100,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
