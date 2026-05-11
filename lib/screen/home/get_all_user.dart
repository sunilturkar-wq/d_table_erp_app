import 'package:d_table_erp_app/config/api_constants.dart';
import 'package:d_table_erp_app/model/user_model.dart';
import 'package:d_table_erp_app/services/dio_client.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class GetAllUserScreen extends StatefulWidget {
  const GetAllUserScreen({super.key});

  @override
  State<GetAllUserScreen> createState() => _GetAllUserScreenState();
}

class _GetAllUserScreenState extends State<GetAllUserScreen> {
  final Dio _dio = DioClient().dio;
  List<UserModel> _users = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _dio.get(ApiConstants.getAllUser);
      final dynamic data = response.data;

      List<dynamic> usersList = [];
      if (data is Map) {
        usersList = data['users'] ?? data['data'] ?? [];
      } else if (data is List) {
        usersList = data;
      }

      setState(() {
        _users = usersList.map((u) => UserModel.fromJson(u)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteUser(String userId) async {
    // API Link: /auth/users/:id
    final String deleteUrl = "${ApiConstants.getAllUser}/$userId";

    // Optimistic UI update
    final originalUsers = List<UserModel>.from(_users);
    setState(() {
      _users.removeWhere((u) => u.id == userId);
    });

    try {
      final response = await _dio.delete(deleteUrl);
      if (response.statusCode == 200 || response.statusCode == 204) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("User deleted successfully"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception("Failed to delete");
      }
    } catch (e) {
      // Revert if failed
      setState(() {
        _users = originalUsers;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmDelete(UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete User?"),
        content: Text("Are you sure you want to delete ${user.fullName}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteUser(user.id);
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.red)),
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
        title: const Text(
          "All Registered Users",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF003366),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _fetchUsers,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: _isLoading && _users.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF003366)),
            )
          : _error != null && _users.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Error: $_error", textAlign: TextAlign.center),
                  ElevatedButton(
                    onPressed: _fetchUsers,
                    child: const Text("Retry"),
                  ),
                ],
              ),
            )
          : _users.isEmpty
          ? const Center(child: Text("No users found"))
          : RefreshIndicator(
              onRefresh: _fetchUsers,
              color: const Color(0xFF003366),
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    elevation: 0.5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(
                          0xFF003366,
                        ).withOpacity(0.1),
                        child: Text(
                          user.fullName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF003366),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        user.fullName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "${user.workEmail}\nDept: ${user.department}",
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () => _confirmDelete(user),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
