import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:d_table_erp_app/provider/group_provider.dart';
import 'package:d_table_erp_app/provider/theme_provider.dart';
import 'package:d_table_erp_app/provider/user_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'group_detail.dart';

class MyGroupsScreen extends StatefulWidget {
  const MyGroupsScreen({Key? key}) : super(key: key);

  @override
  State<MyGroupsScreen> createState() => _MyGroupsScreenState();
}

class _MyGroupsScreenState extends State<MyGroupsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  List<String> _selectedMemberIds = [];
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupProvider>().fetchMyGroups();
      context.read<UserProvider>().fetchUsers();
    });
  }

  Future<void> _pickImage(StateSetter setDialogState) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setDialogState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _showCreateGroupDialog() {
    final primary = ThemeProvider.primaryBlue;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text(
            'New Group',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- IMAGE PICKER ---
                  GestureDetector(
                    onTap: () => _pickImage(setDialogState),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : null,
                      child: _selectedImage == null
                          ? Icon(
                              Icons.add_a_photo,
                              color: Colors.grey.shade600,
                              size: 30,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Group Photo",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Group Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.group),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.description),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Select Members",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Consumer<UserProvider>(
                    builder: (context, userProv, _) {
                      if (userProv.isLoading)
                        return const Center(child: CircularProgressIndicator());
                      return Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: primary.withOpacity(0.5),
                            width: 2,
                          ), // Highlighted border
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: primary.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: ListView.builder(
                            itemCount: userProv.users.length,
                            itemBuilder: (context, index) {
                              final user = userProv.users[index];
                              final isSelected = _selectedMemberIds.contains(
                                user.id,
                              );
                              return CheckboxListTile(
                                title: Text(
                                  user.fullName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  user.workEmail ?? '',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                value: isSelected,
                                activeColor: primary,
                                dense: true,
                                onChanged: (val) {
                                  setDialogState(() {
                                    if (val == true) {
                                      _selectedMemberIds.add(user.id);
                                    } else {
                                      _selectedMemberIds.remove(user.id);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _nameController.clear();
                _descController.clear();
                _selectedMemberIds.clear();
                _selectedImage = null;
                Navigator.pop(context);
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            Consumer<GroupProvider>(
              builder: (context, groupProv, _) => ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: groupProv.isLoading
                    ? null
                    : () async {
                        if (_nameController.text.isEmpty) return;
                        final success = await groupProv.createGroup(
                          _nameController.text,
                          _descController.text,
                          _selectedMemberIds,
                          image: _selectedImage,
                        );
                        if (success) {
                          _nameController.clear();
                          _descController.clear();
                          _selectedMemberIds.clear();
                          _selectedImage = null;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Group created successfully!"),
                            ),
                          );
                        }
                      },
                child: groupProv.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Create',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
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
                "MY GROUPS",
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
              Padding(
                padding: const EdgeInsets.only(right: 12.0, top: 8, bottom: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      LucideIcons.plus,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: _showCreateGroupDialog,
                    tooltip: 'Create New Group',
                  ),
                ),
              ),
            ],
          ),
        ],
        body: Consumer<GroupProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.myGroups.isEmpty) {
              return Center(child: CircularProgressIndicator(color: primary));
            }

            if (provider.myGroups.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("No groups found."),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: primary),
                      onPressed: () => provider.fetchMyGroups(),
                      child: const Text(
                        "Refresh",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              color: primary,
              onRefresh: () => provider.fetchMyGroups(),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                itemCount: provider.myGroups.length,
                itemBuilder: (context, index) {
                  final group = provider.myGroups[index];
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.withOpacity(0.1)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: primary.withOpacity(0.2),
                        backgroundImage:
                            group.imageUrl != null && group.imageUrl!.isNotEmpty
                            ? NetworkImage(group.imageUrl!)
                            : null,
                        child:
                            group.imageUrl != null && group.imageUrl!.isNotEmpty
                            ? null
                            : Text(
                                group.name.isNotEmpty
                                    ? group.name[0].toUpperCase()
                                    : "G",
                                style: TextStyle(
                                  color: Colors.green.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      title: Text(
                        group.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        group.description ?? 'No description',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "${group.memberCount} Members",
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right,
                            color: Colors.grey,
                            size: 18,
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GroupDetailScreen(
                              groupId: group.id,
                              groupName: group.name,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
