import 'package:d_table_erp_app/model/user_model.dart';
import 'package:d_table_erp_app/provider/auth_provider.dart';
import 'package:d_table_erp_app/provider/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widget/personal_profile_panel.dart';

class MyProfileScreen extends StatefulWidget {
  final UserModel user;

  const MyProfileScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  late UserModel displayUser;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    displayUser = widget.user;
    _refreshUserData();
  }

  Future<void> _refreshUserData() async {
    try {
      // Get the latest user data from AuthProvider
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.currentUser;

      if (currentUser != null) {
        setState(() {
          displayUser = currentUser;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final green = ThemeProvider.primaryBlue;
    final appColors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: true,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: green.withOpacity(0.2),
                    child: Text(
                      displayUser.firstName[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: green,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${displayUser.firstName} ${displayUser.lastName}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayUser.designation,
                    style: TextStyle(fontSize: 14, color: appColors.textMuted),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayUser.department,
                    style: TextStyle(fontSize: 12, color: appColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Personal Information
            _buildSection(
              'Personal Information',
              [
                _buildInfoRow('First Name', displayUser.firstName, appColors),
                _buildInfoRow('Last Name', displayUser.lastName, appColors),
                _buildInfoRow(
                  'Mobile Number',
                  displayUser.mobileNumber ?? 'N/A',
                  appColors,
                ),
                _buildInfoRow('Gender', displayUser.gender ?? 'N/A', appColors),
                _buildInfoRow(
                  'Date of Birth',
                  displayUser.dateOfBirth ?? 'N/A',
                  appColors,
                ),
                _buildInfoRow(
                  'Marital Status',
                  displayUser.maritalStatus ?? 'N/A',
                  appColors,
                ),
              ],
              green,
              appColors,
            ),
            const SizedBox(height: 20),

            // Contact Information
            _buildSection(
              'Contact Information',
              [
                _buildInfoRow('Work Email', displayUser.workEmail, appColors),
                _buildInfoRow(
                  'Personal Email',
                  displayUser.personalEmail ?? 'N/A',
                  appColors,
                ),
                _buildInfoRow(
                  'Emergency Contact',
                  displayUser.emergencyMobileNo ?? 'N/A',
                  appColors,
                ),
                _buildInfoRow(
                  'Address',
                  displayUser.address ?? 'N/A',
                  appColors,
                ),
                _buildInfoRow('City', displayUser.city ?? 'N/A', appColors),
                _buildInfoRow('State', displayUser.state ?? 'N/A', appColors),
                _buildInfoRow(
                  'Nationality',
                  displayUser.nationality ?? 'N/A',
                  appColors,
                ),
              ],
              green,
              appColors,
            ),
            const SizedBox(height: 20),

            // Professional Information
            _buildSection(
              'Professional Information',
              [
                _buildInfoRow(
                  'Designation',
                  displayUser.designation,
                  appColors,
                ),
                _buildInfoRow('Department', displayUser.department, appColors),
                _buildInfoRow('Role', displayUser.role, appColors),
                _buildInfoRow(
                  'Joining Date',
                  displayUser.joiningDate ?? 'N/A',
                  appColors,
                ),
                _buildInfoRow(
                  'Current Salary',
                  displayUser.currentSalary != null
                      ? '₹${displayUser.currentSalary}'
                      : 'N/A',
                  appColors,
                ),
              ],
              green,
              appColors,
            ),
            const SizedBox(height: 32),

            // Edit Profile Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => FractionallySizedBox(
                      heightFactor: 0.85,
                      child: PersonalProfilePanel(
                        user: displayUser,
                        onClose: () => Navigator.pop(ctx),
                        green: green,
                        appColors: appColors,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.edit, color: Colors.white),
                label: const Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    String title,
    List<Widget> items,
    Color green,
    AppColors appColors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: green,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: green.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, AppColors appColors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: appColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: TextStyle(
                color: appColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
