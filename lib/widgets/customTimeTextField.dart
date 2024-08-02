import 'package:flutter/material.dart';

class CustomTimeTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final Function() onTap;
  final String? Function(String?)? validator;

  CustomTimeTextField({
    required this.controller,
    required this.labelText,
    required this.onTap,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bodyMedium = textTheme.bodyMedium;

    // Determine text color based on theme brightness
    Color textColor = Theme.of(context).brightness == Brightness.light
        ? Colors.black87 // Soft black for light theme
        : Colors.black; // Black for dark theme

    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: GestureDetector(
        onTap: onTap,
        child: AbsorbPointer(
          child: TextFormField(
            controller: controller,
            style: bodyMedium?.copyWith(
              color: textColor, // Set text color based on theme
            ),
            decoration: InputDecoration(
              labelText: labelText,
              labelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
              prefixIcon: const Icon(
                Icons.access_time,
                color: Colors.deepPurple,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.deepPurple, width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.deepPurple, width: 2.0),
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: const Color.fromARGB(255, 226, 219, 240),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            validator: validator,
          ),
        ),
      ),
    );
  }
}
