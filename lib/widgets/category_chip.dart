import 'package:flutter/material.dart';

class CategoryChip extends StatelessWidget {
  final String name;
  final String color;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const CategoryChip({
    super.key,
    required this.name,
    required this.color,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
  });

  Color get _color {
    try {
      return Color(int.parse(color.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF6366F1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? _color : _color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : _color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                name,
                style: TextStyle(
                  color: isSelected ? Colors.white : _color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
