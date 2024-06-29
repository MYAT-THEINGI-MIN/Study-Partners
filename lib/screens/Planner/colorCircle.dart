import 'package:flutter/material.dart';

class ColorCircle extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const ColorCircle({
    required this.color,
    required this.isSelected,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.deepPurple : Colors.transparent,
            width: isSelected ? 2.0 : 0.0,
          ),
        ),
        child: CircleAvatar(
          backgroundColor: color,
          radius: 20,
          child: isSelected
              ? Icon(
                  Icons.check,
                  size: 20,
                  color: Colors.white,
                )
              : null,
        ),
      ),
    );
  }
}
