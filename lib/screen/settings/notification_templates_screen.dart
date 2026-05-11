import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../provider/notification_provider.dart';
import '../../utils/notification_template_helper.dart';

class NotificationTemplatesScreen extends StatefulWidget {
  const NotificationTemplatesScreen({super.key});

  @override
  State<NotificationTemplatesScreen> createState() =>
      _NotificationTemplatesScreenState();
}

class _NotificationTemplatesScreenState
    extends State<NotificationTemplatesScreen> {
  String _activeEvent = 'newTask';
  String _activeChannel = 'email';

  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  bool _isActive = true;

  final Map<String, String> _events = {
    'newTask': 'New Task (Assignee)',
    'taskEdit': 'Task Edited (Assignee)',
    'taskComment': 'Task Comment (Assignee)',
    'taskInProgress': 'Task In-Progress (Assignee)',
    'taskComplete': 'Task Complete (Assignee)',
    'taskReOpen': 'Task Re-Open (Assignee)',
    'dailyPendingReminders': 'Daily Pending Reminders',
    'reminder': 'Custom Reminder (Assignee)',
    'newTaskInLoop': 'New Task (In-Loop)',
    'taskEditInLoop': 'Task Edited (In-Loop)',
    'taskCommentInLoop': 'Task Comment (In-Loop)',
    'taskInProgressInLoop': 'Task In-Progress (In-Loop)',
    'taskCompleteInLoop': 'Task Complete (In-Loop)',
    'taskReOpenInLoop': 'Task Re-Open (In-Loop)',
    'reminderInLoop': 'Task Reminder (In-Loop)',
  };

  final List<Map<String, String>> _variables = [
    {'key': '{taskId}', 'label': 'Task ID', 'desc': 'Related task identifier'},
    {
      'key': '{taskTitle}',
      'label': 'Task Title',
      'desc': 'The title of the task',
    },
    {
      'key': '{taskDescription}',
      'label': 'Description',
      'desc': 'Task description',
    },
    {'key': '{priority}', 'label': 'Priority', 'desc': 'Task priority level'},
    {'key': '{category}', 'label': 'Category', 'desc': 'Task category'},
    {'key': '{dueDate}', 'label': 'Due Date', 'desc': 'Formatted due date'},
    {
      'key': '{assignerName}',
      'label': 'Assigner',
      'desc': 'Who assigned the task',
    },
    {'key': '{doerName}', 'label': 'Assignee', 'desc': 'Who is assigned'},
    {
      'key': '{updatedBy}',
      'label': 'Updated By',
      'desc': 'Who edited the task',
    },
    {'key': '{status}', 'label': 'Status', 'desc': 'Current task status'},
    {'key': '{remark}', 'label': 'Remark', 'desc': 'Recent comment'},
    {
      'key': '{commenterName}',
      'label': 'Commenter',
      'desc': 'Who added the remark',
    },
    {
      'key': '{taskList}',
      'label': 'Task List',
      'desc': 'Summary list (Daily Report)',
    },
    {
      'key': '{frequency}',
      'label': 'Frequency',
      'desc': 'Recurrence frequency like Daily or Weekly',
    },
    {
      'key': '{startDate}',
      'label': 'Start Date',
      'desc': 'Task or repeat start date',
    },
    {
      'key': '{endDate}',
      'label': 'End Date',
      'desc': 'Task or repeat end date',
    },
    {
      'key': '{voiceNoteUrl}',
      'label': 'Voice Note',
      'desc': 'Link to the recorded audio note',
    },
    {
      'key': '{referenceDocs}',
      'label': 'Attachments',
      'desc': 'Links to reference files and documents',
    },
    {
      'key': '{evidenceUrl}',
      'label': 'Evidence File',
      'desc': 'Link to the completion evidence file',
    },
  ];

  @override
  void initState() {
    super.initState();
    _subjectController.addListener(_handleDraftChanged);
    _bodyController.addListener(_handleDraftChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _handleDraftChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadInitialData() async {
    final provider = context.read<NotificationProvider>();
    await provider.fetchTemplates();
    await _loadTemplate();
  }

  Future<void> _loadTemplate() async {
    final provider = context.read<NotificationProvider>();
    await provider.fetchTemplate(_activeEvent, _activeChannel);
    if (provider.activeTemplate != null) {
      setState(() {
        _subjectController.text = provider.activeTemplate!['subject'] ?? "";
        _bodyController.text = provider.activeTemplate!['body'] ?? "";
        _isActive = provider.activeTemplate!['isActive'] ?? true;
      });
    } else {
      setState(() {
        _subjectController.clear();
        _bodyController.clear();
        _isActive = true;
      });
    }
  }

  Future<void> _saveTemplate() async {
    final provider = context.read<NotificationProvider>();
    final success = await provider.saveTemplate({
      'eventName': _activeEvent,
      'channel': _activeChannel,
      'subject': _subjectController.text,
      'body': _bodyController.text,
      'isActive': _isActive,
    });
    if (success && mounted) {
      await provider.fetchTemplates();
      await provider.fetchTemplate(_activeEvent, _activeChannel);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Template saved successfully!"),
          backgroundColor: Color(0xFF003366),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteTemplate() async {
    final provider = context.read<NotificationProvider>();
    final templateId = provider.activeTemplate?['id']?.toString();
    if (templateId == null || templateId.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template'),
        content: const Text(
          'Remove the current template for this event and channel?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await provider.deleteTemplate(templateId);
    if (success && mounted) {
      await provider.fetchTemplates();
      await _loadTemplate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Template deleted successfully'),
          backgroundColor: Color(0xFF003366),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _insertVariable(String key) {
    final text = _bodyController.text;
    final selection = _bodyController.selection;

    if (selection.start >= 0) {
      final newText = text.replaceRange(selection.start, selection.end, key);
      _bodyController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.start + key.length,
        ),
      );
    } else {
      _bodyController.text += key;
    }
  }

  bool _hasTemplateForEvent(NotificationProvider provider, String eventName) {
    return provider.templates.any(
      (template) =>
          template['eventName'] == eventName &&
          template['channel'] == _activeChannel,
    );
  }

  List<Map<String, dynamic>> _templatesForActiveChannel(
    NotificationProvider provider,
  ) {
    final filtered = provider.templates
        .where((template) => template['channel'] == _activeChannel)
        .toList();
    filtered.sort(
      (a, b) => (a['eventName'] ?? '').toString().compareTo(
        (b['eventName'] ?? '').toString(),
      ),
    );
    return filtered;
  }

  Map<String, String> _previewData() {
    final eventLabel = _events[_activeEvent] ?? _activeEvent;
    return buildNotificationTemplatePreviewData(
      eventLabel: eventLabel,
      channel: _activeChannel,
    );
  }

  String _previewValue(String template) {
    return replaceNotificationTemplatePlaceholders(template, _previewData());
  }

  Widget _buildResolvedPreview() {
    final previewSubject = _previewValue(_subjectController.text.trim());
    final previewBody = _previewValue(_bodyController.text);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _activeChannel == 'email'
                ? 'From $kNotificationEmailSenderName'
                : 'Resolved WhatsApp preview',
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (_activeChannel == 'email') ...[
            const SizedBox(height: 8),
            Text(
              previewSubject.isEmpty ? 'No subject yet' : previewSubject,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Text(
              previewBody.trim().isEmpty
                  ? 'Missing ya blank placeholders yahan backend ki tarah empty render honge.'
                  : previewBody,
              style: TextStyle(
                color: previewBody.trim().isEmpty
                    ? const Color(0xFF94A3B8)
                    : Colors.white,
                fontSize: 12,
                height: 1.5,
                fontFamily: _activeChannel == 'whatsapp' ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _subjectController.removeListener(_handleDraftChanged);
    _bodyController.removeListener(_handleDraftChanged);
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "NOTIFICATION TEMPLATES",
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              return Padding(
                padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                child: ElevatedButton.icon(
                  onPressed: provider.isTemplateLoading ? null : _saveTemplate,
                  icon: provider.isTemplateLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(LucideIcons.save, size: 16),
                  label: Text(
                    provider.isTemplateLoading ? "SAVING..." : "SAVE",
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003366),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              );
            },
          ),
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              final hasCurrentTemplate =
                  provider.activeTemplate?['id']?.toString().isNotEmpty == true;
              return Padding(
                padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                child: OutlinedButton.icon(
                  onPressed: (!hasCurrentTemplate || provider.isTemplateLoading)
                      ? null
                      : _deleteTemplate,
                  icon: const Icon(LucideIcons.trash2, size: 16),
                  label: const Text('DELETE'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) => Row(
          children: [
            // Sidebar - Event Types
            Container(
              width: 160,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(right: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
                    child: Text(
                      "EVENT TYPES",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      children: _events.entries.map((e) {
                        bool active = _activeEvent == e.key;
                        final hasTemplate = _hasTemplateForEvent(
                          provider,
                          e.key,
                        );
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: InkWell(
                            onTap: () {
                              setState(() => _activeEvent = e.key);
                              _loadTemplate();
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: active
                                    ? const Color(0xFF003366)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: active
                                    ? [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF003366,
                                          ).withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  if (hasTemplate)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        color: active
                                            ? Colors.white
                                            : const Color(0xFF003366),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  Expanded(
                                    child: Text(
                                      e.value,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: active
                                            ? FontWeight.bold
                                            : FontWeight.w600,
                                        color: active
                                            ? Colors.white
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                  if (active)
                                    const Icon(
                                      LucideIcons.check,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Main Content
            Expanded(
              child:
                  provider.isTemplateLoading && provider.activeTemplate == null
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF003366),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header & Active Toggle
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${_events[_activeEvent]} ${_activeChannel.toUpperCase()}"
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  const Text(
                                    "Design how this notification will look",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    provider.activeTemplate == null
                                        ? 'No saved template for this event/channel yet'
                                        : 'Saved template is loaded from backend',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF94A3B8),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFF1F5F9),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Text(
                                      "ACTIVE",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF64748B),
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Switch.adaptive(
                                      value: _isActive,
                                      activeTrackColor: const Color(0xFF003366),
                                      onChanged: (v) =>
                                          setState(() => _isActive = v),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Channel Tabs
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _channelTab("Email", 'email', LucideIcons.mail),
                                _channelTab(
                                  "WhatsApp",
                                  'whatsapp',
                                  LucideIcons.messageSquare,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_activeChannel == 'email') ...[
                                _buildSectionLabel("EMAIL SUBJECT"),
                                TextField(
                                  controller: _subjectController,
                                  decoration: _inputDeco(
                                    "Enter email subject...",
                                  ),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF1F8),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFD6E4F2),
                                  ),
                                ),
                                child: const Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      LucideIcons.info,
                                      size: 16,
                                      color: Color(0xFF003366),
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        "Available variables are loaded above the body. Tap any chip to insert it at the current cursor position.",
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF003366),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildSectionLabel("AVAILABLE VARIABLES"),
                              SizedBox(
                                height: 78,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: _variables.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 10),
                                  itemBuilder: (context, index) {
                                    final variable = _variables[index];
                                    return _variableChip(
                                      keyText: variable['key']!,
                                      label: variable['label']!,
                                      onTap: () =>
                                          _insertVariable(variable['key']!),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildSectionLabel(
                                _activeChannel == 'email'
                                    ? "EMAIL BODY (HTML SUPPORTED)"
                                    : "WHATSAPP MESSAGE",
                              ),
                              TextField(
                                controller: _bodyController,
                                maxLines: 12,
                                decoration: _inputDeco("Enter content here..."),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontFamily: 'monospace',
                                  color: Color(0xFF334155),
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildSectionLabel("RESOLVED PREVIEW"),
                              _buildResolvedPreview(),
                              const SizedBox(height: 24),
                              _buildSectionLabel("SAVED TEMPLATES"),
                              Container(
                                height: 160,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFF1F5F9),
                                  ),
                                ),
                                child: Builder(
                                  builder: (context) {
                                    final templates =
                                        _templatesForActiveChannel(provider);
                                    if (templates.isEmpty) {
                                      return const Center(
                                        child: Text(
                                          'No saved templates for this channel',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF94A3B8),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      );
                                    }

                                    return ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: templates.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(width: 10),
                                      itemBuilder: (context, index) {
                                        final template = templates[index];
                                        final eventName =
                                            template['eventName']?.toString() ??
                                            '';
                                        final isCurrent =
                                            eventName == _activeEvent &&
                                            template['channel'] ==
                                                _activeChannel;
                                        return InkWell(
                                          onTap: () {
                                            setState(
                                              () => _activeEvent = eventName,
                                            );
                                            _loadTemplate();
                                          },
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: Container(
                                            width: 180,
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: isCurrent
                                                  ? const Color(0xFFEAF1F8)
                                                  : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isCurrent
                                                    ? const Color(0xFFD6E4F2)
                                                    : const Color(0xFFF1F5F9),
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  _events[eventName] ??
                                                      eventName,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color: isCurrent
                                                        ? const Color(
                                                            0xFF003366,
                                                          )
                                                        : const Color(
                                                            0xFF64748B,
                                                          ),
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  template['subject']
                                                              ?.toString()
                                                              .isNotEmpty ==
                                                          true
                                                      ? template['subject']
                                                            .toString()
                                                      : 'No subject',
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    color: Color(0xFF94A3B8),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _channelTab(String label, String code, IconData icon) {
    bool active = _activeChannel == code;
    return InkWell(
      onTap: () {
        setState(() => _activeChannel = code);
        _loadTemplate();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: active ? const Color(0xFF003366) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: active
                    ? const Color(0xFF1E293B)
                    : const Color(0xFF64748B),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: Color(0xFF94A3B8),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _variableChip({
    required String keyText,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 180,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD6E4F2)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF003366).withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              keyText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Color(0xFF003366),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF94A3B8),
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.all(20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Color(0xFFF1F5F9)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Color(0xFFF1F5F9)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Color(0xFF003366), width: 2),
      ),
    );
  }
}
