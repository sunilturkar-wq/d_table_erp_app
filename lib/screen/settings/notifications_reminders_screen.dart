import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/notification_provider.dart';
import '../../utils/notification_template_helper.dart';

class NotificationsRemindersScreen extends StatefulWidget {
  const NotificationsRemindersScreen({super.key});

  @override
  State<NotificationsRemindersScreen> createState() =>
      _NotificationsRemindersScreenState();
}

class _NotificationsRemindersScreenState
    extends State<NotificationsRemindersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _mainTabController;
  int _activeRoleTab = 0; // 0: Admin, 1: Manager, 2: Member

  // Template State
  String _activeEventTemplate = 'newTask';
  String _activeChannel = 'email'; // 'email' or 'whatsapp'
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  bool _isTemplateActive = true;

  final List<String> _templateVariables = [
    '{taskId}',
    '{taskTitle}',
    '{taskDescription}',
    '{priority}',
    '{category}',
    '{dueDate}',
    '{assignerName}',
    '{doerName}',
    '{updatedBy}',
    '{status}',
    '{remark}',
    '{commenterName}',
    '{taskList}',
    '{frequency}',
    '{startDate}',
    '{endDate}',
    '{voiceNoteUrl}',
    '{referenceDocs}',
    '{evidenceUrl}',
  ];

  @override
  void initState() {
    super.initState();
    _subjectController.addListener(_handleTemplateDraftChanged);
    _bodyController.addListener(_handleTemplateDraftChanged);
    _mainTabController = TabController(length: 2, vsync: this);
    _mainTabController.addListener(() {
      setState(() {});
      if (_mainTabController.index == 1 && _mainTabController.indexIsChanging) {
        _loadTemplateWorkspace();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<NotificationProvider>();
      await provider.fetchNotificationSettings();
      await provider.fetchTemplates();
      if (mounted && _mainTabController.index == 1) {
        await _fetchCurrentTemplate();
      }
    });
  }

  void _handleTemplateDraftChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadTemplateWorkspace() async {
    final provider = context.read<NotificationProvider>();
    await provider.fetchTemplates();
    if (mounted) {
      await _fetchCurrentTemplate();
    }
  }

  Future<void> _fetchCurrentTemplate() async {
    final provider = context.read<NotificationProvider>();
    await provider.fetchTemplate(_activeEventTemplate, _activeChannel);
    if (!mounted) return;
    if (provider.activeTemplate != null) {
      _subjectController.text = provider.activeTemplate!['subject'] ?? '';
      _bodyController.text = provider.activeTemplate!['body'] ?? '';
      setState(() {
        _isTemplateActive = provider.activeTemplate!['isActive'] ?? true;
      });
    } else {
      _subjectController.clear();
      _bodyController.clear();
      setState(() {
        _isTemplateActive = true;
      });
    }
  }

  Future<void> _saveCurrentTemplate() async {
    final provider = context.read<NotificationProvider>();
    final success = await provider.saveTemplate({
      'eventName': _activeEventTemplate,
      'channel': _activeChannel,
      'subject': _subjectController.text.trim(),
      'body': _bodyController.text.trim(),
      'isActive': _isTemplateActive,
    });

    if (!mounted) return;

    if (success) {
      await provider.fetchTemplates();
      await provider.fetchTemplate(_activeEventTemplate, _activeChannel);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Template saved successfully' : 'Failed to save template',
          ),
          backgroundColor: success ? const Color(0xFF003366) : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteCurrentTemplate() async {
    final provider = context.read<NotificationProvider>();
    final templateId = provider.activeTemplate?['id']?.toString();
    if (templateId == null || templateId.isEmpty) {
      return;
    }

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

    if (confirm != true) {
      return;
    }

    final success = await provider.deleteTemplate(templateId);
    if (!mounted) return;

    if (success) {
      await provider.fetchTemplates();
      await _fetchCurrentTemplate();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Template deleted successfully'
              : 'Failed to delete template',
        ),
        backgroundColor: success ? const Color(0xFF003366) : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _insertVariable(String variable) {
    int cursorPosition = _bodyController.selection.base.offset;
    if (cursorPosition == -1) cursorPosition = _bodyController.text.length;

    String currentText = _bodyController.text;
    String newText =
        currentText.substring(0, cursorPosition) +
        variable +
        currentText.substring(cursorPosition);

    _bodyController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: cursorPosition + variable.length,
      ),
    );
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
    final eventLabel =
        kNotificationTemplateEventLabels[_activeEventTemplate] ??
        _activeEventTemplate;
    return buildNotificationTemplatePreviewData(
      eventLabel: eventLabel,
      channel: _activeChannel,
    );
  }

  String _previewValue(String template) {
    return replaceNotificationTemplatePlaceholders(template, _previewData());
  }

  Widget _buildTemplatePreviewCard() {
    final previewSubject = _previewValue(_subjectController.text.trim());
    final previewBody = _previewValue(_bodyController.text);
    final hasBody = previewBody.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _activeChannel == 'email'
                    ? Icons.mail_outline_rounded
                    : Icons.smartphone_outlined,
                size: 16,
                color: const Color(0xFF34D399),
              ),
              const SizedBox(width: 8),
              Text(
                _activeChannel == 'email'
                    ? 'LIVE EMAIL PREVIEW'
                    : 'LIVE WHATSAPP PREVIEW',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_activeChannel == 'email') ...[
            Text(
              'From $kNotificationEmailSenderName',
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              previewSubject.isEmpty ? 'No subject yet' : previewSubject,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
          ] else ...[
            Text(
              'Campaign/body preview with backend-style placeholder cleanup',
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Text(
              hasBody
                  ? previewBody
                  : 'Blank, null, ya missing placeholders preview me empty aaenge. Body content add karte hi yahan resolved message dikh jayega.',
              style: TextStyle(
                color: hasBody ? Colors.white : const Color(0xFF94A3B8),
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
    _mainTabController.dispose();
    _subjectController.removeListener(_handleTemplateDraftChanged);
    _bodyController.removeListener(_handleTemplateDraftChanged);
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
          "NOTIFICATIONS",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: const Color(0xFF003366),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _mainTabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: "PREFERENCES"),
            Tab(text: "TEMPLATES"),
          ],
        ),
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && _mainTabController.index == 0) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _mainTabController,
            physics:
                const NeverScrollableScrollPhysics(), // complex nested scrolling
            children: [
              _buildPreferencesTab(provider),
              _buildTemplatesTab(provider),
            ],
          );
        },
      ),
      bottomNavigationBar: _mainTabController.index == 0
          ? _buildBottomSaveBar()
          : null,
    );
  }

  // ==========================================
  // TEMPLATES TAB LOGIC
  // ==========================================
  Widget _buildTemplatesTab(NotificationProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Rail: Events
        Container(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  "EVENT TYPES",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    fontSize: 11,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: kNotificationTemplateEventLabels.length,
                  itemBuilder: (context, index) {
                    final entry = kNotificationTemplateEventLabels.entries
                        .elementAt(index);
                    final isSelected = _activeEventTemplate == entry.key;
                    final hasTemplate = _hasTemplateForEvent(
                      provider,
                      entry.key,
                    );

                    return InkWell(
                      onTap: () async {
                        setState(() {
                          _activeEventTemplate = entry.key;
                        });
                        await _fetchCurrentTemplate();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF003366)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (hasTemplate)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF003366),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            Text(
                              entry.value,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 14,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Editor Side
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Channel Tabs
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                color: Colors.white,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildChannelTab('email', 'Email', Icons.mail_outline),
                      const SizedBox(width: 12),
                      _buildChannelTab(
                        'whatsapp',
                        'WhatsApp',
                        Icons.smartphone_outlined,
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),

              // Editor Space
              Expanded(
                child:
                    provider.isTemplateLoading &&
                        provider.activeTemplate == null
                    ? const Center(child: CircularProgressIndicator())
                    : _buildTemplateEditor(provider),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChannelTab(String key, String label, IconData icon) {
    final isSelected = _activeChannel == key;
    return InkWell(
      onTap: () async {
        setState(() {
          _activeChannel = key;
        });
        await _fetchCurrentTemplate();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF003366) : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? const Color(0xFF003366)
                  : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF003366)
                    : Colors.grey.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateEditor(NotificationProvider provider) {
    final eventTitle =
        (kNotificationTemplateEventLabels[_activeEventTemplate] ??
                _activeEventTemplate)
            .toUpperCase();
    final channelTitle = _activeChannel.toUpperCase();
    final savedTemplates = _templatesForActiveChannel(provider);
    final hasCurrentTemplate =
        provider.activeTemplate?['id']?.toString().isNotEmpty == true;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$eventTitle $channelTitle TEMPLATE",
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Design how this notification will look",
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
              const SizedBox(height: 6),
              Text(
                provider.activeTemplate == null
                    ? 'No saved template for this event and channel yet'
                    : 'Saved template is loaded from backend',
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "ACTIVE",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch.adaptive(
                        value: _isTemplateActive,
                        activeColor: const Color(0xFF003366),
                        onChanged: (val) {
                          setState(() {
                            _isTemplateActive = val;
                          });
                        },
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: provider.isTemplateLoading
                        ? null
                        : _saveCurrentTemplate,
                    icon: provider.isTemplateLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save, size: 16, color: Colors.white),
                    label: Text(
                      provider.isTemplateLoading
                          ? 'Saving...'
                          : 'Save Template',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003366),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed:
                        (!hasCurrentTemplate || provider.isTemplateLoading)
                        ? null
                        : _deleteCurrentTemplate,
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Delete Template'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_activeChannel == 'email') ...[
                const Text(
                  "EMAIL SUBJECT",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    color: Colors.grey,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _subjectController,
                  decoration: InputDecoration(
                    hintText: "Enter email subject...",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF003366).withOpacity(0.05),
                  border: Border.all(
                    color: const Color(0xFF003366).withOpacity(0.2),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.green.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Available variables are shown in the row below. Tap one to insert it into the body at the current cursor position.",
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "AVAILABLE VARIABLES (${_templateVariables.length})",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: Colors.grey,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 64,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _templateVariables.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final variable = _templateVariables[index];
                    return InkWell(
                      onTap: () => _insertVariable(variable),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFD6E4F2)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF003366).withOpacity(0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            variable,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF003366),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "${_activeChannel == 'email' ? 'EMAIL' : 'WHATSAPP'} BODY",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: Colors.grey,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _bodyController,
                maxLines: 10,
                decoration: InputDecoration(
                  hintText: "Enter your content here...",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "RESOLVED PREVIEW",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: Colors.grey,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              _buildTemplatePreviewCard(),
              const SizedBox(height: 24),
              Text(
                "SAVED TEMPLATES (${savedTemplates.length})",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: Colors.grey,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: savedTemplates.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'No saved templates for this channel',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(8),
                        itemCount: savedTemplates.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final template = savedTemplates[index];
                          final eventName =
                              template['eventName']?.toString() ?? '';
                          final isCurrent = eventName == _activeEventTemplate;
                          return InkWell(
                            onTap: () async {
                              setState(() {
                                _activeEventTemplate = eventName;
                              });
                              await _fetchCurrentTemplate();
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: 180,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isCurrent
                                    ? const Color(0xFFEAF1F8)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isCurrent
                                      ? const Color(0xFFD6E4F2)
                                      : const Color(0xFFF1F5F9),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    kNotificationTemplateEventLabels[eventName] ??
                                        eventName,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isCurrent
                                          ? const Color(0xFF003366)
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    template['subject']
                                                ?.toString()
                                                .isNotEmpty ==
                                            true
                                        ? template['subject'].toString()
                                        : 'No subject',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
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
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // PREFERENCES TAB LOGIC
  // ==========================================
  Widget _buildPreferencesTab(NotificationProvider provider) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("GLOBAL CHANNELS"),
          _buildGlobalToggles(provider),
          const SizedBox(height: 30),

          _buildSectionHeader("REMINDER SCHEDULE"),
          _buildReminderSettings(provider),
          const SizedBox(height: 30),

          _buildSectionHeader("WEEKLY OFFS"),
          _buildWeeklyOffs(provider),
          const SizedBox(height: 30),

          _buildSectionHeader("NOTIFICATION CHANNELS"),
          _buildChannelsMatrix(provider),
          const SizedBox(height: 30),

          _buildSectionHeader("NOTIFICATION FREQUENCY"),
          _buildFrequencyMatrix(provider),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Color(0xFF94A3B8),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildGlobalToggles(NotificationProvider provider) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _toggleCard(
                "WhatsApp Notifications",
                Icons.chat_bubble_outline,
                provider.whatsappNotifications,
                (v) => provider.updateGlobal('whatsappNotifications', v),
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _toggleCard(
                "Email Notifications",
                Icons.mail_outline,
                provider.emailNotifications,
                (v) => provider.updateGlobal('emailNotifications', v),
                Colors.redAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.public, color: Colors.blueGrey),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  "Timezone",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: provider.timezone.isEmpty
                      ? 'Asia/Kolkata'
                      : provider.timezone,
                  items: const [
                    DropdownMenuItem(
                      value: 'Asia/Kolkata',
                      child: Text('Asia/Kolkata'),
                    ),
                    DropdownMenuItem(value: 'UTC', child: Text('UTC')),
                    DropdownMenuItem(
                      value: 'America/New_York',
                      child: Text('America/New_York'),
                    ),
                    DropdownMenuItem(
                      value: 'Europe/London',
                      child: Text('Europe/London'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) provider.updateGlobal('timezone', val);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _toggleCard(
    String title,
    IconData icon,
    bool value,
    Function(bool) onChanged,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Switch.adaptive(
            value: value,
            activeColor: const Color(0xFF003366),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildReminderSettings(NotificationProvider provider) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF003366).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.access_time_filled,
                  color: Color(0xFF003366),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Daily Reminder Time",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      provider.dailyReminderTime,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null)
                    provider.updateReminderTime(
                      "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}",
                    );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF1F5F9),
                  elevation: 0,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text("Edit"),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _toggleCard(
                "WhatsApp Reminders",
                Icons.chat_bubble_outline,
                provider.whatsappReminders,
                (v) => provider.updateGlobal('whatsappReminders', v),
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _toggleCard(
                "Email Reminders",
                Icons.mail_outline,
                provider.emailReminders,
                (v) => provider.updateGlobal('emailReminders', v),
                Colors.redAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _toggleCard(
                "Daily Task Report",
                Icons.analytics_outlined,
                provider.dailyTaskReport,
                (v) => provider.updateGlobal('dailyTaskReport', v),
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Container()),
          ],
        ),
      ],
    );
  }

  Widget _buildWeeklyOffs(NotificationProvider provider) {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final fullDays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (index) {
          bool isOff = provider.weeklyOffs.contains(fullDays[index]);
          return GestureDetector(
            onTap: () => provider.toggleWeeklyOff(fullDays[index]),
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isOff ? const Color(0xFF003366) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isOff
                          ? const Color(0xFF003366)
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.check,
                      size: 16,
                      color: isOff ? Colors.white : Colors.transparent,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  days[index],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isOff ? const Color(0xFF003366) : Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildChannelsMatrix(NotificationProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.white),
          columns: const [
            DataColumn(
              label: Text(
                "Events",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            DataColumn(
              label: Text(
                "Admin",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            DataColumn(
              label: Text(
                "Manager",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            DataColumn(
              label: Text(
                "Member",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
          rows: kNotificationPreferenceEventLabels.entries.map((entry) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    entry.value,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DataCell(_buildMatrixCheck(provider, entry.key, 'admin')),
                DataCell(_buildMatrixCheck(provider, entry.key, 'manager')),
                DataCell(_buildMatrixCheck(provider, entry.key, 'member')),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFrequencyMatrix(NotificationProvider provider) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: List.generate(
              kNotificationRoles.length,
              (index) => Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _activeRoleTab = index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _activeRoleTab == index
                          ? Colors.white
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: _activeRoleTab == index
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                              ),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Text(
                        kNotificationRoles[index],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _activeRoleTab == index
                              ? const Color(0xFF003366)
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(
                const Color(0xFF003366),
              ),
              columns: const [
                DataColumn(
                  label: Text(
                    "Events",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Once",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Daily",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Weekly",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Monthly",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Yearly",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
              rows: kNotificationPreferenceEventLabels.entries.map((entry) {
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        entry.value,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataCell(_buildFreqCheck(provider, entry.key, 'once')),
                    DataCell(_buildFreqCheck(provider, entry.key, 'daily')),
                    DataCell(_buildFreqCheck(provider, entry.key, 'weekly')),
                    DataCell(_buildFreqCheck(provider, entry.key, 'monthly')),
                    DataCell(_buildFreqCheck(provider, entry.key, 'yearly')),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMatrixCheck(
    NotificationProvider provider,
    String event,
    String role,
  ) {
    bool isChecked = provider.notificationChannels[event]?[role] ?? false;
    return Center(
      child: GestureDetector(
        onTap: () => provider.toggleChannel(event, role),
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: isChecked ? const Color(0xFF003366) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isChecked ? const Color(0xFF003366) : Colors.grey.shade300,
            ),
          ),
          child: isChecked
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : null,
        ),
      ),
    );
  }

  Widget _buildFreqCheck(
    NotificationProvider provider,
    String event,
    String freq,
  ) {
    final role = kNotificationRoleKeys[_activeRoleTab];
    bool isChecked =
        provider.notificationFrequency[role]?[event]?[freq] ?? false;
    return Center(
      child: GestureDetector(
        onTap: () => provider.toggleFrequency(event, freq, role),
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: isChecked ? const Color(0xFF003366) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isChecked ? const Color(0xFF003366) : Colors.grey.shade300,
            ),
          ),
          child: isChecked
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : null,
        ),
      ),
    );
  }

  Widget _buildBottomSaveBar() {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: provider.isLoading
              ? null
              : () async {
                  final success = await provider.saveSettings();
                  if (!mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Notification settings saved successfully'
                            : (provider.errorMessage ??
                                  'Failed to save notification settings'),
                      ),
                      backgroundColor: success
                          ? const Color(0xFF003366)
                          : Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
          icon: provider.isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save, color: Colors.white),
          label: Text(
            provider.isLoading ? "Saving..." : "Save Changes",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF003366),
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}
