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

class DelegateTasksScreen extends StatefulWidget {
  const DelegateTasksScreen({super.key});

  @override
  State<DelegateTasksScreen> createState() => _DelegateTasksScreenState();
}

class _DelegateTasksScreenState extends State<DelegateTasksScreen> {
  final Color primaryColor = ThemeProvider.primaryBlue;
  final TextEditingController searchController = TextEditingController();

  String searchQuery = "";
  String selectedDateRange = "All Time";
  int _viewMode = 0; // 0=list, 1=grid, 2=calendar
  String _activeStatusTab = "All";

  // Filter states
  String _assignedToFilter = "All";
  String _priorityFilter = "All";
  String _categoryFilter = "All";
  String _tagFilter = "All";
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  // Custom Slate Colors
  final Color slate50 = Colors.white;
  final Color slate100 = const Color(0xFFF1F5F9);
  final Color slate200 = const Color(0xFFE2E8F0);
  final Color slate400 = const Color(0xFF94A3B8);
  final Color slate600 = const Color(0xFF475569);
  final Color slate800 = const Color(0xFF1E293B);

  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      setState(() => searchQuery = searchController.text.toLowerCase());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final delegationProv = Provider.of<DelegationProvider>(
        context,
        listen: false,
      );
      final userProv = Provider.of<UserProvider>(context, listen: false);
      final catProv = Provider.of<CategoryProvider>(context, listen: false);
      final tagProv = Provider.of<TagProvider>(context, listen: false);

