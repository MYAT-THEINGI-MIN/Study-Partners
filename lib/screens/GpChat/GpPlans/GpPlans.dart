import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sp_test/screens/GpChat/GpPlans/PlanCard.dart';
import 'package:sp_test/screens/GpChat/GpPlans/addNewGpPlan.dart';

class GpPlans extends StatelessWidget {
  final String groupId;

  GpPlans({required this.groupId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Group Plans'),
        actions: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton(
              child: Text("+ Add New Plan"),
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
            .orderBy('deadline')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No plans available'));
          }

          List<DocumentSnapshot> plans = snapshot.data!.docs;

          return ListView.builder(
            itemCount: plans.length,
            itemBuilder: (context, index) {
              var plan = plans[index];
              String planId = plan.id; // Get the planId from the document ID
              String title = plan['title'];
              String description = plan['description'];
              String creatorName =
                  plan['username']; // Ensure this matches Firestore field name
              DateTime deadline = (plan['deadline'] as Timestamp).toDate();

              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: PlanCard(
                  planId: planId,
                  groupId: groupId,
                  title: title,
                  description: description,
                  creatorName: creatorName,
                  deadline: deadline,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
