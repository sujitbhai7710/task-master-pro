import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';

class AddSubtaskScreen extends StatefulWidget {
  final String taskId;
  final Map<String, dynamic>? existingSubtask; // For editing

  const AddSubtaskScreen({
    super.key,
    required this.taskId,
    this.existingSubtask,
  });

  @override
  State<AddSubtaskScreen> createState() => _AddSubtaskScreenState();
}

class _AddSubtaskScreenState extends State<AddSubtaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _dueDate;
  bool _isRecurring = false;
  String _recurrencePattern = 'daily';
  int _recurrenceInterval = 1;
  DateTime? _recurrenceEndDate;
  bool _reminderEnabled = false;
  DateTime? _reminderTime;
  bool _isLoading = false;
  bool get isEditing => widget.existingSubtask != null;

  final List<String> _recurrenceOptions = ['daily', 'weekly', 'monthly', 'yearly'];

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _titleController.text = widget.existingSubtask!['title'] ?? '';
      _descriptionController.text = widget.existingSubtask!['description'] ?? '';
      _dueDate = widget.existingSubtask!['due_date'] != null 
          ? DateTime.tryParse(widget.existingSubtask!['due_date'])
          : null;
      _isRecurring = widget.existingSubtask!['is_recurring'] == 1 || 
                     widget.existingSubtask!['is_recurring'] == true;
      _recurrencePattern = widget.existingSubtask!['recurrence_pattern'] ?? 'daily';
      _recurrenceInterval = widget.existingSubtask!['recurrence_interval'] ?? 1;
      _recurrenceEndDate = widget.existingSubtask!['recurrence_end_date'] != null 
          ? DateTime.tryParse(widget.existingSubtask!['recurrence_end_date'])
          : null;
      _reminderEnabled = widget.existingSubtask!['reminder_enabled'] == 1 || 
                         widget.existingSubtask!['reminder_enabled'] == true;
      _reminderTime = widget.existingSubtask!['reminder_time'] != null 
          ? DateTime.tryParse(widget.existingSubtask!['reminder_time'])
          : null;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _selectRecurrenceEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _recurrenceEndDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _recurrenceEndDate = picked);
    }
  }

  Future<void> _selectReminderTime() async {
    final date = _dueDate ?? DateTime.now();
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_reminderTime ?? date),
    );
    if (time != null) {
      setState(() {
        _reminderTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
      });
    }
  }

  Future<void> _saveSubtask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final subtaskData = {
      'task_id': widget.taskId,
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'due_date': _dueDate?.toIso8601String(),
      'is_recurring': _isRecurring ? 1 : 0,
      'recurrence_pattern': _isRecurring ? _recurrencePattern : null,
      'recurrence_interval': _isRecurring ? _recurrenceInterval : null,
      'recurrence_end_date': _isRecurring ? _recurrenceEndDate?.toIso8601String() : null,
      'reminder_enabled': _reminderEnabled ? 1 : 0,
      'reminder_time': _reminderEnabled ? _reminderTime?.toIso8601String() : null,
    };

    bool success;
    if (isEditing) {
      success = await context.read<TaskProvider>().updateSubtask(
        widget.existingSubtask!['id'],
        subtaskData,
      ) != null;
    } else {
      success = await context.read<TaskProvider>().createSubtask(subtaskData) != null;
    }

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Subtask updated' : 'Subtask created'),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Failed to update subtask' : 'Failed to create subtask'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Subtask' : 'New Subtask'),
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _saveSubtask,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Subtask Title *',
                hintText: 'Enter subtask title',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Title is required';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Enter description',
                alignLabelWithHint: true,
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 48),
                  child: Icon(Icons.description),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Due Date
            _buildSectionHeader('Due Date'),
            const SizedBox(height: 12),

            InkWell(
              onTap: _selectDueDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
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
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _dueDate != null
                          ? DateFormat('EEEE, MMM d, y').format(_dueDate!)
                          : 'Select due date (optional)',
                      style: TextStyle(
                        color: _dueDate != null
                            ? (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary)
                            : (isDark ? AppTheme.darkTextHint : AppTheme.lightTextHint),
                      ),
                    ),
                    const Spacer(),
                    if (_dueDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _dueDate = null),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Recurring Section
            _buildSectionHeader('Recurring'),
            const SizedBox(height: 12),

            SwitchListTile(
              title: const Text('Enable Recurring'),
              subtitle: Text(
                _isRecurring ? 'Subtask will repeat' : 'One-time subtask',
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
              ),
              value: _isRecurring,
              onChanged: (value) => setState(() => _isRecurring = value),
              activeColor: AppTheme.primaryColor,
            ),

            if (_isRecurring) ...[
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _recurrencePattern,
                decoration: const InputDecoration(
                  labelText: 'Repeat',
                  prefixIcon: Icon(Icons.repeat),
                ),
                items: _recurrenceOptions.map((pattern) {
                  return DropdownMenuItem(
                    value: pattern,
                    child: Text(pattern[0].toUpperCase() + pattern.substring(1)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _recurrencePattern = value);
                  }
                },
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  const Text('Every '),
                  Expanded(
                    child: TextFormField(
                      initialValue: _recurrenceInterval.toString(),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (value) {
                        final interval = int.tryParse(value);
                        if (interval != null && interval > 0) {
                          _recurrenceInterval = interval;
                        }
                      },
                    ),
                  ),
                  Text(' ${_recurrencePattern}(s)'),
                ],
              ),

              const SizedBox(height: 16),

              InkWell(
                onTap: _selectRecurrenceEndDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
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
                      const Icon(Icons.event_busy),
                      const SizedBox(width: 12),
                      Text(
                        _recurrenceEndDate != null
                            ? 'Ends: ${DateFormat('MMM d, y').format(_recurrenceEndDate!)}'
                            : 'Set end date (optional)',
                      ),
                      const Spacer(),
                      if (_recurrenceEndDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _recurrenceEndDate = null),
                        ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Reminder Section
            _buildSectionHeader('Reminder'),
            const SizedBox(height: 12),

            SwitchListTile(
              title: const Text('Enable Reminder'),
              subtitle: Text(
                _reminderEnabled ? 'You will be notified' : 'No reminder set',
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
              ),
              value: _reminderEnabled,
              onChanged: (value) => setState(() => _reminderEnabled = value),
              activeColor: AppTheme.primaryColor,
            ),

            if (_reminderEnabled) ...[
              const SizedBox(height: 12),

              InkWell(
                onTap: _selectReminderTime,
                borderRadius: BorderRadius.circular(12),
                child: Container(
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
                      const Icon(Icons.alarm),
                      const SizedBox(width: 12),
                      Text(
                        _reminderTime != null
                            ? DateFormat('h:mm a').format(_reminderTime!)
                            : 'Set reminder time',
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
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
}