      await delegationProv.fetchAll();
      await userProv.fetchUsers();
      await catProv.fetchCategories();
      await tagProv.fetchTags();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      searchController.clear();
      searchQuery = "";
      selectedDateRange = "All Time";
      _activeStatusTab = "All";
      _assignedToFilter = "All";
      _priorityFilter = "All";
      _categoryFilter = "All";
      _tagFilter = "All";
      _customStartDate = null;
      _customEndDate = null;
    });
  }

  DateTime? _parseTaskDate(DelegationModel task) {
    final rawDate = task.dueDate.isNotEmpty ? task.dueDate : task.createdAt;
    if (rawDate.isEmpty) return null;
    return DateTime.tryParse(rawDate);
  }

  bool _matchesDateRange(DateTime? taskDate) {
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
        );
        return !date.isBefore(start) && !date.isAfter(end);
      case "All Time":
      default:
        return true;
    }
  }

  bool _matchesTagFilter(DelegationModel task) {
    if (_tagFilter == "All") return true;
    return task.tagsList.any((tag) => tag.trim() == _tagFilter);
  }

  List<String> _availableTags(List<DelegationModel> tasks, String? myId) {
    final tags = <String>{};
    for (final task in tasks) {
      if (task.delegatorId != myId) continue;
      for (final tag in task.tagsList) {
        final normalized = tag.trim();
        if (normalized.isNotEmpty) tags.add(normalized);
      }
    }
    final sorted = tags.toList()..sort();
    return sorted;
  }

  Map<String, int> _buildStatusCounts(List<DelegationModel> tasks) {
    return {
      "All": tasks.length,
      "Overdue": tasks.where((t) => t.status == "Overdue").length,
      "Pending": tasks.where((t) => t.status == "Pending").length,
      "In Progress": tasks.where((t) => t.status == "In Progress").length,
      "Completed": tasks.where((t) => t.status == "Completed").length,
    };
  }

  List<DelegationModel> _applyFilters(List<DelegationModel> all, String? myId) {
    return all.where((task) {
      if (task.delegatorId != myId) return false;

      final matchesSearch =
          searchQuery.isEmpty ||
          task.delegationName.toLowerCase().contains(searchQuery);
      final matchesStatus =
          _activeStatusTab == "All" || task.status == _activeStatusTab;
      final matchesAssignedTo =
          _assignedToFilter == "All" || task.assingDoerId == _assignedToFilter;
      final matchesPriority =
          _priorityFilter == "All" || task.priority == _priorityFilter;
      final matchesCategory =
          _categoryFilter == "All" || task.category == _categoryFilter;
      final matchesTags = _matchesTagFilter(task);
      final matchesDate = _matchesDateRange(_parseTaskDate(task));

      return matchesSearch &&
          matchesStatus &&
          matchesAssignedTo &&
          matchesPriority &&
          matchesCategory &&
          matchesTags &&
          matchesDate;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final delegationProv = Provider.of<DelegationProvider>(context);
    final userProv = Provider.of<UserProvider>(context);

    final myId = auth.currentUser?.id;
    final filtered = _applyFilters(delegationProv.delegations, myId);
    final delegatedByMe = delegationProv.delegations
        .where((t) => t.delegatorId == myId)
        .toList();
    final counts = _buildStatusCounts(delegatedByMe);
    final activeFilterCount = [
      _priorityFilter != 'All',
      _categoryFilter != 'All',
      _assignedToFilter != 'All',
      _tagFilter != 'All',
    ].where((item) => item).length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            backgroundColor: primaryColor,
            expandedHeight: 120,
            pinned: true,
            elevation: 0,
            leading: ModalRoute.of(context)?.canPop == true
                ? IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  )
                : null,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: const Text(
                "DELEGATED TASKS",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1.2,
                ),
              ),
              background: Container(color: primaryColor),
            ),
          ),
        ],
        body: RefreshIndicator(
          color: primaryColor,
          onRefresh: () async {
            await delegationProv.fetchAll();
            await userProv.fetchUsers();
            await context.read<CategoryProvider>().fetchCategories();
            await context.read<TagProvider>().fetchTags();
          },
          child: ListView(
            padding: const EdgeInsets.only(top: 0),
            children: [
              _buildHeader(primaryColor),
              _buildQuickStats(counts),
              _buildToolbar(primaryColor, activeFilterCount),
              _buildStatusTabs(counts),
              _buildActiveFilterChips(userProv.users),

              // ── Task List / Empty ────────────────────────────────────
              delegationProv.isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    )
                  : filtered.isEmpty
                  ? _buildEmptyState()
                  : _buildTaskResults(filtered, userProv.users, primaryColor),
            ],
          ),
        ),
      ),
    );
  }

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
              Icons.outbox_rounded,
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
                  "Delegated Tasks",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "Tasks you've assigned to others",
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

  Widget _buildToolbar(Color primary, int activeFilterCount) {
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
                  onPressed: _showFilterDialog,
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
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Filter",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                      if (activeFilterCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 18,
                          height: 18,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            activeFilterCount.toString(),
                            style: TextStyle(
                              color: primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
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
                  onPressed: _clearFilters,
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

  Widget _buildStatusTabs(Map<String, int> counts) {
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
                        color: isActive ? primaryColor : Colors.transparent,
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

  Widget _buildActiveFilterChips(List<UserModel> users) {
    final chips = <Widget>[];

    if (_priorityFilter != 'All') {
      chips.add(
        _buildFilterChip('Priority: $_priorityFilter', () {
          setState(() => _priorityFilter = 'All');
        }),
      );
    }
    if (_categoryFilter != 'All') {
      chips.add(
        _buildFilterChip('Category: $_categoryFilter', () {
          setState(() => _categoryFilter = 'All');
        }),
      );
    }
    if (_assignedToFilter != 'All') {
      final selectedUser = users.firstWhere(
        (u) => u.id == _assignedToFilter,
        orElse: UserModel.empty,
      );
      final name = selectedUser.fullName.trim().isNotEmpty
          ? selectedUser.fullName
          : _assignedToFilter;
      chips.add(
        _buildFilterChip('Assigned To: $name', () {
          setState(() => _assignedToFilter = 'All');
        }),
      );
    }
    if (_tagFilter != 'All') {
      chips.add(
        _buildFilterChip('Tag: $_tagFilter', () {
          setState(() => _tagFilter = 'All');
        }),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Wrap(spacing: 8, runSpacing: 8, children: chips),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: primaryColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 14, color: primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskResults(
    List<DelegationModel> tasks,
    List<UserModel> users,
    Color primary,
  ) {
    switch (_viewMode) {
      case 1:
        final crossAxisCount = MediaQuery.of(context).size.width > 900 ? 2 : 1;
        return GridView.builder(
          padding: const EdgeInsets.only(
            top: 12,
            bottom: 80,
            left: 12,
            right: 12,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: crossAxisCount == 1 ? 2.6 : 2.1,
          ),
          itemCount: tasks.length,
          itemBuilder: (ctx, i) => _buildTaskCard(tasks[i], users, primary),
        );
      case 2:
        return _buildCalendarSections(tasks, users, primary);
      case 0:
      default:
        return ListView.builder(
          padding: const EdgeInsets.only(
            top: 12,
            bottom: 80,
            left: 0,
            right: 0,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tasks.length,
          itemBuilder: (ctx, i) => _buildTaskCard(tasks[i], users, primary),
        );
    }
  }

  Widget _buildCalendarSections(
    List<DelegationModel> tasks,
    List<UserModel> users,
    Color primary,
  ) {
    final grouped = <String, List<DelegationModel>>{};
    for (final task in tasks) {
      final date = _parseTaskDate(task);
      final key = date == null
          ? 'No Date'
          : '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(task);
    }

    final keys = grouped.keys.toList()
      ..sort((a, b) {
        if (a == 'No Date') return 1;
        if (b == 'No Date') return -1;
        return a.compareTo(b);
      });

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final key = keys[index];
        final dayTasks = grouped[key] ?? <DelegationModel>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: 4,
                right: 4,
                bottom: 8,
                top: 8,
              ),
              child: Text(
                key,
                style: TextStyle(
                  color: slate800,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            ...dayTasks.map((task) => _buildTaskCard(task, users, primary)),
          ],
        );
      },
    );
  }

  Widget _buildTaskCard(
    DelegationModel task,
    List<UserModel> users,
    Color primary,
  ) {
    final String assignedToName = task.getAssignedToName(users);
    final String initial = assignedToName.isNotEmpty
        ? assignedToName[0].toUpperCase()
        : "U";
    final Color statusColor = _getStatusColor(task.status);
    final String timeAgo = _getTimeAgo(task.createdAt);

    return Container(
      margin: EdgeInsets.only(
        bottom: 8,
        left: _viewMode == 1 ? 0 : 20,
        right: _viewMode == 1 ? 0 : 20,
      ),
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
            // ── Top row: Checkbox + Avatar + Title/To ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: primary,
                border: Border(bottom: BorderSide(color: primary)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: Checkbox(
                      value: false,
                      onChanged: (v) {},
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      side: const BorderSide(color: Colors.white, width: 1.5),
                    ),
                  ),
                  const SizedBox(width: 10),
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.white,
                    child: Text(
                      initial,
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
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
                          "To: $assignedToName",
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

  String _getTimeAgo(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "";
    try {
      final dt = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(dt);
      if (diff.inDays > 0) return "${diff.inDays}d ago";
      if (diff.inHours > 0) return "${diff.inHours}h ago";
      if (diff.inMinutes > 0) return "${diff.inMinutes}m ago";
      return "Just now";
    } catch (_) {
      return "";
    }
  }

  Widget _priorityTag(String priority) {
    final color = _getPriorityColor(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            priority,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateTag(String date) {
    final display = _formatDate(date);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.event_rounded, size: 12, color: Colors.grey),
          const SizedBox(width: 4),
          Text(
            display,
            style: const TextStyle(
              color: Colors.blueGrey,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String date) {
    if (date.isEmpty) return "N/A";
    try {
      final dt = DateTime.parse(date);
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
      return "${dt.day} ${months[dt.month - 1]}";
    } catch (_) {
      return date.split('T')[0];
    }
  }

  void _showFilterDialog() {
    final delegatedTasks = context.read<DelegationProvider>().delegations;
    final currentUserId = context.read<AuthProvider>().currentUser?.id;
    final tagOptions = _availableTags(delegatedTasks, currentUserId);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 24,
              ),
              child: Container(
                width: 320,
                padding: const EdgeInsets.all(24),
                child: Consumer2<UserProvider, CategoryProvider>(
                  builder: (ctx, userProv, catProv, _) {
                    final assignedToItems = [
                      "All",
                      ...userProv.users.map((e) => e.id),
                    ];
                    final assignedToLabels = <String, String>{
                      "All": "All Members",
                      for (final user in userProv.users)
                        user.id: user.fullName.trim(),
                    };
                    final priorities = [
                      "All",
                      "Urgent",
                      "High",
                      "Medium",
                      "Low",
                    ];
                    final categories = [
                      "All",
                      ...catProv.categoryModels.map((e) => e.name),
                    ];
                    final tags = ["All", ...tagOptions];

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "FILTERS",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                                letterSpacing: 1.2,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(ctx);
                                _clearFilters();
                              },
                              child: Text(
                                "Clear All",
                                style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // ASSIGNED TO
                        _buildFilterDropdownLabel("ASSIGNED TO"),
                        _buildFilterDropdown(
                          value: _assignedToFilter,
                          items: assignedToItems,
                          labels: assignedToLabels,
                          onChanged: (val) {
                            setDialogState(() => _assignedToFilter = val!);
                            setState(() => _assignedToFilter = val!);
                          },
                        ),
                        const SizedBox(height: 16),

                        // PRIORITY
                        _buildFilterDropdownLabel("PRIORITY"),
                        _buildFilterDropdown(
                          value: _priorityFilter,
                          items: priorities,
                          onChanged: (val) {
                            setDialogState(() => _priorityFilter = val!);
                            setState(() => _priorityFilter = val!);
                          },
                        ),
                        const SizedBox(height: 16),

                        // CATEGORY
                        _buildFilterDropdownLabel("CATEGORY"),
                        _buildFilterDropdown(
                          value: _categoryFilter,
                          items: categories,
                          onChanged: (val) {
                            setDialogState(() => _categoryFilter = val!);
                            setState(() => _categoryFilter = val!);
                          },
                        ),
                        const SizedBox(height: 16),

                        // TAG
                        _buildFilterDropdownLabel("TAG"),
                        _buildFilterDropdown(
                          value: _tagFilter,
                          items: tags,
                          onChanged: (val) {
                            setDialogState(() => _tagFilter = val!);
                            setState(() => _tagFilter = val!);
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
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

  Widget _buildFilterDropdownLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Colors.grey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    Map<String, String>? labels,
  }) {
    final currentValue = items.contains(value) ? value : items.first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                labels?[item] ?? item,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
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

  Color _getStatusColor(String status) {
    switch (status) {
      case "Pending":
        return Colors.orange;
      case "Completed":
        return primaryColor;
      case "Overdue":
        return Colors.red;
      case "In Progress":
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case "Urgent":
        return Colors.red;
      case "High":
        return Colors.orange;
      case "Medium":
        return Colors.blue;
      case "Low":
      default:
        return Colors.green;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.outbox_rounded,
                    size: 56,
                    color: Colors.grey,
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
            const Text(
              "No Delegated Tasks",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "You haven't assigned any tasks to others yet",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.5),
            ),
          ],
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
    ).then(
      (_) => Provider.of<DelegationProvider>(context, listen: false).fetchAll(),
    );
  }
}
