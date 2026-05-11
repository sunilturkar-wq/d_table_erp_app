import 'package:d_table_erp_app/model/user_model.dart';
import 'package:d_table_erp_app/provider/auth_provider.dart';
import 'package:d_table_erp_app/provider/theme_provider.dart';
import 'package:d_table_erp_app/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/phone_number_helper.dart';

class EditTeamMemberScreen extends StatefulWidget {
  final UserModel member;

  const EditTeamMemberScreen({Key? key, required this.member})
    : super(key: key);

  @override
  State<EditTeamMemberScreen> createState() => _EditTeamMemberScreenState();
}

class _EditTeamMemberScreenState extends State<EditTeamMemberScreen> {
  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;
  late TextEditingController _workEmailCtrl;
  late TextEditingController _mobileNumberCtrl;
  late TextEditingController _designationCtrl;
  late TextEditingController _departmentCtrl;

  String _selectedRole = 'User';
  String? _selectedManager;
  bool _isLoading = false;

  final Color _green = ThemeProvider.primaryBlue;

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController(text: widget.member.firstName);
    _lastNameCtrl = TextEditingController(text: widget.member.lastName);
    _workEmailCtrl = TextEditingController(text: widget.member.workEmail);
    _mobileNumberCtrl = TextEditingController(
      text: extractIndianPhoneDigits(widget.member.mobileNumber),
    );
    _designationCtrl = TextEditingController(
      text: widget.member.designation ?? '',
    );
    _departmentCtrl = TextEditingController(
      text: widget.member.department ?? '',
    );

    _selectedRole = widget.member.role;
    _selectedManager = widget.member.manager;
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _workEmailCtrl.dispose();
    _mobileNumberCtrl.dispose();
    _designationCtrl.dispose();
    _departmentCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_firstNameCtrl.text.isEmpty || _lastNameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('First name and last name are required')),
      );
      return;
    }

    final mobileError = indianPhoneValidationMessage(
      _mobileNumberCtrl.text.trim(),
    );
    if (mobileError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mobileError)));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updateData = {
        'firstName': _firstNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        'workEmail': _workEmailCtrl.text.trim(),
        'mobileNumber': _mobileNumberCtrl.text.trim(),
        'designation': _designationCtrl.text.trim(),
        'department': _departmentCtrl.text.trim(),
        'role': _selectedRole,
        'manager': _selectedManager,
      };

      final success = await context
          .read<AuthProvider>()
          .updateTeamMemberDetails(widget.member.id, updateData);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Team member updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          final auth = context.read<AuthProvider>();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(auth.errorMessage ?? 'Failed to update member'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allUsers = context.watch<UserProvider>().users;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Team Member'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // First Name & Last Name Row
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: 'First Name',
                    controller: _firstNameCtrl,
                    hint: 'Enter first name',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    label: 'Last Name',
                    controller: _lastNameCtrl,
                    hint: 'Enter last name',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Work Email
            _buildTextField(
              label: 'Work Email',
              controller: _workEmailCtrl,
              hint: 'Enter work email',
              keyboardType: TextInputType.emailAddress,
              readOnly: true, // Email usually not changeable
            ),
            const SizedBox(height: 20),

            // Mobile Number
            _buildTextField(
              label: 'Mobile Number',
              controller: _mobileNumberCtrl,
              hint: '9876543210',
              keyboardType: TextInputType.phone,
              isPhone: true,
            ),
            const SizedBox(height: 20),

            // Role Dropdown
            _buildLabel('Role'),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: _green),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: _selectedRole,
                isExpanded: true,
                underline: const SizedBox(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                items: ['User', 'Manager', 'Admin']
                    .map(
                      (role) =>
                          DropdownMenuItem(value: role, child: Text(role)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedRole = value);
                  }
                },
              ),
            ),
            const SizedBox(height: 20),

            // Reporting Manager Dropdown
            _buildLabel('Reporting Manager'),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: _green),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String?>(
                value: _selectedManager,
                isExpanded: true,
                underline: const SizedBox(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Select Reporting Manager'),
                  ),
                  ...allUsers.map((user) {
                    final displayName = '${user.firstName} ${user.lastName}';
                    return DropdownMenuItem(
                      value: displayName,
                      child: Text(displayName),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() => _selectedManager = value);
                },
              ),
            ),
            const SizedBox(height: 20),

            // Designation & Department Row
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: 'Designation',
                    controller: _designationCtrl,
                    hint: 'e.g. Senior Engineer',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    label: 'Department',
                    controller: _departmentCtrl,
                    hint: 'e.g. Engineering',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
                onPressed: _isLoading ? null : _saveChanges,
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Cancel Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: _green),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _green,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    bool isPhone = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        TextField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          inputFormatters: isPhone ? indianPhoneInputFormatters() : null,
          decoration: isPhone
              ? buildIndianPhoneDecoration(
                  context,
                  decoration: InputDecoration(
                    hintText: hint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: _green),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: _green.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: _green),
                    ),
                    filled: readOnly,
                    fillColor: readOnly
                        ? _green.withOpacity(0.05)
                        : Colors.transparent,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                )
              : InputDecoration(
                  hintText: hint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: _green),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: _green.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: _green),
                  ),
                  filled: readOnly,
                  fillColor: readOnly
                      ? _green.withOpacity(0.05)
                      : Colors.transparent,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}
