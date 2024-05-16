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
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: Colors.deepPurple),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.deepPurple),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.deepPurple, width: 2.0),
        ),
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
      ),
      validator: validator,
    );
  }
}
