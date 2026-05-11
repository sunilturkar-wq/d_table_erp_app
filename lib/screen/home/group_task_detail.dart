import 'package:d_table_erp_app/provider/group_provider.dart';
import 'package:d_table_erp_app/widget/app_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GroupTaskDetailScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupTaskDetailScreen({
    Key? key,
    required this.groupId,
    required this.groupName,
  }) : super(key: key);

  @override
  State<GroupTaskDetailScreen> createState() => _GroupTaskDetailScreenState();
}

class _GroupTaskDetailScreenState extends State<GroupTaskDetailScreen> {
  final TextEditingController _taskNameCtrl = TextEditingController();
  final TextEditingController _taskDescCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupProvider>().fetchGroupDetails(widget.groupId);
    });
  }

  void _showAssignBottomSheet() {
    String? selectedAssigneeId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final groupProvider = context.read<GroupProvider>();
        final members = groupProvider.selectedGroup?.members ?? [];

        // Prepare list for dropdown. Maps members to a manageable format.
        // We add "All Members" as a null value option.
        final List<Map<String, dynamic>?> assignableOptions = [
          null,
          ...members.cast<Map<String, dynamic>>(),
        ];

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Assign Task to Group",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _taskNameCtrl,
                    decoration: InputDecoration(
                      labelText: "Task Name *",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.task),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _taskDescCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: "Task Description",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  AppDropdown<Map<String, dynamic>?>(
                    isCompact: false,
                    value: assignableOptions.firstWhere(
                      (opt) => opt != null
                          ? opt['userId'] == selectedAssigneeId
                          : selectedAssigneeId == null,
                      orElse: () => null,
                    ),
                    items: assignableOptions,
                    labelBuilder: (m) {
                      if (m == null) return "All Group Members";
                      return "${m['firstName']} ${m['lastName'] ?? ''}".trim() +
                          (m['role'] != null ? " (${m['role']})" : "");
                    },
                    label: "ASSIGN TO",
                    prefixIcon: Icons.group_rounded,
                    onChanged: (val) {
                      setModalState(() {
                        selectedAssigneeId = val?['userId'];
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003366),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: () async {
                        if (_taskNameCtrl.text.trim().isEmpty) return;

                        // ⚠️ assignTaskToGroup not available in new backend
                        // Display info to user
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Group task assignment is not available in the current backend. Use Delegations instead.",
                            ),
                            backgroundColor: Colors.orange,
                            duration: Duration(seconds: 3),
                          ),
                        );
                      },
                      child: const Text(
                        "Assign Task",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.groupName} Tasks'),
        backgroundColor: const Color(0xFF003366),
      ),
      body: Consumer<GroupProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.groupTasks.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final tasks = provider.groupTasks;

          if (tasks.isEmpty) {
            return const Center(
              child: Text(
                "No tasks assigned to this group yet.",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Card(
                elevation: 2,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF003366).withOpacity(0.2),
                    child: const Icon(
                      Icons.assignment,
                      color: Color(0xFF003366),
                    ),
                  ),
                  title: Text(
                    task['delegationName'] ?? 'Unknown Task',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task['description'] ?? 'No description'),
                      const SizedBox(height: 4),
                      Text(
                        "Status: ${task['status'] ?? 'Pending'}",
                        style: const TextStyle(color: Colors.blueAccent),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAssignBottomSheet,
        backgroundColor: const Color(0xFF003366),
        icon: const Icon(Icons.add_task),
        label: const Text("Assign Task"),
      ),
    );
  }
}
