import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';
import 'task_detail_screen.dart';
import 'add_task_screen.dart';

class KanbanScreen extends StatefulWidget {
  const KanbanScreen({super.key});

  @override
  State<KanbanScreen> createState() => _KanbanScreenState();
}

class _KanbanScreenState extends State<KanbanScreen> {
  final ScrollController _scrollController = ScrollController();

  final List<String> _columns = ['pending', 'in_progress', 'review', 'completed'];
  final Map<String, String> _columnTitles = {
    'pending': 'To Do',
    'in_progress': 'In Progress',
    'review': 'Review',
    'completed': 'Done',
  };

  final Map<String, Color> _columnColors = {
    'pending': AppTheme.warningColor,
    'in_progress': AppTheme.infoColor,
    'review': AppTheme.secondaryColor,
    'completed': AppTheme.successColor,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await context.read<TaskProvider>().loadTasks();
  }

  Future<void> _moveTask(Task task, String newStatus) async {
    await context.read<TaskProvider>().updateTask(task.id, {'status': newStatus});
  }

  void _showStatusMenu(Task task, BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Navigator.of(this.context).overlay!.context.findRenderObject() as RenderBox;
    final Offset position = button.localToGlobal(Offset.zero, ancestor: overlay);

    showMenu<String>(
      context: this.context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + button.size.height,
        overlay.size.width - position.dx - button.size.width,
        0,
      ),
      items: _columns.map((status) {
        return PopupMenuItem<String>(
          value: status,
          enabled: status != task.status,
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _columnColors[status],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(_columnTitles[status]!),
              if (status == task.status) ...[
                const Spacer(),
                const Icon(Icons.check, size: 18),
              ],
            ],
          ),
        );
      }).toList(),
    ).then((value) {
      if (value != null && value != task.status) {
        _moveTask(task, value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kanban Board'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, _) {
          if (taskProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final allTasks = taskProvider.tasks;

          return ListView(
            scrollDirection: Axis.horizontal,
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            children: _columns.map((status) {
              final tasks = allTasks.where((t) => t.status == status).toList();
              return _buildColumn(status, tasks, isDark);
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const AddTaskScreen()),
          );
          if (result == true) {
            _loadData();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildColumn(String status, List<Task> tasks, bool isDark) {
    final color = _columnColors[status]!;
    final title = _columnTitles[status]!;

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Tasks List
          Expanded(
            child: tasks.isEmpty
                ? _buildEmptyColumn(status, isDark)
                : ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      return _buildTaskCard(tasks[index], status, isDark, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyColumn(String status, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: isDark ? AppTheme.darkTextHint : AppTheme.lightTextHint,
          ),
          const SizedBox(height: 8),
          Text(
            'No tasks',
            style: TextStyle(
              color: isDark ? AppTheme.darkTextHint : AppTheme.lightTextHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Task task, String status, bool isDark, int index) {
    final category = context.read<TaskProvider>().getCategoryById(task.categoryId);

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => TaskDetailScreen(taskId: task.id),
          ),
        );
        if (result == true) {
          _loadData();
        }
      },
      onLongPress: () => _showStatusMenu(task, context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              task.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            if (task.description != null && task.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                task.description!,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 12),

            // Priority & Category Row
            Row(
              children: [
                // Priority Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.getPriorityColor(task.priority).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    task.priority.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.getPriorityColor(task.priority),
                    ),
                  ),
                ),

                // Category
                if (category != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _parseColor(category.color).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      category.name,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: _parseColor(category.color),
                      ),
                    ),
                  ),
                ],
              ],
            ),

            // Due Date
            if (task.dueDate != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 12,
                    color: task.isOverdue
                        ? AppTheme.errorColor
                        : (isDark ? AppTheme.darkTextHint : AppTheme.lightTextHint),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM d').format(task.dueDate!),
                    style: TextStyle(
                      fontSize: 11,
                      color: task.isOverdue
                          ? AppTheme.errorColor
                          : (isDark ? AppTheme.darkTextHint : AppTheme.lightTextHint),
                    ),
                  ),
                ],
              ),
            ],

            // Subtasks Count
            if (task.subtasks.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.checklist,
                    size: 12,
                    color: isDark ? AppTheme.darkTextHint : AppTheme.lightTextHint,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${task.subtasks.where((s) => s.completed).length}/${task.subtasks.length}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppTheme.darkTextHint : AppTheme.lightTextHint,
                    ),
                  ),
                ],
              ),
            ],

            // Recurring Indicator
            if (task.isRecurring) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.repeat,
                    size: 12,
                    color: AppTheme.infoColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    task.recurrencePattern ?? 'Recurring',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.infoColor,
                    ),
                  ),
                ],
              ),
            ],

            // Move hint
            const SizedBox(height: 12),
            Text(
              'Long press to move',
              style: TextStyle(
                fontSize: 10,
                fontStyle: FontStyle.italic,
                color: isDark ? AppTheme.darkTextHint : AppTheme.lightTextHint,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: index * 50)).slideX(begin: 0.1, end: 0);
  }

  Color _parseColor(String colorHex) {
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppTheme.primaryColor;
    }
  }
}
