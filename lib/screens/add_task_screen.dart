import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';

class AddTaskScreen extends StatefulWidget {
  final bool isEditing;
  final Map<String, dynamic>? initialData;

  const AddTaskScreen({
    super.key,
    this.isEditing = false,
    this.initialData,
  });

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _dueDate;
  String _priority = 'medium';
  String? _categoryId;
  bool _isLoading = false;
  bool _isRecurring = false;
  String _recurrencePattern = 'daily';
  int _recurrenceInterval = 1;
  DateTime? _recurrenceEndDate;
  bool _reminderEnabled = false;
  DateTime? _reminderTime;

  final List<String> _priorityOptions = ['low', 'medium', 'high', 'urgent'];
  final List<String> _recurrenceOptions = ['daily', 'weekly', 'monthly', 'yearly'];

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.initialData != null) {
      _titleController.text = widget.initialData!['title'] ?? '';
      _descriptionController.text = widget.initialData!['description'] ?? '';
      _dueDate = widget.initialData!['due_date'] != null 
          ? DateTime.tryParse(widget.initialData!['due_date'])
          : null;
      _priority = widget.initialData!['priority'] ?? 'medium';
      _categoryId = widget.initialData!['category_id'];
      _isRecurring = widget.initialData!['is_recurring'] == 1 || widget.initialData!['is_recurring'] == true;
      _recurrencePattern = widget.initialData!['recurrence_pattern'] ?? 'daily';
      _recurrenceInterval = widget.initialData!['recurrence_interval'] ?? 1;
      _recurrenceEndDate = widget.initialData!['recurrence_end_date'] != null 
          ? DateTime.tryParse(widget.initialData!['recurrence_end_date'])
          : null;
      _reminderEnabled = widget.initialData!['reminder_enabled'] == 1 || widget.initialData!['reminder_enabled'] == true;
      _reminderTime = widget.initialData!['reminder_time'] != null 
          ? DateTime.tryParse(widget.initialData!['reminder_time'])
          : null;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
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
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
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

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final taskData = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'priority': _priority,
      'category_id': _categoryId,
      'due_date': _dueDate?.toIso8601String(),
      'status': 'pending',
      'is_recurring': _isRecurring ? 1 : 0,
      'recurrence_pattern': _isRecurring ? _recurrencePattern : null,
      'recurrence_interval': _isRecurring ? _recurrenceInterval : null,
      'recurrence_end_date': _isRecurring ? _recurrenceEndDate?.toIso8601String() : null,
      'reminder_enabled': _reminderEnabled ? 1 : 0,
      'reminder_time': _reminderEnabled ? _reminderTime?.toIso8601String() : null,
    };

    final success = await context.read<TaskProvider>().createTask(taskData);

    setState(() => _isLoading = false);

    if (success != null && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Task' : 'New Task'),
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _saveTask,
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
            // Title Section
            _buildSectionHeader('Task Details'),
            const SizedBox(height: 12),

            TextFormField(
              controller: _titleController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Task Title *',
                hintText: 'Enter task title',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              textInputAction: TextInputAction.done,
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

            // Priority Section
            _buildSectionHeader('Priority'),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _priorityOptions.map((priority) {
                return _buildPriorityChip(priority);
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Due Date Section
            _buildSectionHeader('Due Date'),
            const SizedBox(height: 12),

            InkWell(
              onTap: _selectDate,
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
                    Icon(Icons.calendar_today, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
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

            // Category Section
            Consumer<TaskProvider>(
              builder: (context, taskProvider, _) {
                final categories = taskProvider.categories;
                if (categories.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Category'),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _categoryId,
                      decoration: const InputDecoration(
                        hintText: 'Select category',
                        prefixIcon: Icon(Icons.folder_outlined),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('No Category')),
                        ...categories.map((cat) => DropdownMenuItem(
                          value: cat.id,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _parseColor(cat.color),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(cat.name),
                            ],
                          ),
                        )),
                      ],
                      onChanged: (value) => setState(() => _categoryId = value),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Recurring Section
            _buildSectionHeader('Recurring Settings'),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : AppTheme.lightSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF424242) : const Color(0xFFE0E0E0),
                ),
              ),
              child: SwitchListTile(
                title: const Text('Enable Recurring'),
                subtitle: Text(
                  _isRecurring ? 'Task will repeat automatically' : 'Task is one-time',
                  style: TextStyle(
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
                value: _isRecurring,
                onChanged: (value) => setState(() => _isRecurring = value),
                activeColor: AppTheme.primaryColor,
              ),
            ),

            if (_isRecurring) ...[
              const SizedBox(height: 16),

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

            Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : AppTheme.lightSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF424242) : const Color(0xFFE0E0E0),
                ),
              ),
              child: SwitchListTile(
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
            ),

            if (_reminderEnabled) ...[
              const SizedBox(height: 16),

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

  Widget _buildPriorityChip(String priority) {
    final isSelected = _priority == priority;
    final color = AppTheme.getPriorityColor(priority);

    return FilterChip(
      label: Text(priority[0].toUpperCase() + priority.substring(1)),
      selected: isSelected,
      onSelected: (_) => setState(() => _priority = priority),
      selectedColor: color.withOpacity(0.2),
      backgroundColor: color.withOpacity(0.1),
      labelStyle: TextStyle(
        color: isSelected ? color : color.withOpacity(0.7),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      checkmarkColor: color,
    );
  }

  Color _parseColor(String colorHex) {
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppTheme.primaryColor;
    }
  }
}
