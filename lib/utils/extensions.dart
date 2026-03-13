import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'constants.dart';

/// DateTime Extensions
extension DateTimeExtensions on DateTime {
  /// Check if date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }
  
  /// Check if date is tomorrow
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year && 
           month == tomorrow.month && 
           day == tomorrow.day;
  }
  
  /// Check if date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && 
           month == yesterday.month && 
           day == yesterday.day;
  }
  
  /// Check if date is overdue
  bool get isOverdue => isBefore(DateTime.now());
  
  /// Check if date is in the past
  bool get isPast => isBefore(DateTime.now());
  
  /// Check if date is in the future
  bool get isFuture => isAfter(DateTime.now());
  
  /// Check if date is this week
  bool get isThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return isAfter(startOfWeek.subtract(const Duration(days: 1))) && 
           isBefore(endOfWeek.add(const Duration(days: 1)));
  }
  
  /// Check if date is this month
  bool get isThisMonth {
    final now = DateTime.now();
    return year == now.year && month == now.month;
  }
  
  /// Get start of day
  DateTime get startOfDay => DateTime(year, month, day);
  
  /// Get end of day
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);
  
  /// Get start of week (Monday)
  DateTime get startOfWeek => subtract(Duration(days: weekday - 1));
  
  /// Get end of week (Sunday)
  DateTime get endOfWeek => add(Duration(days: 7 - weekday));
  
  /// Get start of month
  DateTime get startOfMonth => DateTime(year, month, 1);
  
  /// Get end of month
  DateTime get endOfMonth => DateTime(year, month + 1, 0, 23, 59, 59, 999);
  
  /// Format date
  String format([String pattern = 'MMM dd, yyyy']) {
    return DateFormat(pattern).format(this);
  }
  
  /// Format time
  String formatTime([String pattern = 'HH:mm']) {
    return DateFormat(pattern).format(this);
  }
  
  /// Get relative date string
  String get relativeDate {
    if (isToday) return 'Today';
    if (isTomorrow) return 'Tomorrow';
    if (isYesterday) return 'Yesterday';
    if (isThisWeek) return DateFormat('EEEE').format(this);
    return format();
  }
  
  /// Get days from now
  int get daysFromNow {
    return difference(DateTime.now()).inDays;
  }
  
  /// Copy with time
  DateTime copyWithTime({int? hour, int? minute, int? second}) {
    return DateTime(
      year, month, day,
      hour ?? this.hour,
      minute ?? this.minute,
      second ?? second ?? this.second,
    );
  }
}

/// String Extensions
extension StringExtensions on String {
  /// Capitalize first letter
  String get capitalize {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
  
  /// Capitalize each word
  String get capitalizeWords {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize).join(' ');
  }
  
  /// Check if string is null or empty
  bool get isNullOrEmpty => isEmpty;
  
  /// Check if string is not null or empty
  bool get isNotNullOrEmpty => isNotEmpty;
  
  /// Truncate with ellipsis
  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}$ellipsis';
  }
  
  /// Format status (snake_case to Title Case)
  String get formatStatus {
    return split('_').map((word) => word.capitalize).join(' ');
  }
  
  /// Get initials
  String get initials {
    final words = trim().split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '';
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }
  
  /// Parse hex color
  Color get toColor {
    try {
      final hex = replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return AppColors.primary;
    }
  }
  
  /// Check if valid email
  bool get isValidEmail {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }
  
  /// Check if valid phone
  bool get isValidPhone {
    return RegExp(r'^\+?[\d\s-]{10,}$').hasMatch(this);
  }
}

/// Nullable String Extensions
extension NullableStringExtensions on String? {
  /// Check if null or empty
  bool get isNullOrEmpty => this == null || this!.isEmpty;
  
  /// Check if not null or empty
  bool get isNotNullOrEmpty => this != null && this!.isNotEmpty;
  
  /// Return or default
  String orDefault(String defaultValue) {
    return isNullOrEmpty ? defaultValue : this!;
  }
}

/// Color Extensions
extension ColorExtensions on Color {
  /// Convert to hex string
  String get toHex {
    return '#${value.toRadixString(16).substring(2).toUpperCase()}';
  }
  
