import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
        DateTime now = DateTime.now();
        DateTime startOfToday = DateTime(now.year, now.month, now.day);

        List<Widget> planWidgets = plans.map((plan) {
          var planData = plan.data() as Map<String, dynamic>?;

          if (planData == null) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Text('Invalid plan data'),
            );
          }

          try {
            String planName = planData['planName'] ?? 'No name';
            String creatorName = planData['username'] ?? 'Unknown';
            String description = planData['description'] ??
                'No description available'; // Extract description
            String note =
                planData['note'] ?? 'No note available'; // Extract note
            List<Map<String, dynamic>> tasks =
                List<Map<String, dynamic>>.from(planData['tasks'] ?? []);

            List<Map<String, dynamic>> filteredTasks = tasks.where((task) {
              DateTime taskDeadline = DateTime.parse(task['deadline']);
              return (showPassedDeadline &&
                      taskDeadline.isBefore(startOfToday)) ||
                  (!showPassedDeadline &&
                      (taskDeadline.isAfter(startOfToday) ||
                          taskDeadline.isAtSameMomentAs(startOfToday)));
            }).toList();

            filteredTasks.sort((a, b) => DateTime.parse(a['deadline'])
                .compareTo(DateTime.parse(b['deadline'])));

            DateTime latestDeadline = filteredTasks.isNotEmpty
                ? DateTime.parse(filteredTasks.last['deadline'])
                : startOfToday;

            if (filteredTasks.isEmpty) {
              return SizedBox.shrink(); // No need to display empty plans
            }

            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: PlanCard(
                planId: plan.id,
                groupId: widget.groupId,
                planName: planName,
                username: creatorName,
                deadline: latestDeadline,
                taskCount: filteredTasks.length,
                tasks: filteredTasks,
                description: description, // Pass the description
                note: note, // Pass the note
              ),
            );
          } catch (e) {
            print('Error processing plan data: $e');
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Text('Error displaying plan'),
            );
          }
        }).toList();

        planWidgets.removeWhere((widget) => widget is SizedBox);

        if (planWidgets.isEmpty) {
          return const Center(child: Text('No plans available'));
        }

        return ListView(children: planWidgets);
      },
    );
  }
}
