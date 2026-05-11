import 'dart:convert' as dart_convert;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/auth_provider.dart';
import '../provider/theme_provider.dart';
import '../screen/auth/login/login_screen.dart';
import '../screen/home/delegate_task_screen.dart';
import '../screen/home/all_tasks_screen.dart';
import '../screen/home/my_task.dart';
import '../screen/home/my_team.dart';
import '../screen/groups/my_groups.dart';
import '../screen/settings/settings_screen.dart';
import '../screen/settings/holidays_screen.dart';
import '../screen/activities/activities_screen.dart';
import '../screen/tasks/task_templates_screen.dart';
import '../screen/tasks/in_loop_tasks_screen.dart';
import '../screen/tasks/deleted_tasks_screen.dart';

class MyCustomDrawer extends StatelessWidget {
  const MyCustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final userName = user != null ? "${user.firstName} ${user.lastName}" : "Loading User...";
    final userEmail = user != null ? user.workEmail : "loading@erp.com";
    final initial = user != null && user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : "U";

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          _buildHeader(context, userName, userEmail, initial, user?.profilePhotoUrl),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              children: [
                _buildSectionHeader("DASHBOARD"),
                _drawerTile(context, Icons.grid_view_rounded, "Overview", true, () => Navigator.pop(context)),
                
                const SizedBox(height: 20),
                _buildSectionHeader("TASKS"),
                _drawerTile(context, Icons.task_alt_rounded, "My Tasks", false, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => MyTaskScreen(title: 'My Task')));
                }),
                _drawerTile(context, Icons.format_list_bulleted_rounded, "All Tasks", false, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AllTasksScreen(title: 'All Tasks')));
                }),
                _drawerTile(context, Icons.outbox_rounded, "Delegated Tasks", false, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const DelegateTasksScreen()));
                }),
                _drawerTile(context, Icons.notifications_active_outlined, "Subscribed Tasks", false, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const InLoopTasksScreen()));
                }),
                _drawerTile(context, Icons.delete_outline_rounded, "Deleted Tasks", false, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const DeletedTasksScreen()));
                }),
                _drawerTile(context, Icons.file_copy_outlined, "Task Templates", false, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const TaskTemplatesScreen()));
                }),

                const SizedBox(height: 20),
                _buildSectionHeader("COLLABORATION"),
                _drawerTile(context, Icons.groups_rounded, "My Team", false, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => MyTeamScreen()));
                }),
                
                _drawerTile(context, Icons.category_outlined, "Groups", false, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const MyGroupsScreen()));
                }),

                const SizedBox(height: 20),
                _buildSectionHeader("SYSTEM"),
                _drawerTile(context, Icons.event_note_rounded, "Holidays", false, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const HolidaysScreen()));
                }),
                _drawerTile(context, Icons.history_rounded, "Activities", false, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ActivitiesScreen()));
                }),
                _drawerTile(context, Icons.settings_rounded, "Settings", false, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                }),
              ],
            ),
          ),
          _buildFooter(context, auth),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String name, String email, String initial, String? photoUrl) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20, bottom: 20, left: 20, right: 20),
      decoration: BoxDecoration(
        color: ThemeProvider.primaryBlue,
        borderRadius: const BorderRadius.only(bottomRight: Radius.circular(30)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) 
                ? (photoUrl.startsWith('http')
                    ? NetworkImage(photoUrl)
                    : MemoryImage(dart_convert.base64Decode(photoUrl.split(',').last)) as ImageProvider)
                : null,
            child: (photoUrl == null || photoUrl.isEmpty)
                ? Text(initial, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF003366)))
                : null,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(email, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8, top: 4),
      child: Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey.shade500, letterSpacing: 1.2)),
    );
  }

  Widget _drawerTile(BuildContext context, IconData icon, String title, bool isSelected, VoidCallback onTap, {Color? color}) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? ThemeProvider.primaryBlue.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: isSelected ? ThemeProvider.primaryBlue : (color ?? appColors.textMuted), size: 22),
        title: Text(title, style: TextStyle(color: isSelected ? ThemeProvider.primaryBlue : (color ?? appColors.textSecondary), fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, fontSize: 14)),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade200))),
      child: _drawerTile(context, Icons.logout_rounded, "Logout", false, () async {
        await auth.logout();
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
        }
      }, color: Colors.redAccent),
    );
  }
}
