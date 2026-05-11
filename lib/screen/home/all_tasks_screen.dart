import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../model/delegate_model.dart';
import '../../model/user_model.dart';
import '../../provider/auth_provider.dart';
import '../../provider/delegation_provider.dart';
import '../../provider/theme_provider.dart';
import '../../provider/user_provider.dart';
import '../../provider/category_provider.dart';
import '../../provider/tag_provider.dart';
import '../../widget/app_dropdown.dart';
import '../../widget/assign_task_sheet.dart';
import '../../widget/custom_date_range_picker.dart';
import 'task_detail.dart';

class AllTasksScreen extends StatefulWidget {
  final String title;
  final Color themeColor;

  const AllTasksScreen({
    super.key,
    required this.title,
    this.themeColor = const Color(0xFF003366),
  });

  @override
  State<AllTasksScreen> createState() => _AllTasksScreenState();
}

class _AllTasksScreenState extends State<AllTasksScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController searchController = TextEditingController();

  String searchQuery = "";
  String selectedDateRange = "All Time";
  String selectedSortBy = "Target Date";
  bool parentTasksOnly = false;
  int _viewMode = 0; // 0=list, 1=grid, 2=calendar
  String _activeStatusTab = "All";

  // Filter states
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  String _assignedByFilter = "Anyone";
  String _assignedToFilter = "Anyone";
  String _priorityFilter = "All Priority";
  String _categoryFilter = "All Categories";
  String _tagFilter = "All Tags";

  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      setState(() {
        searchQuery = searchController.text.toLowerCase();
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Provider.of<DelegationProvider>(context, listen: false).fetchAll();
      Provider.of<UserProvider>(context, listen: false).fetchUsers();
      Provider.of<CategoryProvider>(context, listen: false).fetchCategories();
      Provider.of<TagProvider>(context, listen: false).fetchTags();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  DateTime? _parseTaskDate(DelegationModel task) {
    final rawDate = task.dueDate.isNotEmpty ? task.dueDate : task.createdAt;
    if (rawDate.isEmpty) return null;
    return DateTime.tryParse(rawDate);
  }

  bool _matchesDateRange(DateTime? taskDate) {
    if (selectedDateRange == "All Time") return true;
    if (taskDate == null) return false;

    final date = DateTime(taskDate.year, taskDate.month, taskDate.day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (selectedDateRange) {
      case "Today":
        return !date.isBefore(today);
      case "Yesterday":
        final yesterday = today.subtract(const Duration(days: 1));
        return !date.isBefore(yesterday) && date.isBefore(today);
      case "This Week":
        final start = DateTime(
          today.year,
          today.month,
          today.day,
        ).subtract(Duration(days: today.weekday == 7 ? 6 : today.weekday - 1));
        return !date.isBefore(start);
      case "Last Week":
        final start = DateTime(
          today.year,
          today.month,
          today.day,
        ).subtract(Duration(days: today.weekday == 7 ? 13 : today.weekday + 6));
        final end = start.add(const Duration(days: 6));
        return !date.isBefore(start) && !date.isAfter(end);
      case "This Month":
        return !date.isBefore(DateTime(now.year, now.month, 1));
      case "Last Month":
        final start = DateTime(now.year, now.month - 1, 1);
        final end = DateTime(now.year, now.month, 0);
        return !date.isBefore(start) && !date.isAfter(end);
      case "This Year":
        return !date.isBefore(DateTime(now.year, 1, 1));
      case "Custom":
        if (_customStartDate == null || _customEndDate == null) return true;
        final start = DateTime(
          _customStartDate!.year,
          _customStartDate!.month,
          _customStartDate!.day,
        );
        final end = DateTime(
          _customEndDate!.year,
          _customEndDate!.month,
          _customEndDate!.day,
          23,
          59,
          59,
        );
        return !date.isBefore(start) && !date.isAfter(end);
      default:
        return true;
    }
  }

  List<String> _availableTags(List<DelegationModel> tasks) {
    final tags = <String>{};
    for (final task in tasks) {
      for (final tag in task.tagsList) {
        final normalized = tag.trim();
        if (normalized.isNotEmpty) tags.add(normalized);
      }
    }
    final sorted = tags.toList()..sort();
    return sorted;
  }

  List<DelegationModel> _visibleTasks(
    List<DelegationModel> all,
    String? myId,
    bool isAdmin,
  ) {
    if (isAdmin) return all;
    return all.where((task) {
      return task.delegatorId == myId ||
          task.assingDoerId == myId ||
          task.inLoopIds.contains(myId);
    }).toList();
  }

  List<DelegationModel> _applyFilters(
    List<DelegationModel> all,
    List<UserModel> users,
  ) {
    return all.where((task) {
      bool matchesSearch =
          searchQuery.isEmpty ||
          task.delegationName.toLowerCase().contains(searchQuery) ||
          task.description.toLowerCase().contains(searchQuery);

      bool matchesStatus =
          _activeStatusTab == "All" || task.status == _activeStatusTab;

      // Filter: Assigned By
      bool matchesAssignedBy = true;
      if (_assignedByFilter != "Anyone") {
        final assigner = users.firstWhere(
          (u) => u.id == task.delegatorId,
          orElse: () => UserModel.empty(),
        );
        matchesAssignedBy = assigner.fullName == _assignedByFilter;
      }

      // Filter: Assigned To
      bool matchesAssignedTo = true;
      if (_assignedToFilter != "Anyone") {
        final assignee = users.firstWhere(
          (u) => u.id == task.assingDoerId,
          orElse: () => UserModel.empty(),
        );
        matchesAssignedTo = assignee.fullName == _assignedToFilter;
      }

      // Filter: Priority
      bool matchesPriority = true;
      if (_priorityFilter != "All Priority") {
        matchesPriority = task.priority == _priorityFilter;
      }

      // Filter: Category
      bool matchesCategory = true;
      if (_categoryFilter != "All Categories") {
        matchesCategory = task.category == _categoryFilter;
      }

      // Filter: Tags
      bool matchesTags = true;
      if (_tagFilter != "All Tags") {
        matchesTags = task.tagsList.contains(_tagFilter);
      }

      final matchesDate = _matchesDateRange(_parseTaskDate(task));

      return matchesSearch &&
          matchesStatus &&
          matchesDate &&
          matchesAssignedBy &&
          matchesAssignedTo &&
          matchesPriority &&
          matchesCategory &&
          matchesTags;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final delegationProv = Provider.of<DelegationProvider>(context);
    final userProv = Provider.of<UserProvider>(context);
    final appColors = Theme.of(context).extension<AppColors>()!;
    final primary = ThemeProvider.primaryBlue;

    final myId = auth.currentUser?.id;
    final bool isAdmin = auth.isAdmin;
    final visibleTasks = _visibleTasks(
      delegationProv.delegations,
      myId,
      isAdmin,
    );
    final filtered = _applyFilters(visibleTasks, userProv.users);

    // Status counts — All tasks
    final myTasks = visibleTasks;

    int overdueCount = myTasks.where((t) => t.status == "Overdue").length;
    int pendingCount = myTasks.where((t) => t.status == "Pending").length;
    int inProgressCount = myTasks
        .where((t) => t.status == "In Progress")
        .length;
    int completedCount = myTasks.where((t) => t.status == "Completed").length;
    int allCount = myTasks.length;

    final counts = {
      "All": allCount,
      "Overdue": overdueCount,
      "Pending": pendingCount,
      "In Progress": inProgressCount,
      "Completed": completedCount,
    };

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
              title: Text(
                widget.title.toUpperCase(),
                style: const TextStyle(
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
            Expanded(
              child: RefreshIndicator(
                color: primary,
                onRefresh: () async {
                  await context.read<DelegationProvider>().fetchAll();
                  await context.read<UserProvider>().fetchUsers();
                  await context.read<CategoryProvider>().fetchCategories();
                  await context.read<TagProvider>().fetchTags();
                },
                child: ListView(
                  padding: const EdgeInsets.only(top: 0),
                  children: [
                    _buildHeader(primary),
                    _buildQuickStats(counts),
                    _buildToolbar(appColors, primary),
                    _buildStatusTabs(appColors, primary, counts),

                    // ── Task List / Empty ────────────────────────────────────
                    delegationProv.isLoading
                        ? Center(
                            child: CircularProgressIndicator(color: primary),
                          )
                        : filtered.isEmpty
                        ? _buildEmptyState(appColors)
                        : ListView.builder(
                            padding: const EdgeInsets.only(
                              top: 12,
                              bottom: 80,
                              left: 0,
                              right: 0,
                            ),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filtered.length,
                            itemBuilder: (ctx, i) => _buildTaskCard(
                              filtered[i],
                              userProv.users,
                              auth.currentUser?.id,
                              appColors,
                              primary,
                            ),
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

  // ─────────────────────────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(Color primary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: primary.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.grid_view_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "All Tasks",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "Every task across all users",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            height: 40,
            child: ElevatedButton(
              onPressed: () => _showAssignBottomSheet(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Icon(Icons.add_rounded, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(Map<String, int> counts) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildStatCard("TOTAL", counts['All'] ?? 0, Colors.blueGrey),
          const SizedBox(width: 12),
          _buildStatCard("OVERDUE", counts['Overdue'] ?? 0, Colors.red),
          const SizedBox(width: 12),
          _buildStatCard("PENDING", counts['Pending'] ?? 0, Colors.orange),
          const SizedBox(width: 12),
          _buildStatCard(
            "IN PROGRESS",
            counts['In Progress'] ?? 0,
            Colors.blue,
          ),
          const SizedBox(width: 12),
          _buildStatCard("COMPLETED", counts['Completed'] ?? 0, Colors.green),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int value, Color color) {
    return Container(
      width: 140, // Fixed width for horizontal scrolling
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border(bottom: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E1E1E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(AppColors appColors, Color primary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 150,
                height: 40,
                child: AppDropdown<String>(
                  isCompact: true,
                  value: selectedDateRange,
                  items: const [
                    "All Time",
                    "Today",
                    "Yesterday",
                    "This Week",
                    "Last Week",
                    "This Month",
                    "Last Month",
                    "This Year",
                    "Custom",
                  ],
                  labelBuilder: (v) => v,
                  accentColor: primary,
                  onChanged: (v) async {
                    if (v == "Custom") {
                      final picked = await showStylishDateRangePicker(
                        context,
                        primary,
                      );
                      if (picked != null) {
                        setState(() {
                          _customStartDate = picked.start;
                          _customEndDate = picked.end;
                          selectedDateRange = "Custom";
                        });
                      }
                    } else {
                      setState(() {
                        selectedDateRange = v!;
                        _customStartDate = null;
                        _customEndDate = null;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 40,
                child: ElevatedButton.icon(
                  onPressed: () => _showFilterDialog(appColors, primary),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  icon: const Icon(
                    Icons.filter_alt_outlined,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: const Text(
                    "Filter",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 200,
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      color: Colors.grey.shade500,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: const InputDecoration(
                          hintText: "Search tasks...",
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 40,
                height: 40,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      searchController.clear();
                      searchQuery = "";
                      selectedDateRange = "All Time";
                      _activeStatusTab = "All";
                      _customStartDate = null;
                      _customEndDate = null;
                      _assignedByFilter = "Anyone";
                      _assignedToFilter = "Anyone";
                      _priorityFilter = "All Priority";
                      _categoryFilter = "All Categories";
                      _tagFilter = "All Tags";
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Icon(Icons.refresh_rounded, size: 18),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 40,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _viewToggleBtn(Icons.view_list_rounded, 0, primary),
                    _viewToggleBtn(Icons.view_module_rounded, 1, primary),
                    _viewToggleBtn(Icons.calendar_month_rounded, 2, primary),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 40,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Task export is not available in the current backend yet.',
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  icon: const Icon(
                    Icons.file_upload_outlined,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: const Text(
                    "Export",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _viewToggleBtn(IconData icon, int index, Color primary) {
    bool active = _viewMode == index;
    return GestureDetector(
      onTap: () => setState(() => _viewMode = index),
      child: Container(
        width: 32,
        height: 34,
        decoration: BoxDecoration(
          color: active ? primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: active ? Colors.white : Colors.grey, size: 16),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // STATUS TABS (like screenshot)
  // ─────────────────────────────────────────────────────────────────
  Widget _buildStatusTabs(
    AppColors appColors,
    Color primary,
    Map<String, int> counts,
  ) {
    final tabs = [
      {"key": "All", "color": Colors.grey.shade500},
      {"key": "Overdue", "color": Colors.redAccent},
      {"key": "Pending", "color": Colors.grey.shade400},
      {"key": "In Progress", "color": Colors.orangeAccent},
      {"key": "Completed", "color": const Color(0xFF003366)},
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: tabs.map((tab) {
              final key = tab["key"] as String;
              final color = tab["color"] as Color;
              final isActive = _activeStatusTab == key;
              final count = counts[key] ?? 0;
              final isPending = key == 'Pending';

              return GestureDetector(
                onTap: () => setState(() => _activeStatusTab = key),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isActive
                            ? const Color(0xFF003366)
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isPending ? Colors.transparent : color,
                          border: isPending
                              ? Border.all(
                                  color: Colors.grey.shade400,
                                  width: 2,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "${key.toUpperCase()} — $count",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: isActive
                              ? Colors.blueGrey.shade700
                              : Colors.blueGrey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // TASK CARD
  // ─────────────────────────────────────────────────────────────────
  Widget _buildTaskCard(
    DelegationModel task,
    List<UserModel> users,
    String? myId,
    AppColors appColors,
    Color primary,
  ) {
    final Color statusColor = _getStatusColor(task.status);

    // helper variables
    String toName = task.getAssignedToName(users);
    String byName = task.getAssignedByName(users);
    String initials = "U";
    if (toName.trim().isNotEmpty) {
      final parts = toName.trim().split(RegExp(r'\s+'));
      if (parts.length > 1 && parts[1].isNotEmpty) {
        initials = "${parts[0][0]}${parts[1][0]}".toUpperCase();
      } else {
        initials = parts[0][0].toUpperCase();
      }
    }

    String timeAgo = _formatTimeAgo(task.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 20, right: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TaskDetailScreen(task: task, allowEdit: true),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: Checkbox + Avatar + Title ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: primary,
                border: Border(bottom: BorderSide(color: primary)),
              ),
              child: Row(
                children: [
                  // Checkbox mock
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.delegationName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          "By $byName — To $toName",
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.more_vert_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
            // ── Bottom row: Status + Date + Priority + Time ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  _statusBadge(task.status, statusColor),
                  if (task.dueDate.isNotEmpty) _dateTag(task.dueDate),
                  _priorityTag(task.priority),
                  if (timeAgo.isNotEmpty)
                    Text(
                      timeAgo,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(String dateStr) {
    try {
      DateTime date = DateTime.parse(dateStr);
      Duration diff = DateTime.now().difference(date);
      if (diff.inHours < 1) return "Just now";
      if (diff.inHours < 24) return "${diff.inHours}h ago";
      return "${diff.inDays}d ago";
    } catch (_) {
      return "";
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // EMPTY STATE (matches screenshot style)
  // ─────────────────────────────────────────────────────────────────
  Widget _buildEmptyState(AppColors appColors) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Illustration placeholder
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: appColors.inputBackground,
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 56,
                      color: appColors.cardBorder,
                    ),
                    Positioned(
                      right: 20,
                      bottom: 20,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "No Tasks Here",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: appColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "It seems that you don't have any tasks in this list",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: appColors.textMuted,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAssignBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AssignTaskSheet(),
    ).then((_) {
      // Refresh after closing
      Provider.of<DelegationProvider>(context, listen: false).fetchAll();
    });
  }

  Widget _statusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 9,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _priorityTag(String priority) {
    final color = _getPriorityColor(priority);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          priority,
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _dateTag(String date) {
    String display = date;
    try {
      if (date.length >= 10) {
        DateTime d = DateTime.parse(date);
        final months = [
          "Jan",
          "Feb",
          "Mar",
          "Apr",
          "May",
          "Jun",
          "Jul",
          "Aug",
          "Sep",
          "Oct",
          "Nov",
          "Dec",
        ];
        display = "${d.day} ${months[d.month - 1]}";
      }
    } catch (_) {}

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.calendar_today_rounded, size: 12, color: Colors.grey),
        const SizedBox(width: 4),
        Text(
          display,
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "Pending":
        return Colors.orange;
      case "Completed":
        return ThemeProvider.primaryBlue;
      case "Overdue":
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case "High":
        return Colors.red;
      case "Medium":
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  void _showFilterDialog(AppColors appColors, Color primary) {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: appColors.cardBackground,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 24,
              ),
              child: Container(
                width: 320,
                padding: const EdgeInsets.all(24),
                child: Consumer3<UserProvider, CategoryProvider, TagProvider>(
                  builder: (ctx, userProv, catProv, tagProv, _) {
                    final auth = context.read<AuthProvider>();
                    final visibleTasks = _visibleTasks(
                      context.read<DelegationProvider>().delegations,
                      auth.currentUser?.id,
                      auth.isAdmin,
                    );
                    final availableTags = _availableTags(visibleTasks);
                    final users = [
                      "Anyone",
                      ...userProv.users.map((e) => e.fullName),
                    ];
                    final priorities = [
                      "All Priority",
                      "High",
                      "Medium",
                      "Low",
                    ];
                    final categories = [
                      "All Categories",
                      ...catProv.categoryModels.map((e) => e.name),
                    ];
                    final tags = ["All Tags", ...availableTags];

                    return SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "FILTERS",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: appColors.textPrimary,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setDialogState(() {
                                    _assignedByFilter = "Anyone";
                                    _assignedToFilter = "Anyone";
                                    _priorityFilter = "All Priority";
                                    _categoryFilter = "All Categories";
                                    _tagFilter = "All Tags";
                                  });
                                  setState(() {
                                    _assignedByFilter = "Anyone";
                                    _assignedToFilter = "Anyone";
                                    _priorityFilter = "All Priority";
                                    _categoryFilter = "All Categories";
                                    _tagFilter = "All Tags";
                                  });
                                },
                                child: Text(
                                  "Clear All",
                                  style: TextStyle(
                                    color: primary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // ASSIGNED BY
                          _buildFilterDropdownLabel("ASSIGNED BY", appColors),
                          _buildFilterDropdown(
                            value: _assignedByFilter,
                            items: users,
                            appColors: appColors,
                            onChanged: (val) {
                              setDialogState(() => _assignedByFilter = val!);
                              setState(() => _assignedByFilter = val!);
                            },
                          ),
                          const SizedBox(height: 16),

                          // ASSIGNED TO
                          _buildFilterDropdownLabel("ASSIGNED TO", appColors),
                          _buildFilterDropdown(
                            value: _assignedToFilter,
                            items: users,
                            appColors: appColors,
                            onChanged: (val) {
                              setDialogState(() => _assignedToFilter = val!);
                              setState(() => _assignedToFilter = val!);
                            },
                          ),
                          const SizedBox(height: 16),

                          // PRIORITY
                          _buildFilterDropdownLabel("PRIORITY", appColors),
                          _buildFilterDropdown(
                            value: _priorityFilter,
                            items: priorities,
                            appColors: appColors,
                            onChanged: (val) {
                              setDialogState(() => _priorityFilter = val!);
                              setState(() => _priorityFilter = val!);
                            },
                          ),
                          const SizedBox(height: 16),

                          // CATEGORY
                          _buildFilterDropdownLabel("CATEGORY", appColors),
                          _buildFilterDropdown(
                            value: _categoryFilter,
                            items: categories,
                            appColors: appColors,
                            onChanged: (val) {
                              setDialogState(() => _categoryFilter = val!);
                              setState(() => _categoryFilter = val!);
                            },
                          ),
                          const SizedBox(height: 16),

                          // TAG
                          _buildFilterDropdownLabel("TAG", appColors),
                          _buildFilterDropdown(
                            value: _tagFilter,
                            items: tags,
                            appColors: appColors,
                            onChanged: (val) {
                              setDialogState(() => _tagFilter = val!);
                              setState(() => _tagFilter = val!);
                            },
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterDropdownLabel(String label, AppColors appColors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: appColors.textMuted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String value,
    required List<String> items,
    required AppColors appColors,
    required ValueChanged<String?> onChanged,
  }) {
    // Make sure 'value' is actually inside 'items' to prevent assertion errors
    final currentValue = items.contains(value) ? value : items.first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: appColors.inputBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: appColors.cardBorder.withOpacity(0.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: appColors.textPrimary,
          ),
          dropdownColor: appColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
