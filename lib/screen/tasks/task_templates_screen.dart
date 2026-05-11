import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../model/task_template_model.dart';
import '../../provider/task_template_provider.dart';
import '../../provider/category_provider.dart';
import '../../provider/user_provider.dart';
import '../../widget/task_template_sheet.dart';
import '../../widget/app_dropdown.dart';
import '../../widget/assign_task_sheet.dart';

class TaskTemplatesScreen extends StatefulWidget {
  const TaskTemplatesScreen({Key? key}) : super(key: key);

  @override
  State<TaskTemplatesScreen> createState() => _TaskTemplatesScreenState();
}

class _TaskTemplatesScreenState extends State<TaskTemplatesScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<String> priorityOptions = [
    'All',
    'Low',
    'Medium',
    'High',
    'Urgent',
  ];
  final List<String> frequencyOptions = [
    'All',
    'Once',
    'Daily',
    'Weekly',
    'Monthly',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskTemplateProvider>().fetchTemplates();
      context.read<CategoryProvider>().fetchCategories();
      context.read<UserProvider>().fetchUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Urgent':
        return Colors.redAccent;
      case 'High':
        return Colors.orangeAccent;
      case 'Medium':
        return Colors.amber;
      case 'Low':
      default:
        return Colors.green;
    }
  }

  Future<void> _openAssignFromTemplate(TaskTemplateModel template) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: FractionallySizedBox(
          heightFactor: 0.94,
          child: AssignTaskSheet(
            templateData: template,
            onSuccess: () {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Task assigned from template!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          ),
        ),
      ),
    );

    if (result == true && mounted) {
      context.read<TaskTemplateProvider>().fetchTemplates(
        skipLoadingChange: true,
      );
    }
  }

  Widget _buildActiveChip(String label, VoidCallback onClear) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F7EF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF003366).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Color(0xFF00A877),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onClear,
            child: const Icon(Icons.close, size: 12, color: Color(0xFF00A877)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'TASK TEMPLATES',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: const Color(0xFF003366),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: FractionallySizedBox(
                    heightFactor: 0.9,
                    child: const TaskTemplateSheet(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer2<TaskTemplateProvider, CategoryProvider>(
        builder: (context, provider, catProvider, child) {
          final Map<String, int> counts = {'All': provider.templates.length};
          for (var cat in catProvider.categoryModels) {
            counts[cat.name] = 0;
          }
          for (var t in provider.templates) {
            if (t.category != null &&
                t.category!.isNotEmpty &&
                counts.containsKey(t.category!)) {
              counts[t.category!] = counts[t.category!]! + 1;
            } else if (t.category != null &&
                t.category!.isNotEmpty &&
                !counts.containsKey(t.category!)) {
              counts[t.category!] = 1;
            }
          }
          final cats = counts.entries
              .map((e) => {'name': e.key, 'count': e.value})
              .toList();
          final filteredList = provider.filteredTemplates;

          final bool hasActiveFilters =
              provider.searchQuery.isNotEmpty ||
              provider.selectedCategory != 'All' ||
              provider.createdByFilter != 'All' ||
              provider.priorityFilter != 'All' ||
              provider.frequencyFilter != 'All';

          if (provider.isLoading && provider.templates.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Filters Section
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Search
                      Container(
                        width: 150,
                        margin: const EdgeInsets.only(right: 8),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search templates...',
                            hintStyle: const TextStyle(fontSize: 12),
                            prefixIcon: const Icon(Icons.search, size: 16),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 0,
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
                          ),
                          onChanged: (val) => provider.setSearchQuery(val),
                        ),
                      ),

                      // Priority Filter
                      AppDropdown<String>(
                        isCompact: true,
                        value: provider.priorityFilter,
                        items: priorityOptions,
                        labelBuilder: (v) => v == 'All' ? 'Priority' : v,
                        prefixIcon: Icons.flag_outlined,
                        onChanged: (val) {
                          if (val != null) provider.setPriorityFilter(val);
                        },
                      ),
                      const SizedBox(width: 8),

                      // Frequency Filter
                      AppDropdown<String>(
                        isCompact: true,
                        value: provider.frequencyFilter,
                        items: frequencyOptions,
                        labelBuilder: (v) => v == 'All' ? 'Frequency' : v,
                        prefixIcon: Icons.repeat,
                        onChanged: (val) {
                          if (val != null) provider.setFrequencyFilter(val);
                        },
                      ),
                      const SizedBox(width: 8),

                      // Created By Filter
                      AppDropdown<String>(
                        isCompact: true,
                        value: provider.createdByFilter,
                        items: ['All', ...provider.users.map((e) => e.id)],
                        labelBuilder: (v) {
                          if (v == 'All') return 'Created By';
                          try {
                            final user = provider.users.firstWhere(
                              (u) => u.id == v,
                            );
                            return '${user.firstName} ${user.lastName}';
                          } catch (_) {
                            return v;
                          }
                        },
                        prefixIcon: Icons.person_outline,
                        onChanged: (val) {
                          if (val != null) provider.setCreatedByFilter(val);
                        },
                      ),

                      if (hasActiveFilters) ...[
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: provider.resetFilters,
                          icon: const Icon(
                            Icons.refresh,
                            size: 16,
                            color: Colors.redAccent,
                          ),
                          label: const Text(
                            'Reset',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.red.shade50,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              if (hasActiveFilters)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  color: Colors.white,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const Text(
                          'ACTIVE:',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.grey,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (provider.searchQuery.isNotEmpty)
                          _buildActiveChip(
                            '"${provider.searchQuery}"',
                            () => provider.setSearchQuery(''),
                          ),
                        if (provider.selectedCategory != 'All')
                          _buildActiveChip(
                            provider.selectedCategory,
                            () => provider.setSelectedCategory('All'),
                          ),
                        if (provider.priorityFilter != 'All')
                          _buildActiveChip(
                            provider.priorityFilter,
                            () => provider.setPriorityFilter('All'),
                          ),
                        if (provider.frequencyFilter != 'All')
                          _buildActiveChip(
                            provider.frequencyFilter,
                            () => provider.setFrequencyFilter('All'),
                          ),
                        if (provider.createdByFilter != 'All')
                          _buildActiveChip(
                            'User: ${provider.createdByFilter}',
                            () => provider.setCreatedByFilter('All'),
                          ),

                        const SizedBox(width: 4),
                        Text(
                          '- ${filteredList.length} results',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 8),

              // Categories Horizontal List (replaces Sidebar on Web)
              SizedBox(
                height: 45,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: cats.length,
                  itemBuilder: (context, index) {
                    final catName = cats[index]['name'] as String;
                    final count = cats[index]['count'];
                    final isSelected = provider.selectedCategory == catName;

                    return GestureDetector(
                      onTap: () => provider.setSelectedCategory(catName),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF003366).withOpacity(0.1)
                              : Colors.white,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF003366)
                                : Colors.grey.shade200,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            '$catName ($count)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? const Color(0xFF1E8D66)
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),

              // Templates List
              Expanded(
                child: filteredList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 48,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "No Templates Found",
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              hasActiveFilters
                                  ? "Try adjusting your filters"
                                  : "Add your first template to get started",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (hasActiveFilters) ...[
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: provider.resetFilters,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF003366),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text(
                                  'Clear All Filters',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final template = filteredList[index];

                          return InkWell(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => Padding(
                                  padding: EdgeInsets.only(
                                    bottom: MediaQuery.of(
                                      context,
                                    ).viewInsets.bottom,
                                  ),
                                  child: FractionallySizedBox(
                                    heightFactor: 0.9,
                                    child: TaskTemplateSheet(
                                      template: template,
                                    ),
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade100),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            template.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.black87,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.check_box_outlined,
                                                color: Color(0xFF003366),
                                                size: 20,
                                              ),
                                              tooltip: 'Assign from Template',
                                              constraints:
                                                  const BoxConstraints(),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                  ),
                                              onPressed: () =>
                                                  _openAssignFromTemplate(
                                                    template,
                                                  ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.redAccent,
                                                size: 20,
                                              ),
                                              tooltip: 'Delete',
                                              constraints:
                                                  const BoxConstraints(),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                  ),
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    title: const Text(
                                                      'Delete Template',
                                                    ),
                                                    content: const Text(
                                                      'Are you sure you want to delete this?',
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                              context,
                                                            ),
                                                        child: const Text(
                                                          'Cancel',
                                                        ),
                                                      ),
                                                      TextButton(
                                                        onPressed: () async {
                                                          Navigator.pop(
                                                            context,
                                                          );
                                                          await provider
                                                              .deleteTemplate(
                                                                template.id,
                                                              );
                                                        },
                                                        child: const Text(
                                                          'Delete',
                                                          style: TextStyle(
                                                            color: Colors.red,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 8),

                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        if (template.priority != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getPriorityColor(
                                                template.priority!,
                                              ).withOpacity(0.1),
                                              border: Border.all(
                                                color: _getPriorityColor(
                                                  template.priority!,
                                                ).withOpacity(0.3),
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              template.priority!.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: _getPriorityColor(
                                                  template.priority!,
                                                ),
                                              ),
                                            ),
                                          ),
                                        if (template.category != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              border: Border.all(
                                                color: Colors.grey.shade300,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              template.category!.toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ),
                                        if (template.frequency != null &&
                                            template.frequency != 'Once')
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.indigo.shade50,
                                              border: Border.all(
                                                color: Colors.indigo.shade100,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.repeat,
                                                  size: 10,
                                                  color: Colors.indigo.shade400,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  template.frequency!
                                                      .toUpperCase(),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        Colors.indigo.shade400,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        // Display Checklist count badge if available
                                        if (template.checklistItems != null &&
                                            template.checklistItems!.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.teal.shade50,
                                              border: Border.all(
                                                color: Colors.teal.shade100,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.checklist,
                                                  size: 10,
                                                  color: Colors.teal.shade600,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${template.checklistItems!.length} ITEMS',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.teal.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),

                                    const SizedBox(height: 12),

                                    if (template.description != null &&
                                        template.description!.isNotEmpty)
                                      Text(
                                        template.description!,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),

                                    const SizedBox(height: 12),
                                    const Divider(height: 1),
                                    const SizedBox(height: 12),

                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 12,
                                              backgroundColor: Colors.teal,
                                              child: Text(
                                                '${template.creatorFirstName?[0] ?? '?'}${template.creatorLastName?[0] ?? ''}',
                                                style: const TextStyle(
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${template.creatorFirstName ?? 'User'} ${template.creatorLastName ?? ''}',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.date_range,
                                              size: 12,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              template.createdAt != null
                                                  ? DateFormat(
                                                      'MMM dd, yyyy',
                                                    ).format(
                                                      template.createdAt!,
                                                    )
                                                  : 'N/A',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
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
    );
  }
}
