import 'package:flutter/material.dart';

/// App Constants
class AppConstants {
  // App Info
  static const String appName = 'Task Pro';
  static const String appVersion = '1.0.0';
  
  // API
  static const String baseUrl = 'https://taskmaster-api.walletsx.workers.dev';
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String themeKey = 'theme_mode';
  static const String onboardingKey = 'onboarding_complete';
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 350);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Pagination
  static const int defaultPageSize = 20;
  
  // Date Formats
  static const String dateFormat = 'MMM dd, yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'MMM dd, yyyy HH:mm';
}

/// App Colors
class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);
  
  // Gradient Colors
  static const List<Color> primaryGradient = [primary, primaryDark];
  static const List<Color> accentGradient = [Color(0xFF818CF8), Color(0xFF6366F1)];
  
  // Status Colors
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFF4ADE80);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFF87171);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFF60A5FA);
  
  // Priority Colors
  static const Color lowPriority = Color(0xFF22C55E);
  static const Color mediumPriority = Color(0xFFF59E0B);
  static const Color highPriority = Color(0xFFEF4444);
  
  // Status Colors
  static const Color pendingStatus = Color(0xFF9CA3AF);
  static const Color inProgressStatus = Color(0xFF3B82F6);
  static const Color completedStatus = Color(0xFF22C55E);
  
  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey50 = Color(0xFFF9FAFB);
  static const Color grey100 = Color(0xFFF3F4F6);
  static const Color grey200 = Color(0xFFE5E7EB);
  static const Color grey300 = Color(0xFFD1D5DB);
  static const Color grey400 = Color(0xFF9CA3AF);
  static const Color grey500 = Color(0xFF6B7280);
  static const Color grey600 = Color(0xFF4B5563);
  static const Color grey700 = Color(0xFF374151);
  static const Color grey800 = Color(0xFF1F2937);
  static const Color grey900 = Color(0xFF111827);
  
  // Background Colors
  static const Color backgroundLight = Color(0xFFF9FAFB);
  static const Color backgroundDark = Color(0xFF111827);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1F2937);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color textLight = Color(0xFFFFFFFF);
  
  // Helper methods
  static Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return lowPriority;
      case 'medium':
        return mediumPriority;
      case 'high':
        return highPriority;
      default:
        return mediumPriority;
    }
  }
  
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return pendingStatus;
      case 'in_progress':
        return inProgressStatus;
      case 'completed':
        return completedStatus;
      default:
        return pendingStatus;
    }
  }
}

/// Text Styles
class AppTextStyles {
  // Headings
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.3,
  );
  
  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );
  
  static const TextStyle heading4 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );
  
  // Body
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
  );
  
  // Labels
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );
  
  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
  );
  
  // Caption
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );
  
  // Button
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
  
  static const TextStyle buttonSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );
}

/// Border Radius
class AppBorderRadius {
  static const BorderRadius small = BorderRadius.all(Radius.circular(8));
  static const BorderRadius medium = BorderRadius.all(Radius.circular(12));
  static const BorderRadius large = BorderRadius.all(Radius.circular(16));
  static const BorderRadius xl = BorderRadius.all(Radius.circular(24));
  static const BorderRadius round = BorderRadius.all(Radius.circular(100));
}

/// Spacing
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Shadows
class AppShadows {
  static List<BoxShadow> small = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> medium = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> large = [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 30,
      offset: const Offset(0, 8),
    ),
  ];
  
  static List<BoxShadow> card = [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 15,
      offset: const Offset(0, 3),
    ),
  ];
}

/// Task Status Options
class TaskStatus {
  static const String pending = 'pending';
  static const String inProgress = 'in_progress';
  static const String completed = 'completed';
  
  static const List<String> values = [pending, inProgress, completed];
  
  static String getLabel(String status) {
    switch (status) {
      case pending:
        return 'Pending';
      case inProgress:
        return 'In Progress';
      case completed:
        return 'Completed';
      default:
        return 'Unknown';
    }
  }
}

/// Task Priority Options
class TaskPriority {
  static const String low = 'low';
  static const String medium = 'medium';
  static const String high = 'high';
  
  static const List<String> values = [low, medium, high];
  
  static String getLabel(String priority) {
    switch (priority) {
      case low:
        return 'Low';
      case medium:
        return 'Medium';
      case high:
        return 'High';
      default:
        return 'Unknown';
    }
  }
}

/// Recurrence Patterns
class RecurrencePattern {
  static const String daily = 'daily';
  static const String weekly = 'weekly';
  static const String monthly = 'monthly';
  
  static const List<String> values = [daily, weekly, monthly];
  
  static String getLabel(String pattern) {
    switch (pattern) {
      case daily:
        return 'Daily';
      case weekly:
        return 'Weekly';
      case monthly:
        return 'Monthly';
      default:
        return 'Unknown';
    }
  }
}

/// Reminder Types
class ReminderType {
  static const String notification = 'notification';
  static const String email = 'email';
  static const String both = 'both';
  
  static const List<String> values = [notification, email, both];
  
  static String getLabel(String type) {
    switch (type) {
      case notification:
        return 'Notification';
      case email:
        return 'Email';
      case both:
        return 'Both';
      default:
        return 'Unknown';
    }
  }
}
