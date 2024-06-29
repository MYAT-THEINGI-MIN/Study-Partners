import 'package:flutter/material.dart';

class myButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const myButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      child: Text(label),
    );
  }
}
