import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../model/delegate_model.dart';
import '../../provider/auth_provider.dart';
import '../../provider/delegation_provider.dart';
import '../../provider/user_provider.dart';
import '../../widget/app_dropdown.dart';
import '../../widget/assign_task_sheet.dart';

class ActivityTaskDetailScreen extends StatefulWidget {
  final dynamic task;
  final bool allowEdit;

  const ActivityTaskDetailScreen({
    super.key,
    required this.task,
    this.allowEdit = false,
  });

  @override
  State<ActivityTaskDetailScreen> createState() =>
      _ActivityTaskDetailScreenState();
}

class _ActivityTaskDetailScreenState extends State<ActivityTaskDetailScreen> {
  // Removed remarkController
  String selectedStatus = "Pending";
  DateTime? _holdTillDate;
  bool _isDetailLoading = true;
  DelegationModel? _currentTask;

  // Audio Player State
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();

    // Handle both DelegationModel and Map inputs
    if (widget.task is DelegationModel) {
      _currentTask = widget.task as DelegationModel;
      selectedStatus = _currentTask?.status ?? 'Pending';
    } else if (widget.task is Map) {
      selectedStatus = widget.task['status'] ?? 'Pending';
    }

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });
    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
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
          selectedStatus = rawResponse.status;
          _isDetailLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isDetailLoading = false);
    }
  }

  void _showUnavailableMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _showAssignBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => const AssignTaskSheet(),
    ).then((_) {
      _loadTaskDetail();
    });
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
                    IconButton(
                      icon: const Icon(
                        LucideIcons.trash2,
                        color: Colors.red,
                        size: 20,
                      ),
                      onPressed: () {
                        _showUnavailableMessage(
                          'Delete action is not available from activity detail. Open the task detail screen for task actions.',
                        );
                      },
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

            // 1. Core Information
            _buildSectionCard(
              title: "CORE INFORMATION",
              icon: LucideIcons.info,
              child: Wrap(
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
                    Colors.blueGrey,
                    task.priority,
                  ),
                  _infoTile(
                    "DEADLINE",
                    LucideIcons.calendar,
                    Colors.redAccent,
                    _formatDate(task.dueDate),
                  ),
                  _infoTile(
                    "EVIDENCE",
                    LucideIcons.shieldCheck,
                    Colors.teal,
                    task.evidenceRequired ? "Required" : "Not Required",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Involved Parties
            _buildInvolvedPartiesCard(task),
            const SizedBox(height: 16),

            // Metadata
            _buildMetadataCard(task),
            const SizedBox(height: 16),

            // 2. Sub Tasks
            _buildSectionCard(
              title: "SUB TASKS",
              icon: LucideIcons.layers,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _countBadge(
                    "${task.checklistItems.where((i) => (i['status'] == 'Completed' || i['status'] == 'Done')).length}/${task.checklistItems.length}",
                  ),
                  const SizedBox(width: 8),
                  _actionIcon(LucideIcons.plus, _showAssignBottomSheet),
                ],
              ),
              child: task.checklistItems.isEmpty
                  ? Center(
                      child: Column(
                        children: [
                          const Text(
                            "NO SUB TASKS YET",
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _showAssignBottomSheet,
                            icon: const Icon(LucideIcons.plus, size: 16),
                            label: const Text("CREATE SUB TASK"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF3B82F6),
                              side: const BorderSide(color: Color(0xFF3B82F6)),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: task.checklistItems.map((item) {
                        final isDone =
                            item['status'] == 'Completed' ||
                            item['status'] == 'Done';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Icon(
                                isDone
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                size: 16,
                                color: isDone ? Colors.green : Colors.grey,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item['text'] ?? '',
                                  style: TextStyle(
                                    fontSize: 13,
                                    decoration: isDone
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 16),

            // Observer Mode
            _buildObserverModeCard(),
            const SizedBox(height: 24),

            // 5. Revision & Remark History
            _buildSectionCard(
              title: "REVISION HISTORY",
              icon: LucideIcons.history,
              child: task.remarks.isEmpty
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
                      children: task.remarks
                          .map(
                            (r) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildHistoryItem(
                                task.status,
                                r.date,
                                r.remark,
                                r.assignedUserId,
                                "OLD: PENDING",
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
              child: const Center(
                child: Text(
                  "NO REMARKS YET",
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
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
          const Icon(Icons.check_circle, size: 14, color: Color(0xFF003366)),
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

  Widget _buildHistoryItem(
    String status,
    String date,
    String comment,
    String user,
    String oldStatus,
  ) {
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
              _statusBadge(status, const Color(0xFF003366)),
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

  Widget _actionIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: const Color(0xFF64748B)),
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

  Widget _buildObserverModeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFEEF2FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.bell,
              color: Color(0xFF4F46E5),
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "OBSERVER MODE",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "YOU ARE CURRENTLY SUBSCRIBED.",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.check_circle_outline,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
                SizedBox(width: 6),
                Text(
                  "SUBSCRIBED",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
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