  /// Lighten color
  Color lighten([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
  
  /// Darken color
  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
  
  /// Get contrasting text color
  Color get contrastingColor {
    final luminance = computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
  
  /// With opacity
  Color withOpacityValue(double opacity) {
    return withOpacity(opacity);
  }
}

/// Widget Extensions
extension WidgetExtensions on Widget {
  /// Add padding
  Widget padding(EdgeInsets padding) {
    return Padding(padding: padding, child: this);
  }
  
  /// Add symmetric padding
  Widget paddingSymmetric({double horizontal = 0, double vertical = 0}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
      child: this,
    );
  }
  
  /// Add all padding
  Widget paddingAll(double value) {
    return Padding(padding: EdgeInsets.all(value), child: this);
  }
  
  /// Add horizontal padding
  Widget paddingHorizontal(double value) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: value),
      child: this,
    );
  }
  
  /// Add vertical padding
  Widget paddingVertical(double value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: value),
      child: this,
    );
  }
  
  /// Center widget
  Widget get center => Center(child: this);
  
  /// Expand widget
  Widget get expand => Expanded(child: this);
  
  /// Flexible widget
  Widget get flexible => Flexible(child: this);
  
  /// Add card decoration
  Widget card({
    Color? color,
    double borderRadius = 16,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: AppShadows.card,
      ),
      child: this,
    );
  }
  
  /// Add container with decoration
  Widget decorated(BoxDecoration decoration, {EdgeInsetsGeometry? padding}) {
    return Container(
      decoration: decoration,
      padding: padding,
      child: this,
    );
  }
  
  /// Make widget clickable
  Widget clickable({
    required VoidCallback onTap,
    BorderRadius? borderRadius,
    Color? splashColor,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        splashColor: splashColor ?? AppColors.primary.withOpacity(0.1),
        child: this,
      ),
    );
  }
}

/// Int Extensions
extension IntExtensions on int {
  /// Convert to duration in seconds
  Duration get seconds => Duration(seconds: this);
  
  /// Convert to duration in minutes
  Duration get minutes => Duration(minutes: this);
  
  /// Convert to duration in hours
  Duration get hours => Duration(hours: this);
  
  /// Convert to duration in days
  Duration get days => Duration(days: this);
  
  /// Format duration (minutes to readable string)
  String get formatDuration {
    if (this <= 0) return '0 min';
    if (this < 60) return '$this min';
    final hours = this ~/ 60;
    final remainingMinutes = this % 60;
    if (remainingMinutes == 0) return '$hours hr';
    return '$hours hr $remainingMinutes min';
  }
}

/// Double Extensions
extension DoubleExtensions on double {
  /// Format to percentage
  String toPercentage([int decimalPlaces = 0]) {
    return '${(this * 100).toStringAsFixed(decimalPlaces)}%';
  }
}

/// List Extensions
extension ListExtensions<T> on List<T> {
  /// Get first element or null
  T? get firstOrNull => isEmpty ? null : first;
  
  /// Get last element or null
  T? get lastOrNull => isEmpty ? null : last;
  
  /// Get element at index or null
  T? elementAtOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }
  
  /// Group by
  Map<K, List<T>> groupBy<K>(K Function(T) keySelector) {
    final map = <K, List<T>>{};
    for (final item in this) {
      final key = keySelector(item);
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  }
  
  /// Distinct by
  List<T> distinctBy<K>(K Function(T) selector) {
    final seen = <K>{};
    return where((item) => seen.add(selector(item))).toList();
  }
  
  /// Sort by
  List<T> sortedBy<K extends Comparable>(K Function(T) selector, {bool descending = false}) {
    final sorted = List<T>.from(this);
    sorted.sort((a, b) {
      final comparison = selector(a).compareTo(selector(b));
      return descending ? -comparison : comparison;
    });
    return sorted;
  }
}

/// BuildContext Extensions
extension BuildContextExtensions on BuildContext {
  /// Get theme
  ThemeData get theme => Theme.of(this);
  
  /// Get text theme
  TextTheme get textTheme => Theme.of(this).textTheme;
  
  /// Get color scheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  
  /// Check if dark mode
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  
  /// Get media query
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  
  /// Get screen size
  Size get screenSize => MediaQuery.of(this).size;
  
  /// Get screen width
  double get screenWidth => MediaQuery.of(this).size.width;
  
  /// Get screen height
  double get screenHeight => MediaQuery.of(this).size.height;
  
  /// Get keyboard height
  double get keyboardHeight => MediaQuery.of(this).viewInsets.bottom;
  
  /// Check if keyboard is visible
  bool get isKeyboardVisible => MediaQuery.of(this).viewInsets.bottom > 0;
  
  /// Show snackbar
  void showSnackBar(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
  
  /// Hide keyboard
  void hideKeyboard() {
    FocusScope.of(this).unfocus();
  }
}
