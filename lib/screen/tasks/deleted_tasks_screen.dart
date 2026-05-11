import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/delegate_model.dart';
import '../../provider/delegation_provider.dart';
import '../../provider/auth_provider.dart';
import '../../provider/user_provider.dart';
import '../../provider/category_provider.dart';
import '../../provider/tag_provider.dart';
import '../../widget/app_dropdown.dart';
import '../../widget/custom_date_range_picker.dart';
import 'package:intl/intl.dart';
import 'package:d_table_erp_app/provider/theme_provider.dart';

class DeletedTasksScreen extends StatefulWidget {
  const DeletedTasksScreen({Key? key}) : super(key: key);

  @override
  State<DeletedTasksScreen> createState() => _DeletedTasksScreenState();
}

class _DeletedTasksScreenState extends State<DeletedTasksScreen> {
  String _statusFilter = 'All';
  String _searchQuery = '';
  String _dateRange = 'All Time';
  String _sortBy = 'Deleted At';
  bool _sortAscending = false;

  // Added Filters
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  String _assignedByFilter = "Anyone";
  String _priorityFilter = "All Priority";
  String _categoryFilter = "All Categories";
  String _tagFilter = "All Tags";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isAdmin = context.read<AuthProvider>().isAdmin;
      if (isAdmin) {
        context.read<DelegationProvider>().fetchDeleted();
        context.read<UserProvider>().fetchUsers();
        context.read<CategoryProvider>().fetchCategories();
        context.read<TagProvider>().fetchTags();
      }
    });
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'No Date';
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return null;
    try {
      return DateTime.parse(dateStr).toLocal();
    } catch (_) {
      return null;
    }
  }

  String _effectiveStatus(DelegationModel task) {
    final normalizedStatus = DelegationModel.normalizeStatus(task.status);
    if (normalizedStatus == 'Completed') return normalizedStatus;

    final dueDate = _parseDate(task.dueDate);
    if (dueDate == null) return normalizedStatus;

    final today = DateTime.now();
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final todayDay = DateTime(today.year, today.month, today.day);

    if (dueDay.isBefore(todayDay)) {
      return 'Overdue';
    }

    return normalizedStatus;
  }

  DateTime? _deletedReferenceDate(DelegationModel task) {
    return _parseDate(task.deletedAt) ?? _parseDate(task.createdAt);
  }

  bool _matchesDeletedDateRange(DelegationModel task) {
    final referenceDate = _deletedReferenceDate(task);
    if (referenceDate == null) return _dateRange == 'All Time';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDay = DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
    );

    switch (_dateRange) {
      case 'Today':
        return !taskDay.isBefore(today);
      case 'Yesterday':
        final yesterday = today.subtract(const Duration(days: 1));
        return taskDay.isAtSameMomentAs(yesterday);
      case 'This Week':
        final weekdayOffset = today.weekday == DateTime.sunday
            ? 6
            : today.weekday - 1;
        final start = today.subtract(Duration(days: weekdayOffset));
        return !taskDay.isBefore(start);
      case 'Next Week':
        final weekdayOffset = today.weekday == DateTime.sunday
            ? 6
            : today.weekday - 1;
        final nextWeekStart = today
            .subtract(Duration(days: weekdayOffset))
            .add(const Duration(days: 7));
        final nextWeekEnd = nextWeekStart.add(const Duration(days: 6));
        return !taskDay.isBefore(nextWeekStart) &&
            !taskDay.isAfter(nextWeekEnd);
      case 'This Month':
        final monthStart = DateTime(now.year, now.month, 1);
        return !taskDay.isBefore(monthStart);
      case 'Next Month':
        final nextMonthStart = DateTime(now.year, now.month + 1, 1);
        final nextMonthEnd = DateTime(now.year, now.month + 2, 0);
        return !taskDay.isBefore(nextMonthStart) &&
            !taskDay.isAfter(nextMonthEnd);
      case 'Custom':
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
          999,
        );
        return !referenceDate.isBefore(start) && !referenceDate.isAfter(end);
      case 'All Time':
      default:
        return true;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'In Progress':
        return Colors.orange;
      case 'Overdue':
        return Colors.red;
      case 'Pending':
      default:
        return Colors.grey;
    }
  }

  Future<void> _handleRestore(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Task'),
        content: const Text('Restore this item? It will become active again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await context.read<DelegationProvider>().restoreTask(id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Task Restored!',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to restore task.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.read<AuthProvider>().isAdmin;

    if (!isAdmin) {
      return Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: AppBar(
          title: const Text('DELETED TASKS'),
          backgroundColor: Colors.redAccent,
          elevation: 0,
        ),
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.security,
                    size: 40,
                    color: Colors.red.shade300,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'ADMIN Only',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'You need administrator access to\nview the deleted tasks bin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<DelegationProvider>(
        builder: (context, provider, child) {
          final allTasks = provider.deletedDelegations;
          final users = context.watch<UserProvider>().users;
          final countOverdue = allTasks
              .where((t) => _effectiveStatus(t) == 'Overdue')
              .length;
          final countPending = allTasks
              .where((t) => _effectiveStatus(t) == 'Pending')
              .length;
          final countInProgress = allTasks
              .where((t) => _effectiveStatus(t) == 'In Progress')
              .length;
          final countCompleted = allTasks
              .where((t) => _effectiveStatus(t) == 'Completed')
              .length;

          final displayList = allTasks.where((task) {
            final q = _searchQuery.toLowerCase();
            final matchesSearch =
                task.delegationName.toLowerCase().contains(q) ||
                task.description.toLowerCase().contains(q);
            final matchesStatus =
                _statusFilter == 'All' ||
                _effectiveStatus(task) == _statusFilter;

            // Assigned By
            bool matchesAssignedBy = true;
            if (_assignedByFilter != "Anyone") {
              final delegator = task.getAssignedByName(users);
              matchesAssignedBy = delegator == _assignedByFilter;
            }
            // Priority
            bool matchesPriority = true;
            if (_priorityFilter != "All Priority") {
              matchesPriority = task.priority == _priorityFilter;
            }
            // Category
            bool matchesCategory = true;
            if (_categoryFilter != "All Categories") {
              matchesCategory = task.category == _categoryFilter;
            }
            // Tags
            bool matchesTags = true;
            if (_tagFilter != "All Tags") {
              matchesTags = task.tagsList.contains(_tagFilter);
            }

            final matchesDate = _matchesDeletedDateRange(task);

            return matchesSearch &&
                matchesStatus &&
                matchesDate &&
                matchesAssignedBy &&
                matchesPriority &&
                matchesCategory &&
                matchesTags;
          }).toList();

          displayList.sort((a, b) {
            if (_sortBy == 'Title') {
              return _sortAscending
                  ? a.delegationName.compareTo(b.delegationName)
                  : b.delegationName.compareTo(a.delegationName);
            } else if (_sortBy == 'Due Date') {
              final aTime = _parseDate(a.dueDate)?.millisecondsSinceEpoch ?? 0;
              final bTime = _parseDate(b.dueDate)?.millisecondsSinceEpoch ?? 0;
              return _sortAscending
                  ? aTime.compareTo(bTime)
                  : bTime.compareTo(aTime);
            } else if (_sortBy == 'Deleted At') {
              final aTime =
                  _deletedReferenceDate(a)?.millisecondsSinceEpoch ?? 0;
              final bTime =
                  _deletedReferenceDate(b)?.millisecondsSinceEpoch ?? 0;
              return _sortAscending
                  ? aTime.compareTo(bTime)
                  : bTime.compareTo(aTime);
            } else {
              final aTime =
                  _parseDate(a.createdAt)?.millisecondsSinceEpoch ?? 0;
              final bTime =
                  _parseDate(b.createdAt)?.millisecondsSinceEpoch ?? 0;
              return _sortAscending
                  ? aTime.compareTo(bTime)
                  : bTime.compareTo(aTime);
            }
          });

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                backgroundColor: ThemeProvider.primaryBlue,
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
                    "DELETED TASKS",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 1.2,
                    ),
                  ),
                  background: Container(color: ThemeProvider.primaryBlue),
                ),
              ),
            ],
            body: RefreshIndicator(
              color: ThemeProvider.primaryBlue,
              onRefresh: () async =>
                  await context.read<DelegationProvider>().fetchDeleted(),
              child: ListView(
                padding: const EdgeInsets.only(top: 0),
                children: [
                  _buildHeader(ThemeProvider.primaryBlue, context),
                  // 2. FILTERS ROW
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Date Range Using AppDropdown
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DATE RANGE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              height: 40,
                              child: AppDropdown<String>(
                                isCompact: true,
                                value: _dateRange,
                                items: const [
                                  "All Time",
                                  "Today",
                                  "Yesterday",
                                  "This Week",
                                  "Next Week",
                                  "This Month",
                                  "Next Month",
                                  "Custom",
                                ],
                                labelBuilder: (v) => v,
                                accentColor: const Color(0xFFFF3B30),
                                onChanged: (val) async {
                                  if (val == "Custom") {
                                    final picked =
                                        await showStylishDateRangePicker(
                                          context,
                                          const Color(0xFFFF3B30),
                                        );
                                    if (picked != null) {
                                      setState(() {
                                        _customStartDate = picked.start;
                                        _customEndDate = picked.end;
                                        _dateRange = "Custom";
                                      });
                                    }
                                  } else {
                                    setState(() {
                                      _dateRange = val!;
                                      _customStartDate = null;
                                      _customEndDate = null;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),

                        // Filter Button
                        Container(
                          height: 40,
                          margin: const EdgeInsets.only(bottom: 0),
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _showFilterDialog(const Color(0xFFFF3B30)),
                            icon: const Icon(
                              Icons.filter_alt_outlined,
                              size: 18,
                            ),
                            label: const Text(
                              'Filter',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF3B30),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Search
                        Container(
                          height: 40,
                          width: 250,
                          margin: const EdgeInsets.only(bottom: 0),
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search deleted tasks...',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade400,
                                fontWeight: FontWeight.w500,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                size: 18,
                                color: Colors.grey.shade400,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 0,
                                horizontal: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade200,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade200,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.red.shade200,
                                ),
                              ),
                            ),
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Reset Button
                        Container(
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF3B30),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.settings_backup_restore,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _dateRange = 'All Time';
                                _statusFilter = 'All';
                                _customStartDate = null;
                                _customEndDate = null;
                                _assignedByFilter = "Anyone";
                                _priorityFilter = "All Priority";
                                _categoryFilter = "All Categories";
                                _tagFilter = "All Tags";
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Sort By Using AppDropdown
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SORT BY',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              height: 40,
                              child: AppDropdown<String>(
                                isCompact: true,
                                value: _sortBy,
                                items: const [
                                  'Deleted At',
                                  'Due Date',
                                  'Created At',
                                  'Title',
                                ],
                                labelBuilder: (v) => v,
                                accentColor: const Color(0xFFFF3B30),
                                onChanged: (val) {
                                  setState(() {
                                    _sortBy = val!;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),

                        // Sort Order Button
                        Container(
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          child: IconButton(
                            icon: Icon(
                              _sortAscending
                                  ? Icons.arrow_upward
                                  : Icons.swap_vert,
                              size: 20,
                              color: Colors.grey.shade600,
                            ),
                            onPressed: () {
                              setState(() {
                                _sortAscending = !_sortAscending;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3. TABS
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        _buildStatusTab(
                          'All',
                          allTasks.length,
                          Colors.grey.shade500,
                        ),
                        _buildStatusTab(
                          'Overdue',
                          countOverdue,
                          const Color(0xFFFF3B30),
                        ),
                        _buildStatusTab(
                          'Pending',
                          countPending,
                          Colors.grey.shade300,
                        ),
                        _buildStatusTab(
                          'In Progress',
                          countInProgress,
                          Colors.orange,
                        ),
                        _buildStatusTab(
                          'Completed',
                          countCompleted,
                          Colors.green,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),

                  // 4. MAIN CONTENT
                  provider.isLoading && allTasks.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : displayList.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(
                            left: 24,
                            right: 24,
                            top: 16,
                            bottom: 80,
                          ),
                          itemCount: displayList.length,
                          itemBuilder: (context, index) {
                            final task = displayList[index];
                            final assigneeName = task.assigneeName.isNotEmpty
                                ? task.assigneeName
                                : task.getAssignedToName(users);
                            final assignedByName = task.delegatorName.isNotEmpty
                                ? task.delegatorName
                                : task.getAssignedByName(users);
                            final deletedOn = _formatDate(
                              task.deletedAt ?? task.createdAt,
                            );
                            final effectiveStatus = _effectiveStatus(task);
                            final initialsParts = assigneeName
                                .split(' ')
                                .where((part) => part.trim().isNotEmpty)
                                .take(2)
                                .map((part) => part.trim()[0].toUpperCase())
                                .join();
                            final avatarText = initialsParts.isNotEmpty
                                ? initialsParts
                                : 'U';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade100),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF003366,
                                      ).withValues(alpha: 0.25),
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 14,
                                          backgroundColor: Colors.white,
                                          child: Text(
                                            avatarText,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      assigneeName,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14,
                                                        color: Colors.white,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Deleted $deletedOn',
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.redAccent,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 1),
                                              Text(
                                                task.category.isNotEmpty
                                                    ? task.category
                                                          .toUpperCase()
                                                    : 'GENERAL',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black54,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () => _handleRestore(task.id!),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Colors.green.shade400,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.restore,
                                                  size: 14,
                                                  color: Colors.green.shade700,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Restore',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        Colors.green.shade800,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          task.delegationName,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (task.description.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            task.description,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                        const SizedBox(height: 12),
                                        Wrap(
                                          spacing: 10,
                                          runSpacing: 10,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            Text(
                                              'Assigned By $assignedByName',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                            if (task.dueDate.isNotEmpty)
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.access_time,
                                                    size: 14,
                                                    color:
                                                        effectiveStatus ==
                                                            'Overdue'
                                                        ? Colors.red
                                                        : Colors.orange,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    _formatDate(task.dueDate),
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          effectiveStatus ==
                                                              'Overdue'
                                                          ? Colors.red
                                                          : Colors.orange,
                                                    ),
                                                  ),
                                                  if (effectiveStatus ==
                                                      'Overdue')
                                                    const Text(
                                                      ' | Overdue',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(
                                                  effectiveStatus,
                                                ).withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                effectiveStatus.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: _getStatusColor(
                                                    effectiveStatus,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: task.priority == 'Urgent'
                                                    ? Colors.red.withOpacity(
                                                        0.08,
                                                      )
                                                    : Colors.grey.withOpacity(
                                                        0.08,
                                                      ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.flag,
                                                    size: 13,
                                                    color:
                                                        task.priority ==
                                                            'Urgent'
                                                        ? Colors.red
                                                        : Colors.grey,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    task.priority,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (task.deletedByName.isNotEmpty)
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.delete_outline,
                                                    size: 14,
                                                    color: Colors.redAccent,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Deleted by ${task.deletedByName}',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(Color primary, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFF3B30), // Warning color for deleted items
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF3B30).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.delete_outline,
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
                  "Deleted Tasks",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "ADMIN View — Trash Bin",
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
              onPressed: () =>
                  context.read<DelegationProvider>().fetchDeleted(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF3B30),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Icon(Icons.refresh_rounded, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTab(String title, int count, Color bulletColor) {
    bool isSelected = _statusFilter == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          _statusFilter = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFFFF3B30) : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: bulletColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${title.toUpperCase()} — $count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? const Color(0xFF1E293B)
                    : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(24),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1.5,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.delete_outline,
              size: 48,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Trash Is Empty',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No deleted tasks found',
            style: TextStyle(fontSize: 15, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(Color primary) {
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
                child: Consumer3<UserProvider, CategoryProvider, TagProvider>(
                  builder: (ctx, userProv, catProv, tagProv, _) {
                    final usersList = [
                      "Anyone",
                      ...userProv.users.map((e) => e.fullName),
                    ];
                    final priorities = [
                      "All Priority",
                      "Urgent",
                      "High",
                      "Medium",
                      "Low",
                    ];
                    final categories = [
                      "All Categories",
                      ...catProv.categoryModels.map((e) => e.name),
                    ];
                    final tags = [
                      "All Tags",
                      ...tagProv.tags.map((e) => e.name),
                    ];

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                setDialogState(() {
                                  _assignedByFilter = "Anyone";
                                  _priorityFilter = "All Priority";
                                  _categoryFilter = "All Categories";
                                  _tagFilter = "All Tags";
                                });
                                setState(() {
                                  _assignedByFilter = "Anyone";
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
                        _buildFilterDropdownLabel("ASSIGNED BY"),
                        _buildFilterDropdown(
                          value: _assignedByFilter,
                          items: usersList,
                          onChanged: (val) {
                            setDialogState(() => _assignedByFilter = val!);
                            setState(() => _assignedByFilter = val!);
                          },
                        ),
                        const SizedBox(height: 16),
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
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Colors.grey.shade500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final currentValue = items.contains(value) ? value : items.first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
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
              child: Text(item, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
