import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool small;

  const StatusBadge({super.key, required this.status, this.small = false});

  @override
  Widget build(BuildContext context) {
    final (color, label, icon) = _getStatusData();
    
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

  (Color, String, IconData) _getStatusData() {
    switch (status.toLowerCase()) {
      case 'completed':
        return (const Color(0xFF10B981), 'Done', Icons.check_circle);
      case 'in_progress':
        return (const Color(0xFF3B82F6), 'Progress', Icons.trending_up);
      case 'pending':
      default:
        return (const Color(0xFFF59E0B), 'Pending', Icons.pending);
    }
  }
}
