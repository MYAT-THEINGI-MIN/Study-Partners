import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PlanDetailPage extends StatelessWidget {
  final String planId;
  final String groupId;
  final String title;
  final String description;
  final DateTime deadline;

  PlanDetailPage({
    required this.planId,
    required this.groupId,
    required this.title,
    required this.description,
    required this.deadline,
  });

  Future<bool> _isCurrentUserCreator() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return false;
    }

    final planDoc = await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('plans')
        .doc(planId)
        .get();

    if (planDoc.exists) {
      final planData = planDoc.data();
      return planData != null && planData['uid'] == user.uid;
    }
    return false;
  }

  void _deletePlan(BuildContext context) async {
    await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('plans')
        .doc(planId)
        .delete();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Plan deleted successfully')),
    );
    Navigator.of(context).pop();
  }

  Widget _buildAttachmentPreview(Map<String, dynamic>? planData) {
    if (planData == null ||
        planData['creatorAttachment'] == null ||
        planData['attachmentType'] == null) {
      return Container();
    }

    final attachmentUrl = planData['creatorAttachment'];
    final attachmentType = planData['attachmentType'];

    switch (attachmentType) {
      case 'image':
        return Image.network(attachmentUrl, height: 200);
      case 'link':
        return GestureDetector(
          onTap: () async {
            if (await canLaunch(attachmentUrl)) {
              await launch(attachmentUrl);
            } else {
              print('Could not launch $attachmentUrl');
            }
          },
          child: Text(
            'Attachment Link: $attachmentUrl',
            style: TextStyle(
                color: Colors.blue, decoration: TextDecoration.underline),
          ),
        );
      default:
        return GestureDetector(
          onTap: () async {
            if (await canLaunch(attachmentUrl)) {
              await launch(attachmentUrl);
            } else {
              print('Could not launch $attachmentUrl');
            }
          },
          child: Text(
            'Attachment: ${attachmentUrl.split('/').last}',
            style: TextStyle(
                color: Colors.blue, decoration: TextDecoration.underline),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .collection('plans')
          .doc(planId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Plan Detail'),
            ),
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Plan Detail'),
            ),
            body: Center(
              child: Text('Plan not found'),
            ),
          );
        }

        final planData = snapshot.data!.data() as Map<String, dynamic>;
        final bool isCurrentUserCreator =
            planData['uid'] == FirebaseAuth.instance.currentUser?.uid;

        return Scaffold(
          appBar: AppBar(
            title: Text('Plan Detail'),
            actions: isCurrentUserCreator
                ? [
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () async {
                        bool confirm = await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Delete Plan'),
                            content: Text(
                                'Are you sure you want to delete this plan?'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                        );

                        if (confirm) {
                          _deletePlan(context);
                        }
                      },
                    ),
                  ]
                : null,
          ),
          body: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                SizedBox(height: 8),
                Text(description),
                SizedBox(height: 8),
                Text(
                  'Deadline: ${deadline.toString()}',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                SizedBox(height: 8),
                _buildAttachmentPreview(planData),
                // Add more details as needed
              ],
            ),
          ),
        );
      },
    );
  }
}
