import 'package:flutter/material.dart';

class PriorityBadge extends StatelessWidget {
  final String priority;
  final bool small;

  const PriorityBadge({super.key, required this.priority, this.small = false});

  @override
  Widget build(BuildContext context) {
    final (color, label, icon) = _getPriorityData();
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 6 : 10, vertical: small ? 3 : 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(small ? 4 : 8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: small ? 12 : 14, color: color),
          SizedBox(width: small ? 2 : 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: small ? 10 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  (Color, String, IconData) _getPriorityData() {
    switch (priority.toLowerCase()) {
      case 'high':
        return (const Color(0xFFEF4444), 'High', Icons.arrow_upward);
      case 'medium':
        return (const Color(0xFFF59E0B), 'Medium', Icons.remove);
      case 'low':
        return (const Color(0xFF10B981), 'Low', Icons.arrow_downward);
      default:
        return (const Color(0xFF9CA3AF), 'None', Icons.remove);
    }
  }
}
