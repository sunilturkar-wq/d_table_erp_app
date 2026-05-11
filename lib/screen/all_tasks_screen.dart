import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../model/delegate_model.dart';
import '../provider/delegation_provider.dart';
import '../provider/auth_provider.dart';
import '../provider/category_provider.dart';
import '../provider/theme_provider.dart';
import '../widget/assign_task_sheet.dart';

class AllTasksScreen extends StatefulWidget {
  const AllTasksScreen({super.key});

  @override
  State<AllTasksScreen> createState() => _AllTasksScreenState();
}

class _AllTasksScreenState extends State<AllTasksScreen> {
  late DelegationProvider delegationProvider;

  // Filters
  String _searchQuery = '';
  String _statusFilter = 'All';
  String _priorityFilter = 'All';
  String _categoryFilter = 'All';

  @override
  void initState() {
    super.initState();
    delegationProvider = Provider.of<DelegationProvider>(
      context,
      listen: false,
    );
    _loadTasks();
  }

  void _loadTasks() {
    delegationProvider.fetchAll();
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = ThemeProvider.primaryBlue;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'All Tasks',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const AssignTaskSheet(),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: primaryBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: Colors.white, size: 18),
                    SizedBox(width: 4),
                    Text(
                      'Add Task',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Consumer2<DelegationProvider, AuthProvider>(
        builder: (context, delegationProv, authProv, _) {
          final tasks = delegationProv.delegations;

          // Calculate stats
          int totalTasks = tasks.length;
          int overdueTasks = tasks.where((t) => t.status == 'Overdue').length;
          int pendingTasks = tasks.where((t) => t.status == 'Pending').length;
          int inProgressTasks = tasks
              .where((t) => t.status == 'In Progress')
              .length;
          int completedTasks = tasks
              .where((t) => t.status == 'Completed')
              .length;

          // Filter tasks
          List<DelegationModel> filteredTasks = tasks.where((task) {
            bool matchesSearch =
                _searchQuery.isEmpty ||
                task.delegationName.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                );

            bool matchesStatus =
                _statusFilter == 'All' || task.status == _statusFilter;
            bool matchesPriority =
                _priorityFilter == 'All' || task.priority == _priorityFilter;
            bool matchesCategory =
                _categoryFilter == 'All' || task.category == _categoryFilter;

            return matchesSearch &&
                matchesStatus &&
                matchesPriority &&
                matchesCategory;
          }).toList();

          if (delegationProv.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Stats
                _buildStatsRow(
                  primaryBlue,
                  totalTasks,
                  overdueTasks,
                  pendingTasks,
                  inProgressTasks,
                  completedTasks,
                ),
                const SizedBox(height: 24),

                // Search and Filters
                _buildSearchAndFilters(primaryBlue),
                const SizedBox(height: 20),

                // Task List
                _buildTaskList(filteredTasks, primaryBlue, authProv),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsRow(
    Color primaryBlue,
    int total,
    int overdue,
    int pending,
    int inProgress,
    int completed,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _statCard('Total', total.toString(), Colors.grey[400]!, Colors.white),
          const SizedBox(width: 12),
          _statCard(
            'Overdue',
            overdue.toString(),
            const Color(0xFFEF4444),
            const Color(0xFFFFEBEE),
          ),
          const SizedBox(width: 12),
          _statCard(
            'Pending',
            pending.toString(),
            Colors.grey[400]!,
            Colors.white,
          ),
          const SizedBox(width: 12),
          _statCard(
            'In Progress',
            inProgress.toString(),
            const Color(0xFFF59E0B),
            const Color(0xFFFFF8E1),
          ),
          const SizedBox(width: 12),
          _statCard(
            'Completed',
            completed.toString(),
            const Color(0xFF003366),
            const Color(0xFFE8F5E9),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color dotColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(Color primaryBlue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bar
        TextField(
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            hintText: 'Search tasks...',
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 16,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterChip(
                'Status: $_statusFilter',
                () => _showStatusFilter(),
                _statusFilter != 'All',
              ),
              const SizedBox(width: 10),
              _filterChip(
                'Priority: $_priorityFilter',
                () => _showPriorityFilter(),
                _priorityFilter != 'All',
              ),
              const SizedBox(width: 10),
              _filterChip(
                'Category: $_categoryFilter',
                () => _showCategoryFilter(),
                _categoryFilter != 'All',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, VoidCallback onTap, bool isActive) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF003366).withOpacity(0.1)
              : Colors.white,
          border: Border.all(
            color: isActive
                ? const Color(0xFF003366)
                : (Colors.grey[300] ?? Colors.grey),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isActive ? const Color(0xFF003366) : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  void _showStatusFilter() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Status',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ..._buildFilterOptions(
                ['All', 'Pending', 'In Progress', 'Completed', 'Overdue'],
                (value) {
                  setState(() => _statusFilter = value);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPriorityFilter() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Priority',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ..._buildFilterOptions(
                ['All', 'Low', 'Medium', 'High', 'Urgent'],
                (value) {
                  setState(() => _priorityFilter = value);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCategoryFilter() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Consumer<CategoryProvider>(
        builder: (_, catProv, __) => SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Category',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('All'),
                  onTap: () {
                    setState(() => _categoryFilter = 'All');
                    Navigator.pop(context);
                  },
                ),
                ...catProv.categories.map((cat) {
                  final categoryName = cat is Map
                      ? cat['name'] ?? 'Unknown'
                      : cat.toString();
                  return ListTile(
                    title: Text(categoryName),
                    onTap: () {
                      setState(() => _categoryFilter = categoryName);
                      Navigator.pop(context);
                    },
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFilterOptions(
    List<String> options,
    Function(String) onSelect,
  ) {
    return options.map((option) {
      return ListTile(title: Text(option), onTap: () => onSelect(option));
    }).toList();
  }

  Widget _buildTaskList(
    List<DelegationModel> tasks,
    Color primaryBlue,
    AuthProvider authProv,
  ) {
    if (tasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.inbox, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'No tasks found',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      itemBuilder: (_, i) => _buildTaskTile(tasks[i], primaryBlue, authProv),
    );
  }

  Widget _buildTaskTile(
    DelegationModel task,
    Color primaryBlue,
    AuthProvider authProv,
  ) {
    final statusColor = _getStatusColor(task.status);
    final priorityColor = _getPriorityColor(task.priority);

    String formattedDate = '';
    if (task.dueDate.isNotEmpty) {
      try {
        formattedDate = DateFormat(
          'dd MMM',
        ).format(DateTime.parse(task.dueDate));
      } catch (_) {
        formattedDate = task.dueDate;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  task.delegationName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  task.status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.person, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'By ${task.delegatorName}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  task.priority,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: priorityColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                formattedDate,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              const SizedBox(width: 16),
              Icon(Icons.timer, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _formatTimeAgo(task.createdAt),
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Pending':
        return Colors.grey;
      case 'In Progress':
        return const Color(0xFFF59E0B);
      case 'Completed':
        return const Color(0xFF003366);
      case 'Overdue':
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String? priority) {
    switch (priority) {
      case 'Low':
        return const Color(0xFF003366);
      case 'Medium':
        return const Color(0xFFF59E0B);
      case 'High':
      case 'Urgent':
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }

  String _formatTimeAgo(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inHours < 1) return 'Just now';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return 'Long ago';
    } catch (_) {
      return '';
    }
  }
}
