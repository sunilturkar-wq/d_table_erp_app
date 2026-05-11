import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../model/delegate_model.dart';
import '../../provider/auth_provider.dart';
import '../../provider/category_provider.dart';
import '../../provider/delegation_provider.dart';
import '../../provider/user_provider.dart';
import '../../widget/assign_task_sheet.dart';

class TaskDetailScreen extends StatefulWidget {
  final dynamic task;
  final bool allowEdit;

  const TaskDetailScreen({
    super.key,
    required this.task,
    this.allowEdit = false,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final TextEditingController remarkController = TextEditingController();
  final FocusNode _remarkFocusNode = FocusNode();
  bool _isDetailLoading = true;
  bool _isActionLoading = false;
  DelegationModel? _currentTask;

  // Audio Player State
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();

    // Handle both DelegationModel and Map inputs
    if (widget.task is DelegationModel) {
      _currentTask = widget.task as DelegationModel;
    }

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTaskDetail());
  }

  Future<void> _loadTaskDetail() async {
    String? taskId;
    if (widget.task is DelegationModel) {
      taskId = (widget.task as DelegationModel).id;
    } else if (widget.task is Map) {
      taskId = widget.task['id']?.toString() ?? widget.task['_id']?.toString();
    }

    if (taskId == null || taskId.isEmpty) {
      if (mounted) setState(() => _isDetailLoading = false);
      return;
    }

    setState(() => _isDetailLoading = true);
    try {
      final service = Provider.of<DelegationProvider>(context, listen: false);
      final rawResponse = await service.fetchTaskDetail(taskId);
      if (rawResponse != null && mounted) {
        setState(() {
          _currentTask = rawResponse;
          _isDetailLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isDetailLoading = false);
    }
  }

  @override
  void dispose() {
    remarkController.dispose();
    _remarkFocusNode.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _deleteTask() async {
    final taskId = _currentTask?.id;
    if (taskId == null || taskId.isEmpty || _isActionLoading) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text(
          'This task will be moved to trash. Do you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isActionLoading = true);
    final success = await context.read<DelegationProvider>().delete(taskId);
    if (!mounted) return;

    setState(() => _isActionLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Task moved to trash' : 'Failed to delete task',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (success) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _submitRemark() async {
    final taskId = _currentTask?.id;
    final userId = context.read<AuthProvider>().currentUser?.id ?? '';
    final remark = remarkController.text.trim();

    if (taskId == null ||
        taskId.isEmpty ||
        userId.isEmpty ||
        remark.isEmpty ||
        _isActionLoading) {
      return;
    }

    setState(() => _isActionLoading = true);
    final success = await context.read<DelegationProvider>().postRemark(
      taskId,
      remark,
      userId,
    );
    if (!mounted) return;

    setState(() => _isActionLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Update added successfully' : 'Failed to submit update',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (success) {
      remarkController.clear();
      await _loadTaskDetail();
    }
  }

  bool _canMarkTaskCompleted(DelegationModel task) {
    final hasPendingChecklist =
        task.checklistItems.isNotEmpty &&
        task.checklistItems.any((item) => !_isChecklistItemDone(item));
    if (hasPendingChecklist) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please complete all checklist items before marking the task as completed.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    return true;
  }

  Future<void> _updateTaskStatus(
    DelegationModel task,
    String newStatus, {
    required String reason,
    String? successMessage,
  }) async {
    final taskId = task.id;
    final userId = context.read<AuthProvider>().currentUser?.id ?? '';
    if (taskId == null ||
        taskId.isEmpty ||
        userId.isEmpty ||
        _isActionLoading) {
      return;
    }

    if (newStatus == 'Completed' && !_canMarkTaskCompleted(task)) {
      return;
    }

    setState(() => _isActionLoading = true);
    final success = await context.read<DelegationProvider>().updateStatus(
      taskId,
      newStatus,
      reason,
      userId,
    );
    if (!mounted) return;

    setState(() => _isActionLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (successMessage ?? 'Status updated to $newStatus')
              : 'Failed to update status',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (success) {
      await _loadTaskDetail();
    }
  }

  Future<void> _changeStatus(String newStatus, {String reason = ''}) async {
    final task = _currentTask;
    if (task == null) {
      return;
    }

    if (newStatus == 'Completed') {
      if (!_canMarkTaskCompleted(task)) {
        return;
      }
      await _showCompleteTaskDialog(task, reason: reason);
      return;
    }

    await _updateTaskStatus(
      task,
      newStatus,
      reason: reason,
      successMessage: 'Status updated to $newStatus',
    );
  }

  void _focusRemarkBox() {
    FocusScope.of(context).requestFocus(_remarkFocusNode);
  }

  Future<void> _subscribeToTask(DelegationModel task) async {
    final taskId = task.id;
    final currentUserId = context.read<AuthProvider>().currentUser?.id ?? '';

    if (taskId == null ||
        taskId.isEmpty ||
        currentUserId.isEmpty ||
        _isActionLoading) {
      return;
    }

    if (task.inLoopIds.contains(currentUserId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are already subscribed to this task.'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    setState(() => _isActionLoading = true);
    final success = await context.read<DelegationProvider>().subscribeToTask(
      taskId,
      currentUserId,
      task.inLoopIds,
    );
    if (!mounted) return;

    setState(() => _isActionLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Subscribed to task!' : 'Failed to update subscription',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (success) {
      await _loadTaskDetail();
    }
  }

  Future<void> _showReminderInfo(DelegationModel task) async {
    final taskId = task.id;
    final currentUserId = context.read<AuthProvider>().currentUser?.id ?? '';
    if (taskId == null || taskId.isEmpty || currentUserId.isEmpty) return;

    DateTime? selectedReminder = _extractExistingReminder(task);
    String selectedChannel = _extractExistingReminderChannel(task);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Task Reminder'),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedReminder == null
                          ? 'No reminder configured for this task.'
                          : 'Reminder scheduled for ${DateFormat('dd MMM yyyy, hh:mm a').format(selectedReminder!)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedChannel,
                      decoration: const InputDecoration(
                        labelText: 'Notification Channel',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'both',
                          child: Text('Email + WhatsApp'),
                        ),
                        DropdownMenuItem(
                          value: 'whatsapp',
                          child: Text('WhatsApp'),
                        ),
                        DropdownMenuItem(value: 'email', child: Text('Email')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => selectedChannel = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedReminder ?? DateTime.now(),
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 1),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 3650),
                          ),
                        );
                        if (date == null) return;

                        if (!context.mounted) return;
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(
                            selectedReminder ?? DateTime.now(),
                          ),
                        );
                        if (time == null) return;

                        setDialogState(() {
                          selectedReminder = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      },
                      icon: const Icon(Icons.schedule_rounded),
                      label: Text(
                        selectedReminder == null
                            ? 'Set Reminder'
                            : 'Change Reminder',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Close'),
                ),
                if (task.reminders.isNotEmpty || selectedReminder != null)
                  TextButton(
                    onPressed: _isActionLoading
                        ? null
                        : () async {
                            setState(() => _isActionLoading = true);
                            final success = await context
                                .read<DelegationProvider>()
                                .saveTaskReminders(
                                  taskId,
                                  const [],
                                  currentUserId,
                                );
                            if (!mounted) return;

                            setState(() => _isActionLoading = false);
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? 'Reminder cleared successfully'
                                      : 'Failed to clear reminder',
                                ),
                                backgroundColor: success
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            );

                            if (success) {
                              await _loadTaskDetail();
                            }
                          },
                    child: const Text('Clear'),
                  ),
                if (selectedReminder != null)
                  TextButton(
                    onPressed: _isActionLoading
                        ? null
                        : () async {
                            final reminderPayload =
                                _buildReminderPayloadForTask(
                                  task,
                                  selectedReminder!,
                                  selectedChannel,
                                );
                            if (reminderPayload == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Due date missing, unable to configure reminder.',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            setState(() => _isActionLoading = true);
                            final success = await context
                                .read<DelegationProvider>()
                                .saveTaskReminders(taskId, [
                                  reminderPayload,
                                ], currentUserId);
                            if (!mounted) return;

                            setState(() => _isActionLoading = false);
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? 'Reminder saved successfully'
                                      : 'Failed to save reminder',
                                ),
                                backgroundColor: success
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            );

                            if (success) {
                              await _loadTaskDetail();
                            }
                          },
                    child: const Text('Save'),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  DateTime? _extractExistingReminder(DelegationModel task) {
    if (task.reminders.isNotEmpty) {
      for (final reminder in task.reminders) {
        final reminderTime = reminder['reminderTime']?.toString().trim();
        if (reminderTime != null && reminderTime.isNotEmpty) {
          final parsed = DateTime.tryParse(reminderTime);
          if (parsed != null) return parsed.toLocal();
        }
      }
    }

    final reminderAt = task.reminderAt;
    if (reminderAt != null && reminderAt.isNotEmpty) {
      return DateTime.tryParse(reminderAt)?.toLocal();
    }

    return null;
  }

  String _extractExistingReminderChannel(DelegationModel task) {
    if (task.reminders.isEmpty) return 'both';
    final type = task.reminders.first['type']?.toString().trim().toLowerCase();
    if (type == 'email' || type == 'whatsapp' || type == 'both') {
      return type!;
    }
    return 'both';
  }

  Map<String, dynamic>? _buildReminderPayloadForTask(
    DelegationModel task,
    DateTime reminderDateTime,
    String channel,
  ) {
    final dueDate = DateTime.tryParse(task.dueDate)?.toLocal();
    if (dueDate == null) return null;

    final isBefore = reminderDateTime.isBefore(dueDate);
    final diff = isBefore
        ? dueDate.difference(reminderDateTime)
        : reminderDateTime.difference(dueDate);

    var timeValue = diff.inMinutes.abs();
    var timeUnit = 'minutes';

    if (timeValue >= 1440 && timeValue % 1440 == 0) {
      timeValue = timeValue ~/ 1440;
      timeUnit = 'days';
    } else if (timeValue >= 60 && timeValue % 60 == 0) {
      timeValue = timeValue ~/ 60;
      timeUnit = 'hours';
    }

    if (timeValue <= 0) {
      timeValue = 1;
    }

    return {
      'type': channel,
      'timeValue': timeValue,
      'timeUnit': timeUnit,
      'triggerType': isBefore ? 'before' : 'after',
    };
  }

  bool _isChecklistItemDone(Map<String, dynamic> item) {
    final completed = item['completed'];
    final status = item['status']?.toString().toLowerCase();
    return completed == true || status == 'completed' || status == 'done';
  }

  String _checklistItemLabel(Map<String, dynamic> item) {
    return (item['itemName'] ?? item['text'] ?? item['title'] ?? '')
        .toString()
        .trim();
  }

  Future<void> _toggleChecklistItem(
    DelegationModel task,
    Map<String, dynamic> item,
    int index,
  ) async {
    final taskId = task.id;
    if (taskId == null || taskId.isEmpty || _isActionLoading) return;

    final checklistId = item['id']?.toString() ?? index.toString();
    final newStatus = _isChecklistItemDone(item) ? 'Pending' : 'Completed';

    setState(() => _isActionLoading = true);
    final success = await context
        .read<DelegationProvider>()
        .updateChecklistStatus(taskId, checklistId, newStatus);
    if (!mounted) return;

    setState(() => _isActionLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Checklist updated' : 'Failed to update checklist',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (success) {
      await _loadTaskDetail();
    }
  }

  String _resolveUserName(String userId) {
    final users = context.read<UserProvider>().users;
    for (final user in users) {
      if (user.id == userId) {
        final name = user.fullName.trim();
        return name.isEmpty ? userId : name;
      }
    }
    return userId.isEmpty ? 'Unknown' : userId;
  }

  Future<void> _openExternalLink(String url) async {
    final parsed = Uri.tryParse(url);
    if (parsed == null) return;
    await launchUrl(parsed, mode: LaunchMode.externalApplication);
  }

  Future<void> _toggleVoicePlayback(String url) async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        return;
      }
      await _audioPlayer.play(UrlSource(url));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to play voice note'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openSubTaskSheet(DelegationModel task) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => AssignTaskSheet(
        parentTaskId: task.id,
        parentTaskTitle: task.delegationName,
        groupId: task.groupId,
      ),
    );

    if (created == true && mounted) {
      await _loadTaskDetail();
    }
  }

