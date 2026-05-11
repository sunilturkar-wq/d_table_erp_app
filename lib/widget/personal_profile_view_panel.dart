import 'package:flutter/material.dart';
import '../provider/theme_provider.dart';
import '../model/user_model.dart';

class PersonalProfileViewPanel extends StatelessWidget {
  final UserModel user;
  final VoidCallback onClose;
  final VoidCallback onUpdate;
  final Color green;
  final AppColors appColors;

  const PersonalProfileViewPanel({
    required this.user,
    required this.onClose,
    required this.onUpdate,
    required this.green,
    required this.appColors,
  });

  @override
  Widget build(BuildContext context) {
    final ac = appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: ac.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            decoration: BoxDecoration(
              color: isDark ? ac.toolbarBackground : green.withOpacity(0.06),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: ac.divider)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Profile',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ac.textPrimary,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: ac.textMuted),
                  onPressed: onClose,
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection('Personal Information', [
                    _buildReadOnlyField('First Name', user.firstName, ac),
                    _buildReadOnlyField('Last Name', user.lastName, ac),
                    _buildReadOnlyField('Mobile Number', user.mobileNumber ?? 'N/A', ac),
                    _buildReadOnlyField('Gender', user.gender ?? 'N/A', ac),
                    _buildReadOnlyField('Date of Birth', user.dateOfBirth ?? 'N/A', ac),
                    _buildReadOnlyField('Marital Status', user.maritalStatus ?? 'N/A', ac),
                  ], ac),
                  const SizedBox(height: 20),
                  _buildSection('Contact Information', [
                    _buildReadOnlyField('Work Email', user.workEmail, ac),
                    _buildReadOnlyField('Personal Email', user.personalEmail ?? 'N/A', ac),
                    _buildReadOnlyField('Emergency Contact', user.emergencyMobileNo ?? 'N/A', ac),
                    _buildReadOnlyField('Address', user.address ?? 'N/A', ac),
                    _buildReadOnlyField('City', user.city ?? 'N/A', ac),
                    _buildReadOnlyField('State', user.state ?? 'N/A', ac),
                    _buildReadOnlyField('Nationality', user.nationality ?? 'N/A', ac),
                  ], ac),
                  const SizedBox(height: 20),
                  _buildSection('Professional Information', [
                    _buildReadOnlyField('Designation', user.designation, ac),
                    _buildReadOnlyField('Department', user.department, ac),
                    _buildReadOnlyField('Role', user.role, ac),
                    _buildReadOnlyField('Joining Date', user.joiningDate ?? 'N/A', ac),
                    _buildReadOnlyField('Current Salary', user.currentSalary != null ? '₹${user.currentSalary}' : 'N/A', ac),
                  ], ac),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: onUpdate,
                      child: const Text(
                        'Update Profile',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> fields, AppColors ac) {
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
          child: Column(
            children: fields,
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(String label, String value, AppColors ac) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: ac.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: green.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(6),
              color: green.withOpacity(0.05),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: ac.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
