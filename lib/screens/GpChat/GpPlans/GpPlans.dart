import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sp_test/screens/GpChat/GpPlans/PlanCard.dart';
import 'package:sp_test/screens/GpChat/GpPlans/addNewGpPlan.dart';

class GpPlans extends StatefulWidget {
  final String groupId;

  GpPlans({required this.groupId});

  @override
  _GpPlansState createState() => _GpPlansState();
}

class _GpPlansState extends State<GpPlans> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Group Plans'),
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'Passed Deadline'),
              Tab(text: 'Current Plans'),
            ],
          ),
          actions: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton(
                child: const Text("Add New Plan"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddNewPlan(groupId: widget.groupId),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildTasksView(true), // Passed Deadline
            _buildTasksView(false), // Current Plans
          ],
        ),
      ),
    );
  }

  Widget _buildTasksView(bool showPassedDeadline) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('plans')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No plans available'));
        }

        List<DocumentSnapshot> plans = snapshot.data!.docs;

        List<Widget> planWidgets = [];

        DateTime now = DateTime.now();
        DateTime startOfToday = DateTime(now.year, now.month, now.day);

        for (var plan in plans) {
          var planData = plan.data() as Map<String, dynamic>?;

          if (planData != null) {
            try {
              String planName = planData['planName'] ?? 'No name';
              String creatorName = planData['username'] ?? 'Unknown';
              List<Map<String, dynamic>> tasks =
                  List<Map<String, dynamic>>.from(planData['tasks'] ?? []);

              List<Map<String, dynamic>> filteredTasks = [];

              for (var task in tasks) {
                DateTime taskDeadline = DateTime.parse(task['deadline']);
                if ((showPassedDeadline &&
                        taskDeadline.isBefore(startOfToday)) ||
                    (!showPassedDeadline &&
                        (taskDeadline.isAfter(startOfToday) ||
                            taskDeadline.isAtSameMomentAs(startOfToday)))) {
                  filteredTasks.add(task);
                }
              }

              filteredTasks.sort((a, b) => DateTime.parse(a['deadline'])
                  .compareTo(DateTime.parse(b['deadline'])));

              DateTime latestDeadline = startOfToday;
              if (filteredTasks.isNotEmpty) {
                latestDeadline = DateTime.parse(filteredTasks.last['deadline']);
              }

              if (showPassedDeadline && filteredTasks.isNotEmpty) {
                planWidgets.add(Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 8.0),
                  child: PlanCard(
                    planId: plan.id,
                    groupId: widget.groupId,
                    planName: planName,
                    username: creatorName,
                    deadline: latestDeadline,
                    taskCount: filteredTasks.length,
                    tasks: filteredTasks,
                  ),
                ));
              } else if (!showPassedDeadline && filteredTasks.isNotEmpty) {
                planWidgets.add(Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 8.0),
                  child: PlanCard(
                    planId: plan.id,
                    groupId: widget.groupId,
                    planName: planName,
                    username: creatorName,
                    deadline: latestDeadline,
                    taskCount: filteredTasks.length,
                    tasks: filteredTasks,
                  ),
                ));
              }
            } catch (e) {
              print('Error processing plan data: $e');
              planWidgets.add(const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Text('Error displaying plan'),
              ));
            }
          } else {
            print('Invalid plan data: ${plan.data()}');
            planWidgets.add(const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Text('Invalid plan data'),
            ));
          }
        }

        if (planWidgets.isEmpty) {
          return const Center(child: Text('No plans available'));
        }

        return ListView(children: planWidgets);
      },
    );
  }
}
