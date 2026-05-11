import 'package:d_table_erp_app/model/delegate_model.dart';
import 'package:d_table_erp_app/model/user_model.dart';
import 'package:d_table_erp_app/provider/auth_provider.dart';
import 'package:d_table_erp_app/provider/dashboard_provider.dart';
import 'package:d_table_erp_app/provider/delegation_provider.dart';
import 'package:d_table_erp_app/provider/theme_provider.dart';
import 'package:d_table_erp_app/provider/category_provider.dart';
import 'package:d_table_erp_app/provider/tag_provider.dart';
import 'package:d_table_erp_app/provider/user_provider.dart';
import 'package:d_table_erp_app/widget/app_dropdown.dart';
import 'package:d_table_erp_app/widget/custom_search_dropdown.dart';
import 'package:d_table_erp_app/widget/custom_multi_dropdown.dart';
import 'package:d_table_erp_app/widget/custom_simple_dropdown.dart';
import 'package:d_table_erp_app/widget/custom_category_dropdown.dart';
import 'package:d_table_erp_app/screen/notifications/notifications_screen.dart';
import 'package:d_table_erp_app/widget/assign_task_sheet.dart';
import 'package:d_table_erp_app/widget/custom_drawer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../widget/custom_date_range_picker.dart';

class DynamicDashboard extends StatefulWidget {
  const DynamicDashboard({super.key});

  @override
  State<DynamicDashboard> createState() => _DynamicDashboardState();
}

