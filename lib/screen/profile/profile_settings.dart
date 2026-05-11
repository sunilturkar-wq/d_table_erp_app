import 'dart:convert';
import 'package:d_table_erp_app/provider/auth_provider.dart';
import 'package:d_table_erp_app/provider/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'my_profile_screen.dart';
import '../notifications/notifications_screen.dart';
import '../auth/login/login_screen.dart';
import 'manage_users.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({Key? key}) : super(key: key);

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    // Getting image from the CAMERA (Selfie mode technically depends on the platform picker default,
    // but ImageSource.camera will pop the camera to take a snap).
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
    );

    if (image != null && mounted) {
      final bytes = await image.readAsBytes();
      final base64String = "data:image/jpeg;base64,${base64Encode(bytes)}";

      final provider = Provider.of<AuthProvider>(context, listen: false);

      // Scaffold Messenger context issue workaround: save before async
      final scaffoldMsg = ScaffoldMessenger.of(context);

      bool success = await provider.updateProfile({
        "profilePhotoUrl": base64String,
      });

      if (success) {
        scaffoldMsg.showSnackBar(
          const SnackBar(
            content: Text(
              'Profile photo updated successfully!',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        scaffoldMsg.showSnackBar(
          SnackBar(
            content: Text(
              provider.errorMessage ?? 'Upload failed',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Profile & Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 55,
                            backgroundColor: Theme.of(context).primaryColor,
                            backgroundImage:
                                (user.profilePhotoUrl != null &&
                                    user.profilePhotoUrl!.isNotEmpty)
                                ? (user.profilePhotoUrl!.startsWith('http')
                                      ? NetworkImage(user.profilePhotoUrl!)
                                      : MemoryImage(
                                              base64Decode(
                                                user.profilePhotoUrl!
                                                    .split(',')
                                                    .last,
                                              ),
                                            )
                                            as ImageProvider)
                                : null,
                            child:
                                (user.profilePhotoUrl == null ||
                                    user.profilePhotoUrl!.isEmpty)
                                ? Text(
                                    user.firstName[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 40,
                                      color: Colors.white,
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => _pickImage(context),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.grey[200]!,
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Color(0xFF003366),
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "${user.firstName} ${user.lastName}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      user.designation ?? user.role,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 32),

                    ListTile(
                      leading: const Icon(Icons.person),
                      title: const Text('View Profile'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MyProfileScreen(user: user),
                          ),
                        );
                      },
                    ),
                    const Divider(),

                    ListTile(
                      leading: const Icon(Icons.dark_mode),
                      title: const Text('Dark Mode'),
                      trailing: Switch(
                        value: context.watch<ThemeProvider>().isDarkMode,
                        activeColor: const Color(0xFF003366),
                        onChanged: (value) {
                          context.read<ThemeProvider>().toggleTheme();
                        },
                      ),
                    ),
                    const Divider(),

                    // ListTile(
                    //   leading: const Icon(Icons.confirmation_num),
                    //   title: const Text('Support / Help Tickets'),
                    //   trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    //   onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen())),
                    // ),
                    // const Divider(),
                    if (context.read<AuthProvider>().isAdmin) ...[
                      ListTile(
                        leading: const Icon(Icons.admin_panel_settings),
                        title: const Text('Manage Users'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ManageUsersScreen(),
                          ),
                        ),
                      ),
                      const Divider(),
                    ],

                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.red),
                      ),
                      onTap: () async {
                        await context.read<AuthProvider>().logout();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
