import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/auth_provider.dart';
import 'categories_screen.dart';
import 'general_settings_screen.dart';
import 'holidays_screen.dart';
import 'notifications_reminders_screen.dart';
import 'role_permission_screen.dart';
import 'tag_settings_screen.dart';
import 'change_password_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showUnavailableMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final userRole = auth.currentUser?.role?.toUpperCase() ?? 'USER';
    final isAdmin = userRole == 'ADMIN' || userRole == 'SUPERADMIN';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'SETTINGS',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: const Color(0xFF003366),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWebStyleSection('WORKSPACE PREFERENCES'),
              _buildSettingsTile(
                icon: Icons.settings_outlined,
                title: 'General',
                description: 'Update profile and workspace preferences',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GeneralSettingsScreen(),
                  ),
                ),
              ),
              _buildSettingsTile(
                icon: Icons.folder_open_outlined,
                title: 'Categories',
                description: 'Manage your task categories',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CategoriesScreen(),
                  ),
                ),
              ),
              _buildSettingsTile(
                icon: Icons.local_offer_outlined,
                title: 'Tags',
                description: 'Manage task tags and labels',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TagSettingsScreen(),
                  ),
                ),
              ),
              _buildSettingsTile(
                icon: Icons.calendar_today_outlined,
                title: 'Holidays',
                description: 'View and manage office holidays',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HolidaysScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildWebStyleSection('ACCESS & SECURITY'),
              if (isAdmin)
                _buildSettingsTile(
                  icon: Icons.people_outline,
                  title: 'Roles and Permissions',
                  description: 'Manage user access and feature permissions',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RolePermissionScreen(),
                    ),
                  ),
                ),
              _buildSettingsTile(
                icon: Icons.notifications_none_outlined,
                title: 'Notifications',
                description: 'Configure alert preferences',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsRemindersScreen(),
                  ),
                ),
              ),
              _buildSettingsTile(
                icon: Icons.shield_outlined,
                title: 'Security',
                description: 'Password and access controls',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChangePasswordScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebStyleSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Color(0xFF94A3B8),
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF475569), size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFFCBD5E1),
        ),
      ),
    );
  }
}
