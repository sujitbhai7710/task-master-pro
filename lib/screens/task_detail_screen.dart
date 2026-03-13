import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../models/subtask.dart';
import '../theme/app_theme.dart';
import 'edit_task_screen.dart';
import 'add_subtask_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  Task? _task;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTask();
  }

  Future<void> _loadTask() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final task = await context.read<TaskProvider>().getTask(widget.taskId);
      if (mounted) {
        setState(() {
          _task = task;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleSubtask(int index) async {
    if (_task == null || _task!.subtasks.isEmpty || index >= _task!.subtasks.length) return;

    final subtask = _task!.subtasks[index];
    await context.read<TaskProvider>().updateSubtask(
      subtask.id,
      {'completed': !subtask.completed},
    );
    _loadTask();
  }

  Future<void> _deleteSubtask(int index) async {
    if (_task == null || _task!.subtasks.isEmpty || index >= _task!.subtasks.length) return;

    final subtask = _task!.subtasks[index];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subtask'),
        content: Text('Delete "${subtask.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<TaskProvider>().deleteSubtask(subtask.id);
      _loadTask();
    }
  }

  Future<void> _editSubtask(int index) async {
    if (_task == null || _task!.subtasks.isEmpty || index >= _task!.subtasks.length) return;

    final subtask = _task!.subtasks[index];
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddSubtaskScreen(
          taskId: widget.taskId,
          existingSubtask: subtask.toJson(),
        ),
      ),
    );
    if (result == true) {
      _loadTask();
    }
  }

  Future<void> _deleteTask() async {
    if (_task == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${_task!.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<TaskProvider>().deleteTask(_task!.id);
      Navigator.pop(context, true);
    }
  }

  Future<void> _editTask() async {
    if (_task == null) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditTaskScreen(task: _task!),
      ),
    );
    if (result == true) {
      _loadTask();
    }
  }

  Future<void> _addSubtask() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddSubtaskScreen(taskId: widget.taskId),
      ),
    );
    if (result == true) {
      _loadTask();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          if (_task != null) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: _editTask,
              tooltip: 'Edit Task',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteTask,
              tooltip: 'Delete Task',
            ),
          ],
        ],
      ),
      body: _buildBody(isDark),
      floatingActionButton: _task != null
          ? FloatingActionButton.extended(
              onPressed: _addSubtask,
              icon: const Icon(Icons.add_task),
              label: const Text('Add Subtask'),
            )
          : null,
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
              const SizedBox(height: 16),
              Text(
                'Error loading task',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadTask,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_task == null) {
      return const Center(child: Text('Task not found'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title & Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _toggleTaskStatus(),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _task!.status == 'completed'
                        ? AppTheme.successColor
                        : Colors.transparent,
                    border: Border.all(
                      color: _task!.status == 'completed'
                          ? AppTheme.successColor
                          : AppTheme.getPriorityColor(_task!.priority),
                      width: 2,
                    ),
                  ),
                  child: _task!.status == 'completed'
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _task!.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    decoration: _task!.status == 'completed'
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Status Selection
          _buildSectionHeader('Status'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatusChip('Pending', 'pending', AppTheme.warningColor),
              _buildStatusChip('In Progress', 'in_progress', AppTheme.infoColor),
              _buildStatusChip('Review', 'review', AppTheme.secondaryColor),
              _buildStatusChip('Done', 'completed', AppTheme.successColor),
            ],
          ),

          const SizedBox(height: 24),

          // Description
          if (_task!.description != null && _task!.description!.isNotEmpty) ...[
            _buildSectionHeader('Description'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : AppTheme.lightSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF424242) : const Color(0xFFE0E0E0),
                ),
              ),
              child: Text(
                _task!.description!,
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Due Date
          if (_task!.dueDate != null) ...[
            _buildSectionHeader('Due Date'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : AppTheme.lightSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF424242) : const Color(0xFFE0E0E0),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: _task!.isOverdue
                        ? AppTheme.errorColor
                        : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    DateFormat('EEEE, MMMM d, y').format(_task!.dueDate!),
                    style: TextStyle(
                      color: _task!.isOverdue
                          ? AppTheme.errorColor
                          : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_task!.isOverdue) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Overdue',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.errorColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Priority
          _buildSectionHeader('Priority'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.getPriorityColor(_task!.priority).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.flag,
                  size: 18,
                  color: AppTheme.getPriorityColor(_task!.priority),
                ),
                const SizedBox(width: 8),
                Text(
                  _task!.priority[0].toUpperCase() + _task!.priority.substring(1),
                  style: TextStyle(
                    color: AppTheme.getPriorityColor(_task!.priority),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Category
          if (_task!.category != null) ...[
            _buildSectionHeader('Category'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _parseColor(_task!.category!.color).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _parseColor(_task!.category!.color),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _task!.category!.name,
                    style: TextStyle(
                      color: _parseColor(_task!.category!.color),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Recurring Info
          if (_task!.isRecurring) ...[
            _buildSectionHeader('Recurring'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.infoColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.infoColor.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.repeat, color: AppTheme.infoColor),
                      const SizedBox(width: 8),
                      Text(
                        'Repeats ${_task!.recurrencePattern ?? 'daily'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: AppTheme.infoColor,
                        ),
                      ),
                    ],
                  ),
                  if (_task!.recurrenceInterval != null && _task!.recurrenceInterval! > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Every ${_task!.recurrenceInterval} ${_task!.recurrencePattern}(s)',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                    ),
                  if (_task!.recurrenceEndDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Until ${DateFormat('MMM d, y').format(_task!.recurrenceEndDate!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Reminder Info
          if (_task!.reminderEnabled && _task!.reminderTime != null) ...[
            _buildSectionHeader('Reminder'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.warningColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.alarm, color: AppTheme.warningColor),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('h:mm a').format(_task!.reminderTime!),
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppTheme.warningColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Subtasks Section
          _buildSectionHeader('Subtasks'),
          const SizedBox(height: 12),
          if (_task!.subtasks.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : AppTheme.lightSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF424242) : const Color(0xFFE0E0E0),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.add_task,
                    size: 48,
                    color: isDark ? AppTheme.darkTextHint : AppTheme.lightTextHint,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No subtasks yet',
                    style: TextStyle(
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the button below to add subtasks',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppTheme.darkTextHint : AppTheme.lightTextHint,
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                // Progress indicator
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _task!.progress,
                    backgroundColor: isDark ? AppTheme.darkCard : const Color(0xFFE0E0E0),
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.successColor),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_task!.subtasks.where((s) => s.completed).length} of ${_task!.subtasks.length} completed',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                    ),
                    Text(
                      '${(_task!.progress * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.successColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Subtask list
                ...List.generate(_task!.subtasks.length, (index) {
                  final subtask = _task!.subtasks[index];
                  return _buildSubtaskCard(subtask, index, isDark);
                }),
              ],
            ),

          const SizedBox(height: 24),

          // Meta Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : AppTheme.lightSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: isDark ? AppTheme.darkTextHint : AppTheme.lightTextHint,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Created: ${DateFormat('MMM d, y • h:mm a').format(_task!.createdAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppTheme.darkTextHint : AppTheme.lightTextHint,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.update,
                      size: 14,
                      color: isDark ? AppTheme.darkTextHint : AppTheme.lightTextHint,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Updated: ${DateFormat('MMM d, y • h:mm a').format(_task!.updatedAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppTheme.darkTextHint : AppTheme.lightTextHint,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 100), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildStatusChip(String label, String status, Color color) {
    final isSelected = _task!.status == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) async {
        await context.read<TaskProvider>().updateTask(_task!.id, {'status': status});
        _loadTask();
      },
      selectedColor: color.withOpacity(0.2),
      backgroundColor: color.withOpacity(0.1),
      labelStyle: TextStyle(
        color: isSelected ? color : color.withOpacity(0.7),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      checkmarkColor: color,
    );
  }

  Widget _buildSubtaskCard(SubTask subtask, int index, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF424242) : const Color(0xFFE0E0E0),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Checkbox(
          value: subtask.completed,
          onChanged: (_) => _toggleSubtask(index),
          activeColor: AppTheme.successColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        title: Text(
          subtask.title,
          style: TextStyle(
            decoration: subtask.completed ? TextDecoration.lineThrough : null,
            color: subtask.completed
                ? (isDark ? AppTheme.darkTextHint : AppTheme.lightTextHint)
                : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
          ),
        ),
        subtitle: subtask.dueDate != null
            ? Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 12,
                    color: isDark ? AppTheme.darkTextHint : AppTheme.lightTextHint,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM d').format(subtask.dueDate!),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppTheme.darkTextHint : AppTheme.lightTextHint,
                    ),
                  ),
                ],
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => _editSubtask(index),
              tooltip: 'Edit',
              color: isDark ? AppTheme.darkTextHint : AppTheme.lightTextHint,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => _deleteSubtask(index),
              tooltip: 'Delete',
              color: AppTheme.errorColor,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleTaskStatus() async {
    final newStatus = _task!.status == 'completed' ? 'pending' : 'completed';
    await context.read<TaskProvider>().updateTask(_task!.id, {'status': newStatus});
    _loadTask();
  }

  Color _parseColor(String colorHex) {
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppTheme.primaryColor;
    }
  }
}
