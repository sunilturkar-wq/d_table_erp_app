import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:d_table_erp_app/provider/theme_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../provider/auth_provider.dart';
import '../../provider/group_provider.dart';
import '../../provider/user_provider.dart';
import '../../model/group_model.dart';
import '../../widget/custom_date_range_picker.dart';
import '../../widget/app_dropdown.dart';
import '../../widget/assign_task_sheet.dart';
import '../home/task_detail.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupDetailScreen({
    Key? key,
    required this.groupId,
    required this.groupName,
  }) : super(key: key);

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // Tasks Tab State
  String _activeSubTab = 'All Task';
  String _selectedStatusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupProvider>().fetchGroupDetails(widget.groupId);
      context.read<UserProvider>().fetchUsers();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showAssignTaskSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AssignTaskSheet(groupId: widget.groupId),
    ).then((_) {
      // Refresh group details after task is assigned
      if (mounted) {
        context.read<GroupProvider>().fetchGroupDetails(widget.groupId);
      }
    });
  }

  Future<void> _pickEditImage(
    StateSetter setDialogState,
    ValueChanged<File> onPicked,
  ) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    setDialogState(() => onPicked(File(pickedFile.path)));
  }

  void _showEditGroupDialog() {
    final groupProvider = context.read<GroupProvider>();
    final userProvider = context.read<UserProvider>();
    final group = groupProvider.selectedGroup;
    if (group == null) return;

    final nameController = TextEditingController(text: group.name);
    final descController = TextEditingController(text: group.description ?? '');
    final selectedMemberIds = groupProvider.groupMembers
        .map((m) => (m['userId'] ?? m['id']).toString())
        .where((id) => id.isNotEmpty)
        .toList();
    File? selectedImage;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          title: const Text(
            "Edit Group",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: MediaQuery.of(dialogContext).size.width > 600
                ? 540
                : MediaQuery.of(dialogContext).size.width * 0.9,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => _pickEditImage(
                      setDialogState,
                      (file) => selectedImage = file,
                    ),
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: ThemeProvider.primaryBlue.withOpacity(
                        0.12,
                      ),
                      backgroundImage: selectedImage != null
                          ? FileImage(selectedImage!)
                          : (group.imageUrl != null &&
                                    group.imageUrl!.isNotEmpty
                                ? NetworkImage(group.imageUrl!) as ImageProvider
                                : null),
                      child:
                          selectedImage == null &&
                              (group.imageUrl == null ||
                                  group.imageUrl!.isEmpty)
                          ? const Icon(Icons.add_a_photo_outlined)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Group Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Members',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 260),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView(
                      shrinkWrap: true,
                      children: userProvider.users.map((user) {
                        final isSelected = selectedMemberIds.contains(user.id);
                        return CheckboxListTile(
                          dense: true,
                          value: isSelected,
                          title: Text(user.fullName),
                          subtitle: Text(
                            user.designation.isNotEmpty
                                ? user.designation
                                : user.workEmail,
                          ),
                          onChanged: (value) {
                            setDialogState(() {
                              if (value == true) {
                                selectedMemberIds.add(user.id);
                              } else {
                                selectedMemberIds.remove(user.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
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
            Consumer<GroupProvider>(
              builder: (context, provider, _) => ElevatedButton(
                onPressed: provider.isLoading
                    ? null
                    : () async {
                        if (nameController.text.trim().isEmpty) return;
                        final success = await provider.updateGroup(
                          widget.groupId,
                          name: nameController.text.trim(),
                          description: descController.text.trim(),
                          memberIds: selectedMemberIds,
                          image: selectedImage,
                          existingImageUrl: group.imageUrl,
                        );
                        if (!mounted) return;
                        if (success) {
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Group updated successfully'),
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeProvider.primaryBlue,
                ),
                child: provider.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = ThemeProvider.primaryBlue;
    final selectedGroup = context.watch<GroupProvider>().selectedGroup;
    final displayGroup =
        selectedGroup ??
        GroupModel(
          id: widget.groupId,
          name: widget.groupName,
          description: '',
          createdBy: '',
          memberCount: 0,
        );

    return Scaffold(
      backgroundColor: Colors.white,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            backgroundColor: primary,
            expandedHeight: 120,
            pinned: true,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: const Text(
                "GROUP TASK",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1.2,
                ),
              ),
              background: Container(color: primary),
            ),
          ),
        ],
        body: Column(
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child:
                          displayGroup.imageUrl != null &&
                              displayGroup.imageUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                displayGroup.imageUrl!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(
                              LucideIcons.users,
                              color: Colors.white,
                              size: 24,
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayGroup.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          displayGroup.description?.isNotEmpty == true
                              ? displayGroup.description!
                              : "Manage tasks and monitor performance",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _showEditGroupDialog,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: primary.withOpacity(0.25)),
                      ),
                      child: Icon(LucideIcons.pencil, color: primary, size: 18),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Styled Add Button in Header (Restore functionality here)
                  GestureDetector(
                    onTap: _showAssignTaskSheet,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primary, primary.withOpacity(0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        LucideIcons.plus,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Filter Dropdowns Row
            Consumer<GroupProvider>(
              builder: (context, provider, _) {
                return Container(
                  color: Colors.white,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFilterLabel("DATE RANGE"),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: 150,
                              child: AppDropdown<String>(
                                isCompact: true,
                                value: provider.dateRange,
                                items: const [
                                  "Today",
                                  "Yesterday",
                                  "This Week",
                                  "Last Week",
                                  "This Month",
                                  "Last Month",
                                  "This Year",
                                  "All Time",
                                  "Custom",
                                ],
                                labelBuilder: (v) => v,
                                accentColor: primary,
                                onChanged: (val) async {
                                  if (val == "Custom") {
                                    final picked =
                                        await showStylishDateRangePicker(
                                          context,
                                          primary,
                                        );
                                    if (picked != null) {
                                      provider.setDateRange(
                                        "Custom",
                                        start: picked.start,
                                        end: picked.end,
                                      );
                                      provider.fetchGroupDetails(
                                        widget.groupId,
                                      );
                                    }
                                  } else {
                                    provider.setDateRange(val!);
                                    provider.fetchGroupDetails(widget.groupId);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFilterLabel("ASSIGNED TO"),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: 150,
                              child: AppDropdown<dynamic>(
                                isCompact: true,
                                value: provider.assignedTo == "Assigned To"
                                    ? "Assigned To"
                                    : provider.groupMembers.firstWhere(
                                        (m) =>
                                            (m['userId'] ?? m['id']) ==
                                            provider.assignedTo,
                                        orElse: () => null,
                                      ),
                                items: [
                                  "Assigned To",
                                  ...provider.groupMembers,
                                ],
                                labelBuilder: (m) => m is String
                                    ? m
                                    : "${m['firstName'] ?? ''} ${m['lastName'] ?? ''}",
                                accentColor: primary,
                                onChanged: (val) {
                                  if (val == "Assigned To") {
                                    provider.setAssignedTo("Assigned To");
                                  } else {
                                    provider.setAssignedTo(
                                      val['userId'] ?? val['id'],
                                    );
                                  }
                                  provider.fetchGroupDetails(widget.groupId);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFilterLabel("FREQUENCY"),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: 140,
                              child: AppDropdown<String>(
                                isCompact: true,
                                value: provider.frequency,
                                items: const [
                                  "Frequency",
                                  "Once",
                                  "Daily",
                                  "Weekly",
                                  "Monthly",
                                  "Custom",
                                ],
                                labelBuilder: (v) => v,
                                accentColor: primary,
                                onChanged: (val) {
                                  provider.setFrequency(val!);
                                  provider.fetchGroupDetails(widget.groupId);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),

                        SizedBox(
                          width: 40,
                          height: 42,
                          child: ElevatedButton(
                            onPressed: () =>
                                provider.fetchGroupDetails(widget.groupId),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            child: const Icon(Icons.refresh_rounded, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),

            // Tabs Row
            Container(
              color: Colors.white,
              width: double.infinity,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: primary,
                unselectedLabelColor: const Color(0xFF64748B),
                indicatorColor: primary,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                tabs: const [
                  Tab(
                    child: Row(
                      children: [
                        Icon(LucideIcons.layoutDashboard, size: 16),
                        SizedBox(width: 6),
                        Text("DASHBOARD"),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      children: [
                        Icon(LucideIcons.checkCircle2, size: 16),
                        SizedBox(width: 6),
                        Text("TASKS"),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      children: [
                        Icon(LucideIcons.lightbulb, size: 16),
                        SizedBox(width: 6),
                        Text("IDEABOARD"),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      children: [
                        Icon(LucideIcons.link, size: 16),
                        SizedBox(width: 6),
                        Text("LINKS"),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      children: [
                        Icon(LucideIcons.history, size: 16),
                        SizedBox(width: 6),
                        Text("TIMELINE"),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Main Content Area
            Expanded(
              child: Consumer<GroupProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading && provider.selectedGroup == null) {
                    return Center(
                      child: CircularProgressIndicator(color: primary),
                    );
                  }

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDashboardTab(provider),
                      _buildTasksTab(provider),
                      const Center(child: Text("Ideaboard Not Available")),
                      const Center(child: Text("Links Not Available")),
                      const Center(child: Text("Timeline Not Available")),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w900,
        color: Color(0xFF94A3B8),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildDashboardTab(GroupProvider provider) {
    final tasks = provider.groupTasks;
    final members = provider.groupMembers;

    int overdue = tasks.where((t) => t['status'] == 'Overdue').length;
    int pending = tasks
        .where((t) => t['status'] == 'Pending' || t['status'] == 'To Do')
        .length;
    int inProgress = tasks
        .where((t) => t['status'] == 'In Progress' || t['status'] == 'Working')
        .length;
    int completed = tasks
        .where((t) => t['status'] == 'Completed' || t['status'] == 'Done')
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatCard("OVERDUE", overdue, const Color(0xFFEF4444)),
                const SizedBox(width: 12),
                _buildStatCard("PENDING", pending, const Color(0xFFF59E0B)),
                const SizedBox(width: 12),
                _buildStatCard(
                  "IN PROGRESS",
                  inProgress,
                  const Color(0xFF3B82F6),
                ),
                const SizedBox(width: 12),
                _buildStatCard("COMPLETED", completed, const Color(0xFF003366)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "MEMBER PERFORMANCE",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),

          if (members.isEmpty)
            const Center(child: Text("No members available."))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: members.length,
              itemBuilder: (context, index) {
                final member = members[index];
                final doerId = member['userId'] ?? member['id'];
                final name = member['firstName'] != null
                    ? "${member['firstName']} ${member['lastName'] ?? ''}"
                    : "Member";
                final memberTasks = tasks
                    .where(
                      (t) => t['doerId'] == doerId || t['assignedTo'] == doerId,
                    )
                    .toList();
                return _buildMemberPerformanceCard(name, memberTasks);
              },
            ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildMemberPerformanceCard(String name, List memberTasks) {
    int total = memberTasks.length;
    int overdue = memberTasks.where((t) => t['status'] == 'Overdue').length;
    int pending = memberTasks
        .where((t) => t['status'] == 'Pending' || t['status'] == 'To Do')
        .length;
    int completed = memberTasks
        .where((t) => t['status'] == 'Completed' || t['status'] == 'Done')
        .length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF475569), // Fika header color (Slate 600)
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.white24,
                  child: Text(
                    name.isNotEmpty ? name[0] : '?',
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  "TOTAL: $total",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _perfRow("Overdue", overdue, const Color(0xFFEF4444)),
                ),
                Expanded(
                  child: _perfRow("Pending", pending, const Color(0xFFF59E0B)),
                ),
                Expanded(
                  child: _perfRow("Done", completed, const Color(0xFF003366)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _perfRow(String label, int val, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        Text(
          "$val",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, int value, Color color) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(bottom: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "$value",
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  // --- TASKS TAB IMPLEMENTATION (MATCHING WEB IMAGE) ---

  Widget _buildTasksTab(GroupProvider provider) {
    final allTasks = provider.groupTasks;
    final currentUserId = context.read<AuthProvider>().currentUser?.id;

    List finalTasks = allTasks
        .where((t) {
          if (_activeSubTab == 'My Task' &&
              currentUserId != null &&
              currentUserId.isNotEmpty) {
            return (t['doerId'] ?? t['assignedTo']) == currentUserId;
          }
          return true;
        })
        .where((t) {
          if (_selectedStatusFilter == 'All') return true;
          if (_selectedStatusFilter == 'Overdue')
            return t['status'] == 'Overdue';
          if (_selectedStatusFilter == 'Pending')
            return t['status'] == 'Pending' || t['status'] == 'To Do';
          if (_selectedStatusFilter == 'In Progress')
            return t['status'] == 'In Progress' || t['status'] == 'Working';
          if (_selectedStatusFilter == 'Hold') return t['status'] == 'Hold';
          if (_selectedStatusFilter == 'Need Revision')
            return t['status'] == 'Need Revision' || t['status'] == 'Revision';
          if (_selectedStatusFilter == 'Completed')
            return t['status'] == 'Completed' || t['status'] == 'Done';
          return true;
        })
        .toList();

    // 2. Status Filter Counts
    int cAll = allTasks.length;
    int cMy = currentUserId == null
        ? 0
        : allTasks
              .where((t) => (t['doerId'] ?? t['assignedTo']) == currentUserId)
              .length;
    int cOverdue = allTasks.where((t) => t['status'] == 'Overdue').length;
    int cPending = allTasks
        .where((t) => t['status'] == 'Pending' || t['status'] == 'To Do')
        .length;
    int cWorking = allTasks
        .where((t) => t['status'] == 'In Progress' || t['status'] == 'Working')
        .length;
    int cHold = allTasks.where((t) => t['status'] == 'Hold').length;
    int cRevision = allTasks
        .where(
          (t) => t['status'] == 'Need Revision' || t['status'] == 'Revision',
        )
        .length;
    int cDone = allTasks
        .where((t) => t['status'] == 'Completed' || t['status'] == 'Done')
        .length;

    return Column(
      children: [
        // Sub-Tabs Header (All Task | My Task)
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          color: Colors.white,
          child: Row(
            children: [
              _buildSubTabButton("All Task", _activeSubTab == "All Task"),
              const SizedBox(width: 8),
              _buildSubTabButton(
                "My Task",
                _activeSubTab == "My Task",
                count: cMy,
              ),
            ],
          ),
        ),

        // Status Horizontal Filter Bar
        Container(
          height: 60,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildStatusChip("All", const Color(0xFF64748B), cAll),
                _buildStatusChip("Overdue", const Color(0xFFEF4444), cOverdue),
                _buildStatusChip("Pending", const Color(0xFFF59E0B), cPending),
                _buildStatusChip(
                  "In Progress",
                  const Color(0xFFF97316),
                  cWorking,
                ),
                _buildStatusChip("Hold", const Color(0xFFEAB308), cHold),
                _buildStatusChip(
                  "Need Revision",
                  const Color(0xFF3B82F6),
                  cRevision,
                ),
                _buildStatusChip("Completed", const Color(0xFF003366), cDone),
              ],
            ),
          ),
        ),
        const Divider(height: 1, color: Color(0xFFF1F5F9)),

        // Tasks List or Empty State
        Expanded(
          child: finalTasks.isEmpty
              ? _buildEmptyTasksState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: finalTasks.length,
                  itemBuilder: (context, index) =>
                      _buildTaskCard(finalTasks[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildSubTabButton(String label, bool isActive, {int? count}) {
    final primary = ThemeProvider.primaryBlue;
    return GestureDetector(
      onTap: () => setState(() => _activeSubTab = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive ? Border.all(color: const Color(0xFFE2E8F0)) : null,
          boxShadow: isActive
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
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: isActive ? primary : const Color(0xFF64748B),
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              Text(
                "$count",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isActive ? primary : Colors.grey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color, int count) {
    bool isSelected = _selectedStatusFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedStatusFilter = label),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: isSelected
              ? Border.all(color: const Color(0xFFE2E8F0), width: 1.5)
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              "$count",
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTasksState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
            ),
            child: const Icon(
              LucideIcons.clipboardList,
              size: 48,
              color: Color(0xFFCBD5E1),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "No Task Here",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "It seems there are no tasks matching your active filters in this group",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(dynamic task) {
    final status = task['status'] ?? 'Pending';
    Color statusColor = const Color(0xFFF59E0B);
    if (status == 'Completed' || status == 'Done')
      statusColor = const Color(0xFF003366);
    if (status == 'Overdue') statusColor = const Color(0xFFEF4444);
    if (status == 'In Progress' || status == 'Working')
      statusColor = const Color(0xFFF97316);
    if (status == 'Hold') statusColor = const Color(0xFFEAB308);
    if (status == 'Need Revision' || status == 'Revision')
      statusColor = const Color(0xFF3B82F6);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TaskDetailScreen(task: task, allowEdit: true),
          ),
        ).then((_) {
          if (mounted) {
            context.read<GroupProvider>().fetchGroupDetails(widget.groupId);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.clipboardList, size: 20, color: statusColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task['taskTitle'] ?? "Untitled",
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    task['description'] ?? "No description",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            _statusBadge(status, statusColor),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 9,
        ),
      ),
    );
  }
}