  Future<void> _showEditTaskDialog(DelegationModel task) async {
    final taskId = task.id;
    final currentUserId = context.read<AuthProvider>().currentUser?.id ?? '';
    if (taskId == null || taskId.isEmpty || currentUserId.isEmpty) return;

    final titleController = TextEditingController(text: task.delegationName);
    final descriptionController = TextEditingController(text: task.description);
    final categoryProvider = context.read<CategoryProvider>();
    if (categoryProvider.categoryModels.isEmpty) {
      await categoryProvider.fetchCategories();
    }

    final categoryItems = categoryProvider.categoryModels
        .map((item) => item.name)
        .where((name) => name.trim().isNotEmpty)
        .toSet()
        .toList();
    if (task.category.trim().isNotEmpty) {
      categoryItems.insert(0, task.category.trim());
    }
    if (categoryItems.isEmpty) {
      categoryItems.add('General');
    }

    String selectedPriority = task.priority.isNotEmpty ? task.priority : 'High';
    String selectedCategory = task.category.isNotEmpty
        ? task.category
        : categoryItems.first;
    bool evidenceRequired = task.evidenceRequired;
    DateTime selectedDueDate =
        DateTime.tryParse(task.dueDate)?.toLocal() ??
        DateTime.now().add(const Duration(days: 1));

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Task'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Title'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedPriority,
                        decoration: const InputDecoration(
                          labelText: 'Priority',
                        ),
                        items: const ['Urgent', 'High', 'Medium', 'Low']
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(item),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() => selectedPriority = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: categoryItems.contains(selectedCategory)
                            ? selectedCategory
                            : categoryItems.first,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                        items: categoryItems
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(item),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() => selectedCategory = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Due Date'),
                        subtitle: Text(
                          DateFormat(
                            'dd MMM yyyy, hh:mm a',
                          ).format(selectedDueDate),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.schedule_rounded),
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedDueDate,
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 365),
                              ),
                              lastDate: DateTime.now().add(
                                const Duration(days: 3650),
                              ),
                            );
                            if (date == null) return;
                            if (!context.mounted) return;
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(
                                selectedDueDate,
                              ),
                            );
                            if (time == null) return;
                            setDialogState(() {
                              selectedDueDate = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                time.hour,
                                time.minute,
                              );
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 4),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Evidence Required'),
                        value: evidenceRequired,
                        onChanged: (value) {
                          setDialogState(() => evidenceRequired = value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: _isActionLoading
                      ? null
                      : () async {
                          final title = titleController.text.trim();
                          if (title.isEmpty) return;

                          Navigator.pop(dialogContext);
                          setState(() => _isActionLoading = true);
                          final success = await context
                              .read<DelegationProvider>()
                              .updateTaskDetails(taskId, {
                                'taskTitle': title,
                                'description': descriptionController.text
                                    .trim(),
                                'priority': selectedPriority,
                                'category': selectedCategory,
                                'dueDate': selectedDueDate
                                    .toUtc()
                                    .toIso8601String(),
                                'evidenceRequired': evidenceRequired,
                                'changedBy': currentUserId,
                                'reason': 'Task updated from detail view',
                              });
                          if (!mounted) return;

                          setState(() => _isActionLoading = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? 'Task updated successfully'
                                    : 'Failed to update task',
                              ),
                              backgroundColor: success
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          );

                          if (success) {
                            await _loadTaskDetail();
                          }
                        },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showCompleteTaskDialog(
    DelegationModel task, {
    required String reason,
  }) async {
    final taskId = task.id;
    final currentUserId = context.read<AuthProvider>().currentUser?.id ?? '';
    if (taskId == null || taskId.isEmpty || currentUserId.isEmpty) return;

    final existingEvidenceUrls = _parseEvidenceUrls(task.evidenceUrl);
    final uploadedProvider = context.read<DelegationProvider>();
    final selectedFiles = <PlatformFile>[];
    var isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickEvidenceFiles() async {
              final result = await FilePicker.platform.pickFiles(
                allowMultiple: true,
              );
              if (result == null || result.files.isEmpty) return;

              setDialogState(() {
                for (final file in result.files) {
                  final alreadyAdded = selectedFiles.any(
                    (item) =>
                        item.name == file.name &&
                        (item.path ?? '') == (file.path ?? ''),
                  );
                  if (!alreadyAdded) {
                    selectedFiles.add(file);
                  }
                }
              });
            }

            Future<void> completeTask() async {
              if (isSubmitting) return;

              if (task.evidenceRequired &&
                  existingEvidenceUrls.isEmpty &&
                  selectedFiles.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Evidence is required before completing this task.',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              setDialogState(() => isSubmitting = true);

              try {
                final uploadedEvidenceUrls = <String>[];
                for (final file in selectedFiles) {
                  final url = await uploadedProvider.uploadFile(
                    file,
                    folder: 'evidence',
                  );
                  uploadedEvidenceUrls.add(url);
                }

                final mergedEvidenceUrls = <String>[
                  ...existingEvidenceUrls,
                  ...uploadedEvidenceUrls,
                ].toSet().toList();

                final payload = <String, dynamic>{
                  'status': 'Completed',
                  'changedBy': currentUserId,
                  'reason': reason,
                };

                if (mergedEvidenceUrls.isNotEmpty) {
                  payload['evidenceUrl'] = jsonEncode(mergedEvidenceUrls);
                }

                final success = await uploadedProvider.updateTaskDetails(
                  taskId,
                  payload,
                );
                if (!mounted) return;

                if (success) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text('Task completed successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  await _loadTaskDetail();
                  return;
                }

                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to complete task'),
                    backgroundColor: Colors.red,
                  ),
                );
              } catch (_) {
                if (!mounted) return;
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to upload evidence files'),
                    backgroundColor: Colors.red,
                  ),
                );
              } finally {
                if (dialogContext.mounted) {
                  setDialogState(() => isSubmitting = false);
                }
              }
            }

            return AlertDialog(
              title: const Text('Complete Task'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.evidenceRequired
                          ? 'Evidence is required before this task can be completed.'
                          : 'You can attach evidence before completing this task.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (existingEvidenceUrls.isNotEmpty) ...[
                      Text(
                        'Existing evidence (${existingEvidenceUrls.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: existingEvidenceUrls.map((url) {
                          final label =
                              Uri.tryParse(url)?.pathSegments.isNotEmpty == true
                              ? Uri.parse(url).pathSegments.last
                              : 'Evidence';
                          return ActionChip(
                            label: Text(label, overflow: TextOverflow.ellipsis),
                            onPressed: () => _openExternalLink(url),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                    OutlinedButton.icon(
                      onPressed: isSubmitting ? null : pickEvidenceFiles,
                      icon: const Icon(Icons.upload_file_rounded),
                      label: Text(
                        selectedFiles.isEmpty
                            ? 'Add Evidence Files'
                            : 'Add More Evidence (${selectedFiles.length})',
                      ),
                    ),
                    if (selectedFiles.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(selectedFiles.length, (index) {
                          final file = selectedFiles[index];
                          return Chip(
                            label: Text(
                              file.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            onDeleted: isSubmitting
                                ? null
                                : () => setDialogState(
                                    () => selectedFiles.removeAt(index),
                                  ),
                          );
                        }),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting ? null : completeTask,
                  child: isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Complete Task'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _changeSubtaskStatus(
    DelegationModel subtask,
    String newStatus,
  ) async {
    await _updateTaskStatus(
      subtask,
      newStatus,
      reason: 'Subtask status updated to $newStatus',
      successMessage: 'Sub task marked as $newStatus',
    );
  }

  bool _canActOnSubtask(
    DelegationModel subtask,
    String? currentUserId,
    bool isAdmin,
  ) {
    if (currentUserId == null || currentUserId.isEmpty) return false;
    return isAdmin ||
        currentUserId == subtask.delegatorId ||
        currentUserId == subtask.assingDoerId;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Completed':
        return const Color(0xFF003366);
      case 'In Progress':
        return Colors.orange;
      case 'Overdue':
        return Colors.redAccent;
      case 'Need Revision':
        return Colors.indigo;
      case 'Pending':
        return Colors.blueGrey;
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'Urgent':
        return Colors.redAccent;
      case 'High':
        return Colors.orange;
      case 'Medium':
        return Colors.blue;
      case 'Low':
        return Colors.green;
      default:
        return const Color(0xFF64748B);
    }
  }

  List<String> _parseEvidenceUrls(String? rawEvidence) {
    if (rawEvidence == null || rawEvidence.trim().isEmpty) return const [];

    final trimmed = rawEvidence.trim();
    if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is List) {
          return decoded
              .map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .toList();
        }
        return decoded
            .toString()
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList();
      } catch (_) {}
    }

    return trimmed
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading if we don't have task data yet (especially when coming from Map)
    if (_isDetailLoading && _currentTask == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF003366)),
        ),
      );
    }

    final task = _currentTask;
    if (task == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: const Center(child: Text("Task not found or failed to load")),
      );
    }

    final currentUserId = context.read<AuthProvider>().currentUser?.id;
    final isAdmin = context.read<AuthProvider>().isAdmin;
    final isAssigner =
        currentUserId != null && currentUserId == task.delegatorId;
    final isDoer = currentUserId != null && currentUserId == task.assingDoerId;
    final canAct = isAssigner || isDoer;
    final canDelete = isAdmin || canAct;
    final isSubscribed =
        currentUserId != null && task.inLoopIds.contains(currentUserId);
    final completedChecklistCount = task.checklistItems
        .where(_isChecklistItemDone)
        .length;
    final completedSubtasksCount = task.subtasks
        .where((item) => item.status == 'Completed')
        .length;
    final evidenceUrls = _parseEvidenceUrls(task.evidenceUrl);
    final attachmentUrls = task.referenceDocs
        .where((url) => url.trim().isNotEmpty)
        .toSet()
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Flexible(
                        child: Text(
                          "DELEGATIONS",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: Color(0xFFCBD5E1),
                      ),
                      const Flexible(
                        child: Text(
                          "DETAILS",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFF003366),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _statusPill(task.status),
                    if (canDelete)
                      IconButton(
                        icon: const Icon(
                          LucideIcons.trash2,
                          color: Colors.red,
                          size: 20,
                        ),
                        onPressed: _isActionLoading ? null : _deleteTask,
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              task.delegationName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionCard(
              title: "CORE INFORMATION",
              icon: LucideIcons.info,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 32,
                    runSpacing: 20,
                    children: [
                      _infoTile(
                        "CATEGORY",
                        LucideIcons.tag,
                        Colors.indigo,
                        task.category.isEmpty ? "General" : task.category,
                      ),
                      _infoTile(
                        "PRIORITY",
                        LucideIcons.circle,
                        _priorityColor(task.priority),
                        task.priority,
                      ),
                      _infoTile(
                        "DEADLINE",
                        LucideIcons.calendar,
                        Colors.redAccent,
                        task.dueDate.isEmpty
                            ? "Not set"
                            : _formatDate(task.dueDate),
                      ),
                      _infoTile(
                        "EVIDENCE",
                        LucideIcons.shieldCheck,
                        Colors.teal,
                        task.evidenceRequired ? "Required" : "Optional",
                      ),
                    ],
                  ),
                  if (task.tagsList.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Divider(color: Color(0xFFF1F5F9), height: 1),
                    const SizedBox(height: 16),
                    const Text(
                      "TASK TAGS",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: task.tagsList.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF1F8),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (task.description.trim().isNotEmpty) ...[
              _buildSectionCard(
                title: "DESCRIPTION",
                icon: LucideIcons.alignLeft,
                child: Text(
                  task.description.trim(),
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            _buildInvolvedPartiesCard(task),
            const SizedBox(height: 16),

            _buildMetadataCard(task),
            const SizedBox(height: 16),

            _buildSectionCard(
              title: "CHECKLIST",
              icon: LucideIcons.checkSquare,
              trailing: _countBadge(
                "$completedChecklistCount/${task.checklistItems.length}",
              ),
              child: task.checklistItems.isEmpty
                  ? Center(
                      child: const Text(
                        "NO CHECKLIST ITEMS",
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    )
                  : Column(
                      children: List.generate(task.checklistItems.length, (
                        index,
                      ) {
                        final item = task.checklistItems[index];
                        final isDone = _isChecklistItemDone(item);
                        final label = _checklistItemLabel(item);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: isDoer
                                ? () => _toggleChecklistItem(task, item, index)
                                : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isDone
                                        ? Icons.check_circle
                                        : Icons.circle_outlined,
                                    size: 18,
                                    color: isDone ? Colors.green : Colors.grey,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      label.isEmpty ? "Checklist Item" : label,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: const Color(0xFF334155),
                                        decoration: isDone
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              title: "SUB TASKS",
              icon: LucideIcons.layers,
              trailing: _countBadge(
                "$completedSubtasksCount/${task.subtasks.length}",
              ),
              child: task.subtasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "NO SUB TASKS YET",
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                          if (task.id != null) ...[
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _isActionLoading
                                  ? null
                                  : () => _openSubTaskSheet(task),
                              icon: const Icon(LucideIcons.plus, size: 16),
                              label: const Text(
                                "CREATE SUB TASK",
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  : Column(
                      children: task.subtasks.map((subtask) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      subtask.delegationName,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  ),
                                  _statusBadge(
                                    subtask.status,
                                    _statusColor(subtask.status),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 10,
                                runSpacing: 6,
                                children: [
                                  if (subtask.dueDate.isNotEmpty)
                                    _miniMeta(
                                      LucideIcons.clock,
                                      _formatDate(subtask.dueDate),
                                    ),
                                  _miniMeta(
                                    LucideIcons.user,
                                    subtask.getAssignedToName(
                                      context.read<UserProvider>().users,
                                    ),
                                  ),
                                ],
                              ),
                              if (_canActOnSubtask(
                                subtask,
                                currentUserId,
                                isAdmin,
                              )) ...[
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _quickActionButton(
                                      "IN PROGRESS",
                                      LucideIcons.playCircle,
                                      Colors.orange,
                                      onTap:
                                          _isActionLoading ||
                                              subtask.status == 'In Progress'
                                          ? null
                                          : () => _changeSubtaskStatus(
                                              subtask,
                                              "In Progress",
                                            ),
                                    ),
                                    _quickActionButton(
                                      "COMPLETE",
                                      LucideIcons.checkCircle,
                                      Colors.green,
                                      onTap:
                                          _isActionLoading ||
                                              subtask.status == 'Completed'
                                          ? null
                                          : () => _changeSubtaskStatus(
                                              subtask,
                                              "Completed",
                                            ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 16),

            if (task.voiceNoteUrl != null || attachmentUrls.isNotEmpty) ...[
              _buildSectionCard(
                title: "ATTACHMENTS",
                icon: LucideIcons.paperclip,
                child: Column(
                  children: [
                    if (task.voiceNoteUrl != null &&
                        task.voiceNoteUrl!.trim().isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              LucideIcons.mic,
                              size: 18,
                              color: Color(0xFF003366),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                "Voice Note",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => _toggleVoicePlayback(
                                task.voiceNoteUrl!.trim(),
                              ),
                              child: Text(_isPlaying ? "Pause" : "Play"),
                            ),
                            IconButton(
                              onPressed: () =>
                                  _openExternalLink(task.voiceNoteUrl!.trim()),
                              icon: const Icon(
                                Icons.open_in_new_rounded,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ...attachmentUrls.map((url) {
                      final parsed = Uri.tryParse(url);
                      final last = parsed?.pathSegments.isNotEmpty == true
                          ? parsed!.pathSegments.last
                          : url;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              LucideIcons.fileText,
                              size: 18,
                              color: Color(0xFF0F766E),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                last,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => _openExternalLink(url),
                              icon: const Icon(
                                Icons.open_in_new_rounded,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            if (evidenceUrls.isNotEmpty) ...[
              _buildSectionCard(
                title: "EVIDENCE PROVIDED",
                icon: LucideIcons.shieldCheck,
                child: Column(
                  children: evidenceUrls.map((url) {
                    final parsed = Uri.tryParse(url);
                    final last = parsed?.pathSegments.isNotEmpty == true
                        ? parsed!.pathSegments.last
                        : url;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF1F8),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.verified_outlined,
                            size: 18,
                            color: Color(0xFF003366),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              last,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF166534),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _openExternalLink(url),
                            icon: const Icon(
                              Icons.open_in_new_rounded,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
            ],

            if (canAct) ...[
              const Text(
                "QUICK ACTIONS",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (isDoer)
                    _quickActionButton(
                      "IN PROGRESS",
                      LucideIcons.playCircle,
                      Colors.orange,
                      onTap: _isActionLoading || task.status == "In Progress"
                          ? null
                          : () => _changeStatus(
                              "In Progress",
                              reason: 'Updated from task detail',
                            ),
                    ),
                  if (isDoer)
                    _quickActionButton(
                      "COMPLETE",
                      LucideIcons.checkCircle,
                      Colors.green,
                      onTap: _isActionLoading || task.status == "Completed"
                          ? null
                          : () => _changeStatus(
                              "Completed",
                              reason: 'Completed from task detail',
                            ),
                    ),
                  if (isDoer)
                    _quickActionButton(
                      "REMINDERS",
                      LucideIcons.bell,
                      Colors.blue,
                      onTap: () => _showReminderInfo(task),
                    ),
                  _quickActionButton(
                    "COMMENT",
                    LucideIcons.messageCircle,
                    Colors.indigo,
                    onTap: _focusRemarkBox,
                  ),
                  _quickActionButton(
                    "SUB TASK",
                    LucideIcons.layers,
                    Colors.cyan,
                    onTap: task.id == null
                        ? null
                        : () => _openSubTaskSheet(task),
                  ),
                  if (widget.allowEdit && isAssigner)
                    _quickActionButton(
                      "EDIT",
                      LucideIcons.pencil,
                      Colors.purple,
                      onTap: _isActionLoading
                          ? null
                          : () => _showEditTaskDialog(task),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              const Text(
                "QUICK REMARK",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: remarkController,
                focusNode: _remarkFocusNode,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Focus on specific details or updates...",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isActionLoading ? null : _submitRemark,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003366),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isActionLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "SUBMIT UPDATE",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            if (!canAct) ...[
              _buildObserverModeCard(task, isSubscribed),
              const SizedBox(height: 24),
            ],

            _buildSectionCard(
              title: "REVISION HISTORY",
              icon: LucideIcons.history,
              child: task.revisionHistory.isEmpty
                  ? const Center(
                      child: Text(
                        "NO REVISIONS YET",
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    )
                  : Column(
                      children: task.revisionHistory
                          .map(
                            (r) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildHistoryItem(
                                r.newStatus.isEmpty ? task.status : r.newStatus,
                                r.createdAt,
                                r.reason.isEmpty ? "Update" : r.reason,
                                _resolveUserName(r.changedBy),
                                r.oldStatus.isEmpty
                                    ? ""
                                    : "OLD: ${r.oldStatus}",
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: "REMARK HISTORY",
              icon: LucideIcons.messageSquare,
              child: task.remarks.isEmpty
                  ? const Center(
                      child: Text(
                        "NO REMARKS YET",
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    )
                  : Column(
                      children: task.remarks
                          .map(
                            (remark) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildHistoryItem(
                                "Remark",
                                remark.date,
                                remark.remark,
                                _resolveUserName(remark.assignedUserId),
                                "",
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF003366),
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.black,
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        "DELEGATION DETAIL",
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 16,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _statusPill(String status) {
    final color = _statusColor(status);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.w900,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
              if (trailing != null) ...[const Spacer(), trailing],
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _infoTile(String label, IconData icon, Color color, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            color: Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _miniMeta(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF64748B)),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActionButton(
    String label,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(
    String status,
    String date,
    String comment,
    String user,
    String oldStatus,
  ) {
    final statusColor = status == 'Remark'
        ? Colors.indigo
        : _statusColor(status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statusBadge(status, statusColor),
              Text(
                date,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment,
            style: const TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "BY: $user",
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF64748B),
                ),
              ),
              if (oldStatus.isNotEmpty)
                Text(
                  oldStatus,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF94A3B8),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 9,
        ),
      ),
    );
  }

  Widget _countBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontWeight: FontWeight.w900,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildInvolvedPartiesCard(DelegationModel task) {
    var users = Provider.of<UserProvider>(context, listen: false).users;
    String assignedBy = task.getAssignedByName(users);
    String assignedTo = task.getAssignedToName(users);

    List<String> inLoopNames = task.inLoopIds.map((id) {
      try {
        return users.firstWhere((u) => u.id == id).fullName.toUpperCase();
      } catch (e) {
        return "USER";
      }
    }).toList();

    return _buildSectionCard(
      title: "INVOLVED PARTIES",
      icon: LucideIcons.users,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _userRow(
            "ASSIGNED BY",
            assignedBy,
            'G',
            const Color(0xFFEEF2FF),
            const Color(0xFF4F46E5),
          ),
          const SizedBox(height: 16),
          _userRow(
            "ASSIGNED TO",
            assignedTo,
            'S',
            const Color(0xFFFFFBEB),
            const Color(0xFFD97706),
          ),
          if (inLoopNames.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              "IN LOOP",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: inLoopNames.map((name) => _inLoopBadge(name)).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildObserverModeCard(DelegationModel task, bool isSubscribed) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isSubscribed
                  ? const Color(0xFFE0E7FF)
                  : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSubscribed
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_off_outlined,
              color: isSubscribed
                  ? const Color(0xFF4F46E5)
                  : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "OBSERVER MODE",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E293B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSubscribed
                ? "You are currently subscribed."
                : "Subscribe to receive updates.",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              height: 1.5,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isActionLoading || isSubscribed
                ? null
                : () => _subscribeToTask(task),
            style: ElevatedButton.styleFrom(
              backgroundColor: isSubscribed
                  ? const Color(0xFFE2E8F0)
                  : const Color(0xFF4F46E5),
              foregroundColor: isSubscribed
                  ? const Color(0xFF64748B)
                  : Colors.white,
              elevation: isSubscribed ? 0 : 2,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(
              isSubscribed
                  ? Icons.check_circle_outline
                  : Icons.notifications_active,
              size: 18,
            ),
            label: Text(
              isSubscribed ? "SUBSCRIBED" : "SUBSCRIBE",
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _userRow(
    String label,
    String name,
    String initial,
    Color bgColor,
    Color textColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: bgColor,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : initial,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              name.isNotEmpty ? name : "Unknown",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _inLoopBadge(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: const Color(0xFFEEF2FF),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: const TextStyle(
                color: Color(0xFF4F46E5),
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            name.isNotEmpty ? name : "USER",
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataCard(DelegationModel task) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "CREATED ON",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF94A3B8),
                ),
              ),
              Text(
                task.createdAt.isNotEmpty ? _formatDate(task.createdAt) : "N/A",
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "DELEGATION ID",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF94A3B8),
                ),
              ),
              Text(
                task.id != null
                    ? "#${task.id!.substring(0, task.id!.length > 8 ? 8 : task.id!.length)}"
                    : "N/A",
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('dd MMM, HH:mm').format(dt);
    } catch (_) {
      return raw;
    }
  }
}
