import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../provider/activity_provider.dart';
import '../../provider/theme_provider.dart';
import '../../widget/app_dropdown.dart';
import '../home/activity_task_detail.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({Key? key}) : super(key: key);

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActivityProvider>().initActivities();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'task_created':
      case 'subtask_created':
        return Icons.add_circle_outline;
      case 'status_change':
        return Icons.check_circle_outline;
      case 'remark':
        return Icons.chat_bubble_outline;
      default:
        return Icons.access_time;
    }
  }

  Color _getActivityIconColor(String type) {
    switch (type) {
      case 'task_created':
        return Colors.redAccent;
      case 'subtask_created':
        return Colors.green;
      case 'status_change':
        return Colors.redAccent;
      case 'remark':
        return Colors.blueAccent;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime? time) {
    if (time == null) return 'N/A';
    return DateFormat('MMM d, y, hh:mm a').format(time);
  }

  String _safeInitials(String? firstName, String? lastName) {
    final first = (firstName ?? '').trim();
    final last = (lastName ?? '').trim();
    final firstInitial = first.isNotEmpty ? first[0] : '';
    final lastInitial = last.isNotEmpty ? last[0] : '';
    final initials = '$firstInitial$lastInitial';
    return initials.isNotEmpty ? initials.toUpperCase() : '?';
  }

  String _safeDisplayName(String? firstName, String? lastName) {
    final first = (firstName ?? '').trim();
    final last = (lastName ?? '').trim();
    final fullName = [first, last].where((part) => part.isNotEmpty).join(' ');
    return fullName.isNotEmpty ? fullName : 'Unknown User';
  }

  Widget _buildErrorBanner(String message, Color primary) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF991B1B),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: () {
              context.read<ActivityProvider>().fetchActivities(
                skipLoadingChange: false,
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: primary,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Retry',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message, Color primary) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              "Couldn't Load Activities",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<ActivityProvider>().fetchActivities(
                  skipLoadingChange: false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = ThemeProvider.primaryBlue;

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
                "ACTIVITIES",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1.2,
                ),
              ),
              background: Container(color: primary),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: () {
                  context.read<ActivityProvider>().fetchActivities(
                    skipLoadingChange: false,
                  );
                },
              ),
            ],
          ),
        ],
        body: Consumer<ActivityProvider>(
          builder: (context, provider, child) {
            final stats = provider.userStats.take(5).toList();
            final filteredList = provider.filteredActivities;

            return Column(
              children: [
                // Filters Section
                Container(
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
                        // Date Range
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 4.0, bottom: 6),
                              child: Text(
                                "DATE RANGE",
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF94A3B8),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 140,
                              child: AppDropdown<String>(
                                isCompact: true,
                                value: provider.dateRange,
                                items: const [
                                  'This Month',
                                  'Today',
                                  'This Week',
                                  'All Time',
                                ],
                                labelBuilder: (val) => val,
                                accentColor: primary,
                                onChanged: (val) {
                                  if (val != null) provider.setDateRange(val);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),

                        // Updated By
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 4.0, bottom: 6),
                              child: Text(
                                "UPDATED BY",
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF94A3B8),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 160,
                              child: AppDropdown<dynamic>(
                                isCompact: true,
                                value: provider.updatedBy ?? 'Updated By',
                                items: [
                                  'Updated By',
                                  ...provider.usersList.map((u) => u.id),
                                ],
                                labelBuilder: (val) {
                                  if (val == 'Updated By') return 'All Users';
                                  final user = provider.usersList.firstWhere(
                                    (u) => (u.id == val),
                                    orElse: () => null as dynamic,
                                  );
                                  return user != null
                                      ? '${user.firstName} ${user.lastName}'
                                      : val.toString();
                                },
                                accentColor: primary,
                                onChanged: (val) {
                                  provider.setUpdatedBy(
                                    val == 'Updated By' ? null : val,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),

                        // Search
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 4.0, bottom: 6),
                              child: Text(
                                "SEARCH",
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF94A3B8),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Container(
                              width: 150,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.grey.withOpacity(0.25),
                                ),
                              ),
                              child: TextField(
                                controller: _searchController,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'Search...',
                                  hintStyle: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.normal,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    size: 18,
                                    color: Colors.grey,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 11,
                                  ),
                                ),
                                onChanged: (val) =>
                                    provider.setSearchQuery(val),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                if (provider.errorMessage != null &&
                    provider.activities.isNotEmpty)
                  _buildErrorBanner(provider.errorMessage!, primary),

                // Stats Row
                if (stats.isNotEmpty)
                  Container(
                    height: 90,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: stats.length,
                      itemBuilder: (context, index) {
                        final item = stats[index];
                        final user = item['user'];
                        final count = item['count'];
                        final initials =
                            '${user.firstName.isNotEmpty ? user.firstName[0] : ""}${user.lastName.isNotEmpty ? user.lastName[0] : ""}';

                        return Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: index % 2 == 0
                                    ? const Color(0xFF3B82F6).withOpacity(0.1)
                                    : const Color(0xFFEF4444).withOpacity(0.1),
                                child: Text(
                                  initials,
                                  style: TextStyle(
                                    color: index % 2 == 0
                                        ? const Color(0xFF3B82F6)
                                        : const Color(0xFFEF4444),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$count',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  Text(
                                    user.firstName.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                // Activities List
                Expanded(
                  child: provider.isLoading && provider.activities.isEmpty
                      ? Center(child: CircularProgressIndicator(color: primary))
                      : provider.errorMessage != null &&
                            provider.activities.isEmpty
                      ? _buildErrorState(provider.errorMessage!, primary)
                      : filteredList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history_rounded,
                                size: 48,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "No Activities Found",
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const Text(
                                "Try adjusting your filters",
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) {
                            final act = filteredList[index];
                            final uInitials = _safeInitials(
                              act.user?.firstName,
                              act.user?.lastName,
                            );
                            final userName = _safeDisplayName(
                              act.user?.firstName,
                              act.user?.lastName,
                            );

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: act.relatedId != null
                                    ? () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                ActivityTaskDetailScreen(
                                                  task: {'id': act.relatedId},
                                                  allowEdit: true,
                                                ),
                                          ),
                                        );
                                      }
                                    : null,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      // Icon
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: _getActivityIconColor(
                                            act.type,
                                          ).withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          _getActivityIcon(act.type),
                                          color: _getActivityIconColor(
                                            act.type,
                                          ),
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 16),

                                      // Title & Desc
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              act.title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 13,
                                                color: Color(0xFF1E293B),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              act.description,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF64748B),
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(width: 12),

                                      // User Avatar & Time
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 10,
                                                backgroundColor: primary
                                                    .withOpacity(0.2),
                                                child: Text(
                                                  uInitials,
                                                  style: TextStyle(
                                                    fontSize: 8,
                                                    color: primary,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                userName,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w900,
                                                  color: Color(0xFF1E293B),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            _formatDate(act.createdAt),
                                            style: const TextStyle(
                                              fontSize: 9,
                                              color: Color(0xFF94A3B8),
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          if (act.relatedId != null)
                                            const Padding(
                                              padding: EdgeInsets.only(top: 4),
                                              child: Icon(
                                                Icons.arrow_forward_ios_rounded,
                                                size: 10,
                                                color: Color(0xFFCBD5E1),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
