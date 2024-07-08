import 'package:flutter/material.dart';

class FlashcardWidget extends StatefulWidget {
  final String question;
  final String answer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  FlashcardWidget({
    required this.question,
    required this.answer,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  _FlashcardWidgetState createState() => _FlashcardWidgetState();
}

class _FlashcardWidgetState extends State<FlashcardWidget> {
  bool _showBack = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: widget.onDelete,
                  ),
                ],
              ),
              Text(
                _showBack ? 'Answer:' : 'Question:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(_showBack ? widget.answer : widget.question),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showBack = !_showBack;
                      });
                    },
                    child: Text(_showBack ? 'Show Front' : 'Show Back'),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: widget.onEdit,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
