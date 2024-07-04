import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final bool obscureText;
  final Function() onSuffixIconPressed;
  final String? Function(String?)? validator;
  final bool showSuffixIcon; // New parameter to control suffix icon visibility

  CustomTextField({
    required this.controller,
    required this.labelText,
    this.obscureText = false,
    required this.onSuffixIconPressed,
    this.validator,
    this.showSuffixIcon = true, // Default value true to show the suffix icon
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
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
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
          // Conditionally show the suffix icon based on showSuffixIcon flag
          suffixIcon: showSuffixIcon
              ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility : Icons.visibility_off,
                    color: Colors.deepPurple,
                  ),
                  onPressed: onSuffixIconPressed,
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        validator: validator,
      ),
    );
  }
}
