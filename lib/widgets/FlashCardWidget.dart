import 'package:flutter/material.dart';

class FlashcardWidget extends StatelessWidget {
  final String question;
  final String answer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isHighlighted;

  FlashcardWidget({
    required this.question,
    required this.answer,
    required this.onEdit,
    required this.onDelete,
    this.isHighlighted = false, // Default value for isHighlighted
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color:
          isHighlighted ? Colors.blue[200] : Colors.white, // Highlight the card
      child: ListTile(
        title: Text(question),
        subtitle: Text(answer),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: onEdit,
            ),
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
