import 'package:flutter/material.dart';

class InputField extends StatelessWidget {
  final String title;
  final String hint;
  final TextEditingController? controller;
  final Widget? widget;
  final VoidCallback? onTap;

  const InputField({
    Key? key,
    required this.title,
    required this.hint,
    this.controller,
    this.widget,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors
                  .deepPurple, // Match the deepPurple color for consistency
            ),
          ),
          const SizedBox(height: 2),
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 226, 219, 240),
              border: Border.all(color: Colors.deepPurple, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium, // Match your app's body text style
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: Theme.of(context)
                          .textTheme
                          .bodyMedium, // Match your app's body text style
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onTap: onTap,
                  ),
                ),
                if (widget != null) widget!,
              ],
            ),
          ),
        ],
      ),
    );
  }
}