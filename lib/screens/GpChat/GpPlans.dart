import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sp_test/screens/GpChat/addNewGpPlan.dart';
import 'package:sp_test/screens/GpChat/planCard.dart';

class GpPlans extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Group Plans'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              // Navigate to the AddNewPlan page
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddNewPlan()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('groups')
            .doc('YOUR_GROUP_ID') // Replace with actual group ID
            .collection('plans')
            .orderBy('deadline') // Assuming you have a 'deadline' field
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No plans available'));
          }

          // Extract the plans from the snapshot
          List<DocumentSnapshot> plans = snapshot.data!.docs;

          return ListView.builder(
            itemCount: plans.length,
            itemBuilder: (context, index) {
              var plan = plans[index];
              String title = plan['title'];
              String description = plan['description'];
              DateTime deadline = (plan['deadline'] as Timestamp).toDate();

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: PlanCard(
                  title: title,
                  description: description,
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
