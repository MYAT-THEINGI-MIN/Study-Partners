import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sp_test/screens/GpChat/GpPlans/PlanCard.dart';
import 'package:sp_test/screens/GpChat/GpPlans/addNewGpPlan.dart';

import 'package:sp_test/screens/GpChat/GpPlans/planDetailPg.dart'; // Import the PlanDetailPage

class GpPlans extends StatelessWidget {
  final String groupId;

  GpPlans({required this.groupId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Plans'),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton(
              child: const Text("Add New Plan"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => AddNewPlan(groupId: groupId)),
                );
              },
            ),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('groups')
            .doc(groupId)
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

          return ListView.builder(
            itemCount: plans.length,
            itemBuilder: (context, index) {
              var plan = plans[index];
              String planId = plan.id; // Get the planId from the document ID

              var planData = plan.data() as Map<String, dynamic>?;

              // Check if planData is not null and the expected fields are present
              if (planData != null &&
                  planData.containsKey('planName') &&
                  planData.containsKey('username') &&
                  planData.containsKey('deadline') &&
                  planData.containsKey('tasks')) {
                try {
                  String planName = planData['planName'] ?? 'No name';
                  String creatorName = planData['username'] ?? 'Unknown';
                  DateTime deadline =
                      DateTime.tryParse(planData['deadline'] ?? '') ??
                          DateTime.now();

                  // Ensure tasks field is a list of maps
                  List tasks = planData['tasks'] as List;
                  int taskCount =
                      tasks.whereType<Map<String, dynamic>>().length;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 8.0),
                    child: PlanCard(
                      planId: planId,
                      groupId: groupId,
                      planName: planName,
                      username: creatorName,
                      deadline: deadline,
                      taskCount: taskCount,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlanDetailPage(
                              title: planName,
                              description:
                                  planData['description'] ?? 'No description',
                              deadline: deadline,
                              planId: planId,
                              groupId: groupId,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                } catch (e) {
                  // Log the error for debugging
                  print('Error processing plan data: $e');
                  return const Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                    child: Text('Error displaying plan'),
                  );
                }
              } else {
                // Log or print the document data for debugging
                print('Invalid plan data: ${plan.data()}');
                return const Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Text('Invalid plan data'),
                );
              }
            },
          );
        },
      ),
    );
  }
}
