import 'package:flutter/material.dart';
import 'package:d_table_erp_app/provider/auth_provider.dart';
import 'package:provider/provider.dart';
import '../../../widget/shimmer_loading.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({Key? key}) : super(key: key);

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().fetchAllUsers();
    });
  }

  void _confirmDelete(BuildContext context, String userId, String userName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to delete $userName? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<AuthProvider>().deleteUser(
                userId,
              );
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$userName deleted successfully')),
                );
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete user')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text('Manage Users')),
      body: authProvider.isLoading
          ? const ShimmerListLoading()
          : authProvider.allUsers.isEmpty
          ? const Center(child: Text('No users found'))
          : RefreshIndicator(
              onRefresh: () async {
                await context.read<AuthProvider>().fetchAllUsers();
              },
              child: ListView.builder(
                itemCount: authProvider.allUsers.length,
                itemBuilder: (context, index) {
                  final user = authProvider.allUsers[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(user.firstName[0].toUpperCase()),
                      ),
                      title: Text("${user.firstName} ${user.lastName}"),
                      subtitle: Text("${user.role} | ${user.workEmail}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(
                          context,
                          user.id,
                          "${user.firstName} ${user.lastName}",
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
