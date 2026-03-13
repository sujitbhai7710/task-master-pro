// API Configuration
class ApiConfig {
  // Cloudflare Worker API URL
  static const String baseUrl = 'https://taskmaster-api.walletsx.workers.dev';
  
  // API Endpoints
  static const String health = '/api/health';
  
  // Auth endpoints
  static const String register = '/api/auth/register';
  static const String login = '/api/auth/login';
  static const String me = '/api/auth/me';
  static const String profile = '/api/auth/profile';
  
  // Task endpoints
  static const String tasks = '/api/tasks';
  static String task(String id) => '/api/tasks/$id';
  static String subtasks(String taskId) => '/api/tasks/$taskId/subtasks';
  static String subtask(String id) => '/api/subtasks/$id';
  
  // Category endpoints
  static const String categories = '/api/categories';
  static String category(String id) => '/api/categories/$id';
  
  // Statistics
  static const String statistics = '/api/statistics';
  
  // Notifications
  static const String notifications = '/api/notifications';
  static String notificationRead(String id) => '/api/notifications/$id/read';
  
  // Templates
  static const String templates = '/api/templates';
  
  // Search
  static const String search = '/api/search';
}
