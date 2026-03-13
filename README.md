# TaskMaster Pro - Flutter App

A comprehensive, beautiful task management application with advanced features including sub-tasks, recurring tasks, categories, and smart reminders.

## Features

### Task Management
- Create, edit, and delete tasks with rich details
- Add unlimited sub-tasks with full feature support (title, description, due date, recurring, reminders)
- Set task priorities (Low, Medium, High) with visual indicators
- Track task status (Pending, In Progress, Completed)
- Assign tasks to categories and sub-categories
- Add tags for better organization
- Set estimated completion time

### Scheduling
- Single and recurring task scheduling
- Recurrence patterns: Daily, Weekly, Monthly
- Set recurrence intervals and end dates
- Easy reschedule functionality
- Due date and time tracking
- Visual overdue indicators

### Smart Reminders
- Customizable reminder times
- Multiple reminder types
- Local push notifications
- Never miss an important task

### Categories
- Create custom categories with colors and icons
- Hierarchical category structure (main categories and subcategories)
- Filter tasks by category
- Beautiful category chips

### Beautiful UI
- Clean, modern design with proper spacing
- Dark and light theme support
- Smooth animations and transitions
- Intuitive navigation with bottom navigation bar
- Card-based layouts
- Swipe actions for quick task completion/deletion
- Full-page task detail view
- Pull-to-refresh functionality

### Technical Features
- Secure authentication with JWT tokens
- Offline support with local caching
- Backend powered by Cloudflare Workers
- D1 SQLite database
- Responsive design for all screen sizes

## Project Structure

```
lib/
├── config/
│   └── api_config.dart       # API endpoints configuration
├── models/
│   ├── user.dart             # User model
│   ├── task.dart             # Task and Category models
│   └── subtask.dart          # SubTask model
├── providers/
│   ├── auth_provider.dart    # Authentication state
│   ├── task_provider.dart    # Task management state
│   ├── category_provider.dart # Category state
│   └── theme_provider.dart   # Theme management
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── home/
│   │   └── home_screen.dart
│   ├── tasks/
│   │   ├── task_list_screen.dart
│   │   ├── task_detail_screen.dart
│   │   ├── add_task_screen.dart
│   │   └── add_subtask_screen.dart
│   ├── categories/
│   │   └── category_screen.dart
│   ├── settings/
│   │   └── settings_screen.dart
│   └── splash_screen.dart
├── services/
│   ├── api_service.dart      # API communication
│   ├── storage_service.dart  # Secure storage
│   └── notification_service.dart
├── widgets/
│   ├── task_card.dart
│   ├── priority_badge.dart
│   ├── status_badge.dart
│   ├── category_chip.dart
│   ├── stat_card.dart
│   ├── empty_state.dart
│   └── loading_indicator.dart
├── utils/
│   └── constants.dart
└── main.dart
```

## Getting Started

1. Clone the repository
2. Navigate to `flutter_app` directory
3. Run `flutter pub get`
4. Run `flutter run` to start the app

## Building APK

### Local Build
```bash
cd flutter_app
flutter build apk --release
```

### GitHub Actions
The project includes a GitHub Actions workflow that automatically builds APK and App Bundle on push to main/master branch.

## API Backend

The backend is powered by Cloudflare Workers with D1 database. API endpoints:
- POST `/api/auth/register` - User registration
- POST `/api/auth/login` - User login
- GET `/api/auth/me` - Get current user
- GET `/api/tasks` - Get all tasks
- POST `/api/tasks` - Create task
- PUT `/api/tasks/:id` - Update task
- DELETE `/api/tasks/:id` - Delete task
- GET `/api/categories` - Get categories
- POST `/api/categories` - Create category
- GET `/api/statistics` - Get task statistics

## License

MIT License