class _DynamicDashboardState extends State<DynamicDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Color primaryColor = ThemeProvider.primaryBlue;
  final TextEditingController _searchController = TextEditingController();
  UserModel? _selectedUser;
  String? _selectedFrequency;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardProvider>(
        context,
        listen: false,
      ).fetchDashboardStats();
      // Users & Categories pre-load kar lo taaki assign sheet khulte hi ready ho
      final userProv = Provider.of<UserProvider>(context, listen: false);
      if (userProv.users.isEmpty) userProv.fetchUsers();
      final catProv = Provider.of<CategoryProvider>(context, listen: false);
      if (catProv.categories.isEmpty) catProv.fetchCategories();
      final tagProv = Provider.of<TagProvider>(context, listen: false);
      if (tagProv.tags.isEmpty) tagProv.fetchTags();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    bool isMobile = width < 800;
    var dashPro = Provider.of<DashboardProvider>(context);
    final appColors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: MyCustomDrawer(),
      floatingActionButton: GestureDetector(
        onTap: () => _showAssignBottomSheet(context),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: primaryColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.4),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_task_rounded, color: Colors.white, size: 26),
              SizedBox(height: 3),
              Text(
                "Assign",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              expandedHeight: 120.0,
              floating: false,
              pinned: true,
              backgroundColor: primaryColor,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: const Text(
                  "DASHBOARD",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 1.5,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        primaryColor,
                        primaryColor.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 15),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.notifications_none,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ];
        },
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Performance Overview",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: appColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildDateFilters(dashPro),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Column(
                  children: [
                    dashPro.isTableView
                        ? _buildSummaryCards(isMobile)
                        : _buildTopDonutCharts(dashPro, isMobile),
                    const SizedBox(height: 25),
                    _buildActionRow(isMobile),
                    const SizedBox(height: 25),
                    _buildViewToggle(dashPro),
                    if (dashPro.isTableView) ...[
                      const SizedBox(height: 25),
                      _buildSubTabs(dashPro),
                    ],
                    const SizedBox(height: 10),
                    dashPro.isTableView
                        ? _buildReportTable(isMobile)
                        : _buildAnalyticsCharts(dashPro, isMobile),
                    const SizedBox(height: 40),
                  ],
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
      useSafeArea: true,
      builder: (_) => const AssignTaskSheet(),
    ).then((_) {
      Provider.of<DelegationProvider>(context, listen: false).fetchAll();
    });
  }

  Widget _buildDateFilters(DashboardProvider provider) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    const List<String> filters = [
      "Today",
      "Yesterday",
      "This Week",
      "Last Week",
      "This Month",
      "Last Month",
      "This Year",
      "All Time",
      "Custom",
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((f) {
          bool active = provider.selectedFilter == f;
          return GestureDetector(
            onTap: () async {
              if (f == 'Custom') {
                final picked = await showStylishDateRangePicker(
                  context,
                  primaryColor,
                  isDark: Theme.of(context).brightness == Brightness.dark,
                );
                if (picked != null)
                  provider.setFilter(
                    f,
                    startDate: picked.start,
                    endDate: picked.end,
                  );
              } else {
                provider.setFilter(f);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: active ? primaryColor : appColors.chipBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: active ? primaryColor : appColors.cardBorder,
                ),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Text(
                f == 'Custom' && active && provider.customStartDate != null
                    ? '${provider.customStartDate!.day}/${provider.customStartDate!.month} - ${provider.customEndDate!.day}/${provider.customEndDate!.month}'
                    : f,
                style: TextStyle(
                  color: active ? Colors.white : appColors.textSecondary,
                  fontSize: 13,
                  fontWeight: active ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryCards(bool isMobile) {
    return Consumer<DashboardProvider>(
      builder: (context, dashPro, _) {
        if (dashPro.isLoading)
          return const SizedBox(
            height: 130,
            child: Center(child: CircularProgressIndicator()),
          );
        final stats = dashPro.taskStats;
        final cards = [
          _statusCard(
            "OVERDUE",
            (stats["overdue"] ?? 0).toString(),
            Colors.redAccent,
            Icons.warning_rounded,
          ),
          _statusCard(
            "PENDING",
            (stats["pending"] ?? 0).toString(),
            Colors.orangeAccent,
            Icons.hourglass_empty_rounded,
          ),
          _statusCard(
            "IN PROGRESS",
            (stats["inProgress"] ?? 0).toString(),
            Colors.blueAccent,
            Icons.sync_rounded,
          ),
          _statusCard(
            "COMPLETED",
            (stats["done"] ?? 0).toString(),
            primaryColor,
            Icons.check_circle_outline_rounded,
          ),
          _statusCard(
            "IN TIME",
            (stats["onTime"] ?? 0).toString(),
            Colors.teal,
            Icons.timer_outlined,
          ),
          _statusCard(
            "DELAYED",
            (stats["delayed"] ?? 0).toString(),
            Colors.deepOrangeAccent,
            Icons.history_rounded,
          ),
        ];
        if (isMobile) {
          return SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: cards.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => SizedBox(width: 150, child: cards[i]),
            ),
          );
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            int crossCount = constraints.maxWidth > 1200
                ? 6
                : (constraints.maxWidth > 800 ? 3 : 2);
            double aspectRatio = constraints.maxWidth > 1200 ? 1.5 : 2.5;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossCount,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: aspectRatio,
              children: cards,
            );
          },
        );
      },
    );
  }

  Widget _statusCard(String title, String count, Color color, IconData icon) {
    final appColors2 = Theme.of(context).extension<AppColors>()!;
    return Container(
      decoration: BoxDecoration(
        color: appColors2.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: appColors2.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          count,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: appColors2.textPrimary,
                          ),
                        ),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: appColors2.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(height: 4, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow(bool isMobile) {
    final appColors3 = Theme.of(context).extension<AppColors>()!;
    var dashPro = Provider.of<DashboardProvider>(context);
    final userProv = Provider.of<UserProvider>(context);
    final tagProv = Provider.of<TagProvider>(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: appColors3.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: appColors3.shadowColor, blurRadius: 10)],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _clearButton(context),
            const SizedBox(width: 12),
            CustomSearchDropdown<UserModel>(
              label: "Assigned To",
              items: userProv.users,
              value: userProv.users
                  .where((u) => u.id == dashPro.selectedUserId)
                  .firstOrNull,
              width: 150,
              labelBuilder: (u) => "${u.firstName} ${u.lastName}",
              onChanged: (val) {
                dashPro.setSelectedUserId(val?.id);
              },
            ),
            const SizedBox(width: 12),
            Consumer<CategoryProvider>(
              builder: (context, catProv, _) {
                final catNames = [
                  "All",
                  ...catProv.categoryModels.map((c) => c.name),
                ];
                return CustomCategoryDropdown(
                  items: catNames,
                  value: dashPro.selectedCategory.isEmpty
                      ? "All"
                      : dashPro.selectedCategory,
                  onChanged: (val) {
                    dashPro.setCategory(val);
                  },
                );
              },
            ),
            const SizedBox(width: 12),
            CustomSimpleDropdown<String>(
              label: "Tag",
              items: ["Tag", "All", ...tagProv.tags.map((e) => e.name)],
              value: dashPro.selectedTag,
              width: 150,
              labelBuilder: (t) => t,
              onChanged: (val) {
                if (val != null) dashPro.setTag(val);
              },
            ),
            const SizedBox(width: 12),
            CustomSimpleDropdown<String>(
              label: "Frequency",
              items: const [
                "Frequency",
                "Daily",
                "Weekly",
                "monthly",
                "Yearly",
                "Periodically",
                "Custom",
                "Once",
              ],
              value: dashPro.selectedFrequency,
              width: 150,
              labelBuilder: (f) => f,
              onChanged: (val) {
                if (val != null) dashPro.setFrequency(val);
              },
            ),
            const SizedBox(width: 12),
            SizedBox(width: 200, child: _searchField(context)),
          ],
        ),
      ),
    );
  }

  Widget _clearButton(BuildContext context) {
    return SizedBox(
      height: 42,
      child: TextButton.icon(
        onPressed: () {
          _searchController.clear();
          setState(() {
            _selectedUser = null;
            _selectedFrequency = null;
          });
          Provider.of<DashboardProvider>(context, listen: false).resetFilters();
        },
        icon: const Icon(
          Icons.filter_alt_off_rounded,
          size: 16,
          color: Color(0xFF616161),
        ),
        label: const Text(
          "Clear",
          style: TextStyle(
            color: Color(0xFF616161),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        style: TextButton.styleFrom(
          backgroundColor: const Color(0xFFE0E5E9),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _searchField(BuildContext context) {
    final appColors4 = Theme.of(context).extension<AppColors>()!;
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withOpacity(0.25)),
      ),
      child: TextField(
        controller: _searchController,
        onSubmitted: (value) => Provider.of<DashboardProvider>(
          context,
          listen: false,
        ).setSearchQuery(value),
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: "Search...",
          hintStyle: TextStyle(color: appColors4.textMuted, fontSize: 13),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 18,
            color: appColors4.textMuted,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildViewToggle(DashboardProvider provider) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).extension<AppColors>()!.inputBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _toggleBtn(
              "Table",
              Icons.table_chart_rounded,
              provider.isTableView,
              () => provider.toggleView(true),
            ),
            _toggleBtn(
              "Bar Chart",
              Icons.bar_chart_rounded,
              !provider.isTableView,
              () => provider.toggleView(false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleBtn(
    String text,
    IconData icon,
    bool active,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: active ? Theme.of(context).cardColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).extension<AppColors>()!.shadowColor,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: active
                  ? primaryColor
                  : Theme.of(context).extension<AppColors>()!.textMuted,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: active
                    ? Theme.of(context).extension<AppColors>()!.textPrimary
                    : Theme.of(context).extension<AppColors>()!.textMuted,
                fontWeight: active ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubTabs(DashboardProvider provider) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final userRole =
        context.read<AuthProvider>().currentUser?.role.toUpperCase() ?? '';
    final canViewEmployeesTab =
        userRole == 'ADMIN' ||
        userRole == 'SUPERADMIN' ||
        userRole == 'MANAGER';

    final List<Map<String, dynamic>> tabs = [
      if (canViewEmployeesTab)
        {"icon": Icons.people_outline, "label": "Employees"},
      {"icon": Icons.folder_open_outlined, "label": "Groups"},
      {"icon": Icons.check_circle_outline, "label": "My Report"},
      {"icon": Icons.share_outlined, "label": "Delegated"},
      {"icon": Icons.calendar_today_outlined, "label": "Daily"},
      {"icon": Icons.calendar_month_outlined, "label": "Monthly"},
      {"icon": Icons.schedule_outlined, "label": "Overdue"},
      {"icon": Icons.local_offer_outlined, "label": "Tags"},
      {"icon": Icons.category_outlined, "label": "Categories"},
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: ac.divider, width: 1.5)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: tabs.map((tab) {
            String label = tab["label"];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: _subTabItem(
                tab["icon"],
                label,
                provider.selectedTab == label,
                onTap: () {
                  provider.setTab(label);
                  // Further Dynamic API calls can be triggered here based on the selected tab
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _subTabItem(
    IconData icon,
    String label,
    bool active, {
    required VoidCallback onTap,
  }) {
    final ac = Theme.of(context).extension<AppColors>()!;
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: active ? primaryColor : ac.textMuted,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: active ? FontWeight.bold : FontWeight.w500,
                    color: active ? primaryColor : ac.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (active)
            Container(
              height: 3,
              width: 100,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReportTable(bool isMobile) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading)
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: CircularProgressIndicator(color: primaryColor),
            ),
          );
        final appColors = Theme.of(context).extension<AppColors>()!;

        String firstColLabel = "Employee Name";
        if (provider.selectedTab == 'Groups')
          firstColLabel = "Group";
        else if (provider.selectedTab == 'My Report' ||
            provider.selectedTab == 'Categories')
          firstColLabel = "Category";
        else if (provider.selectedTab == 'Delegated')
          firstColLabel = "Assigned To";
        else if (provider.selectedTab == 'Daily')
          firstColLabel = "Date";
        else if (provider.selectedTab == 'Monthly')
          firstColLabel = "Month";
        else if (provider.selectedTab == 'Tags')
          firstColLabel = "Tag";

        if (provider.selectedTab == 'Overdue') {
          if (provider.overdueTasks.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(60),
              child: Center(
                child: Text(
                  "No overdue tasks 🎉",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            );
          }
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: provider.overdueTasks.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final task = provider.overdueTasks[index];
              final dueDateStr = task['dueDate'];
              String dueFormat = "N/A";
              String overdueSince = "N/A";
              if (dueDateStr != null) {
                final d = DateTime.tryParse(dueDateStr);
                if (d != null) {
                  final localDue = d.toLocal();
                  final dueDay = DateTime(
                    localDue.year,
                    localDue.month,
                    localDue.day,
                  );
                  dueFormat =
                      "${localDue.day}/${localDue.month}/${localDue.year}";
                  final diff = DateTime.now().difference(dueDay);
                  if (diff.inDays > 0)
                    overdueSince = "${diff.inDays} days ago";
                  else if (diff.inHours > 0)
                    overdueSince = "${diff.inHours}h ago";
                  else
                    overdueSince = "${diff.inMinutes}m ago";
                }
              }
              return _buildOverdueCard(
                task['taskTitle']?.toString() ?? "Untitled",
                dueFormat,
                overdueSince,
                task['status']?.toString() ?? "OVERDUE",
                appColors,
              );
            },
          );
        }

        if (provider.categoryStats.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(60),
            child: Center(
              child: Text(
                "No records found",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: provider.categoryStats.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final cat = provider.categoryStats[index];
            return _buildStatCardItem(
              cat['name'] ?? "Unknown",
              firstColLabel,
              cat['total'].toString(),
              cat['score'].toString(),
              cat['overdue'].toString(),
              cat['pending'].toString(),
              cat['in_progress']?.toString() ?? "0",
              cat['in_time']?.toString() ?? "0",
              cat['delayed']?.toString() ?? "0",
              appColors,
            );
          },
        );
      },
    );
  }

  Widget _buildStatCardItem(
    String title,
    String typeLabel,
    String total,
    String score,
    String overdue,
    String pending,
    String inProgress,
    String inTime,
    String delayed,
    AppColors appColors,
  ) {
    Color scoreColor = score.contains("100")
        ? Colors.green
        : (score == "0%" ? Colors.red : Colors.orange);

    return Container(
      decoration: BoxDecoration(
        color: appColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: appColors.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: appColors.cardBorder ?? Colors.transparent),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1B2A).withValues(alpha: 0.55),
            ),
            child: Row(
              children: [
                _circularIndicator(score, scoreColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        typeLabel,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    "Total: $total",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statusValueCard(
                      "Overdue",
                      overdue,
                      Colors.red,
                      total,
                      appColors,
                    ),
                    _statusValueCard(
                      "Pending",
                      pending,
                      Colors.orange,
                      total,
                      appColors,
                    ),
                    _statusValueCard(
                      "In-Progress",
                      inProgress,
                      Colors.blue,
                      total,
                      appColors,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _statusValueCard(
                      "In Time",
                      inTime,
                      Colors.teal,
                      total,
                      appColors,
                    ),
                    _statusValueCard(
                      "Delayed",
                      delayed,
                      Colors.deepOrange,
                      total,
                      appColors,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusValueCard(
    String label,
    String val,
    Color color,
    String total,
    AppColors appColors,
  ) {
    int v = int.tryParse(val) ?? 0;
    int t = int.tryParse(total) ?? 1;
    int perc = ((v / (t == 0 ? 1 : t)) * 100).toInt();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          val,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: appColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          "($perc%)",
          style: TextStyle(
            color: color.withValues(alpha: 0.8),
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildOverdueCard(
    String title,
    String due,
    String overdueSince,
    String status,
    AppColors appColors,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: appColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: appColors.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: const Border(
          left: BorderSide(color: Colors.redAccent, width: 4),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1B2A).withValues(alpha: 0.55),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.event, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  "Due: $due",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 14,
                  color: Colors.redAccent,
                ),
                const SizedBox(width: 4),
                Text(
                  overdueSince,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circularIndicator(String label, Color color) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.2), width: 2),
      ),
      child: Center(
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.05),
          ),
          child: Center(
            child: Text(
              label.replaceAll("%", ""),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopDonutCharts(DashboardProvider dashPro, bool isMobile) {
    if (dashPro.isLoading)
      return const SizedBox(
        height: 130,
        child: Center(child: CircularProgressIndicator()),
      );
    final stats = dashPro.taskStats;

    // 1. OVERDUE, PENDING & IN-PROGRESS
    int overdue = stats["overdue"] ?? 0;
    int pending = stats["pending"] ?? 0;
    int inProgress = stats["inProgress"] ?? 0;
    int total1 = overdue + pending + inProgress;

    // 2. COMPLETED & NOT COMPLETED
    int completed = stats["done"] ?? 0;
    int notCompleted = (stats["total"] ?? 0) - completed;
    if (notCompleted < 0) notCompleted = 0;
    int total2 = completed + notCompleted;

    // 3. IN-TIME & DELAYED
    int onTime = stats["onTime"] ?? 0;
    int delayed = stats["delayed"] ?? 0;
    int total3 = onTime + delayed;

    final widgets = [
      _chartCardSmall("Overdue, Pending & In-Progress", total1, [
        _chartSection(overdue, Colors.redAccent, "Overdue"),
        _chartSection(pending, Colors.orangeAccent, "Pending"),
        _chartSection(inProgress, Colors.blueAccent, "In Progress"),
      ]),
      _chartCardSmall("Completed & Not Completed", total2, [
        _chartSection(completed, primaryColor, "Completed"),
        _chartSection(
          notCompleted,
          Colors.grey.withOpacity(0.3),
          "Not Completed",
        ),
      ]),
      _chartCardSmall("In-Time & Delayed", total3, [
        _chartSection(onTime, Colors.teal, "In-Time"),
        _chartSection(delayed, Colors.deepOrangeAccent, "Delayed"),
      ]),
    ];

    if (isMobile) {
      return SizedBox(
        height: 150,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: widgets.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) => SizedBox(width: 280, child: widgets[i]),
        ),
      );
    }

    return Row(
      children: widgets
          .map(
            (w) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: w,
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _chartCardSmall(
    String title,
    int total,
    List<PieChartSectionData> sections,
  ) {
    final ac = Theme.of(context).extension<AppColors>()!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ac.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: ac.shadowColor, blurRadius: 10)],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 1,
                    centerSpaceRadius: 25,
                    sections: sections,
                  ),
                ),
                Center(
                  child: Text(
                    "$total",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: ac.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 6),
                ...sections.map((s) {
                  double perc = total > 0 ? (s.value / total) * 100 : 0;
                  return Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: s.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          "${perc.toStringAsFixed(0)}%",
                          style: const TextStyle(fontSize: 9),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCharts(DashboardProvider dashPro, bool isMobile) {
    final charts = dashPro.charts;
    if (dashPro.isLoading)
      return const SizedBox(
        height: 150,
        child: Center(child: CircularProgressIndicator()),
      );
    if (charts.isEmpty)
      return const SizedBox(
        height: 100,
        child: Center(child: Text("No chart data available")),
      );

    return Column(
      children: [
        _buildBarChartCard(
          "EMPLOYEE WISE",
          charts['employeeWise'] as Map<String, dynamic>? ?? {},
          isMobile,
        ),
        const SizedBox(height: 20),
        _buildBarChartCard(
          "CATEGORY WISE",
          charts['categoryWise'] as Map<String, dynamic>? ?? {},
          isMobile,
        ),
        const SizedBox(height: 20),
        _buildBarChartCard(
          "DAILY REPORT",
          charts['dailyReport'] as Map<String, dynamic>? ?? {},
          isMobile,
        ),
        const SizedBox(height: 20),
        _buildBarChartCard(
          "MONTHLY REPORT",
          charts['monthlyReport'] as Map<String, dynamic>? ?? {},
          isMobile,
        ),
        const SizedBox(height: 20),
        _buildBarChartCard(
          "DELEGATED TASKS REPORT",
          charts['delegatedReport'] as Map<String, dynamic>? ?? {},
          isMobile,
        ),
      ],
    );
  }

  Widget _buildBarChartCard(
    String title,
    Map<String, dynamic> data,
    bool isMobile,
  ) {
    final acVisible = Theme.of(context).extension<AppColors>()!;
    if (data.isEmpty) return const SizedBox.shrink();

    final entries = data.entries.toList();
    entries.sort((a, b) {
      int sumA = (a.value as Map).values.fold(
        0,
        (p, c) => (p as int) + (c as int),
      );
      int sumB = (b.value as Map).values.fold(
        0,
        (p, c) => (p as int) + (c as int),
      );
      return sumB.compareTo(sumA);
    });

    // Increased limit to 50 but with scrolling management
    final limitedEntries = entries.take(50).toList();

    // Dynamic width calculation: 60px per bar, min width is screen width
    double chartContentWidth = limitedEntries.length * 60.0;
    if (chartContentWidth < 300) chartContentWidth = 300;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: acVisible.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: acVisible.shadowColor, blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const Row(
                children: [
                  _LegendItem(color: Colors.orangeAccent, label: "Pend"),
                  SizedBox(width: 4),
                  _LegendItem(color: Colors.redAccent, label: "Ovr"),
                ],
              ),
            ],
          ),
          const SizedBox(height: 30),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              height: 240,
              width: chartContentWidth,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _calculateMaxY(limitedEntries),
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          int idx = value.toInt();
                          if (idx < 0 || idx >= limitedEntries.length)
                            return const SizedBox.shrink();
                          String label = limitedEntries[idx].key;
                          if (label.length > 10)
                            label = "${label.substring(0, 8)}..";
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 9,
                                color: acVisible.textMuted,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (v, m) => Text(
                          v.toInt().toString(),
                          style: TextStyle(
                            fontSize: 9,
                            color: acVisible.textMuted,
                          ),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (v) =>
                        FlLine(color: acVisible.divider, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(limitedEntries.length, (index) {
                    final entry = limitedEntries[index].value as Map;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY:
                              (entry['Pending'] ?? 0).toDouble() +
                              (entry['Overdue'] ?? 0).toDouble() +
                              (entry['In Progress'] ?? 0).toDouble() +
                              (entry['Completed'] ?? 0).toDouble(),
                          color: Colors.orangeAccent,
                          width: 20,
                          borderRadius: BorderRadius.circular(4),
                          rodStackItems: [
                            BarChartRodStackItem(
                              0,
                              (entry['Pending'] ?? 0).toDouble(),
                              Colors.orangeAccent,
                            ),
                            BarChartRodStackItem(
                              (entry['Pending'] ?? 0).toDouble(),
                              (entry['Pending'] ?? 0).toDouble() +
                                  (entry['Overdue'] ?? 0).toDouble(),
                              Colors.redAccent,
                            ),
                            BarChartRodStackItem(
                              (entry['Pending'] ?? 0).toDouble() +
                                  (entry['Overdue'] ?? 0).toDouble(),
                              (entry['Pending'] ?? 0).toDouble() +
                                  (entry['Overdue'] ?? 0).toDouble() +
                                  (entry['In Progress'] ?? 0).toDouble(),
                              Colors.blueAccent,
                            ),
                            BarChartRodStackItem(
                              (entry['Pending'] ?? 0).toDouble() +
                                  (entry['Overdue'] ?? 0).toDouble() +
                                  (entry['In Progress'] ?? 0).toDouble(),
                              (entry['Pending'] ?? 0).toDouble() +
                                  (entry['Overdue'] ?? 0).toDouble() +
                                  (entry['In Progress'] ?? 0).toDouble() +
                                  (entry['Completed'] ?? 0).toDouble(),
                              primaryColor,
                            ),
                          ],
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateMaxY(List<MapEntry<String, dynamic>> entries) {
    double max = 5;
    for (var e in entries) {
      double sum = (e.value as Map).values.fold(
        0.0,
        (p, c) => p + (c as int).toDouble(),
      );
      if (sum > max) max = sum;
    }
    return max * 1.2;
  }

  PieChartSectionData _chartSection(int value, Color color, String title) {
    return PieChartSectionData(
      color: color,
      value: value.toDouble(),
      title: '',
      radius: 12,
      showTitle: false,
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 8,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
