import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/auth_provider.dart';
import '../provider/theme_provider.dart';
import '../model/user_model.dart';
import '../utils/phone_number_helper.dart';

class PersonalProfilePanel extends StatefulWidget {
  final UserModel user;
  final VoidCallback onClose;
  final Color green;
  final AppColors appColors;

  const PersonalProfilePanel({
    required this.user,
    required this.onClose,
    required this.green,
    required this.appColors,
  });

  @override
  State<PersonalProfilePanel> createState() => _PersonalProfilePanelState();
}

class _PersonalProfilePanelState extends State<PersonalProfilePanel> {
  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;
  late TextEditingController _mobileCtrl;
  late TextEditingController _personalEmailCtrl;
  late TextEditingController _designationCtrl;
  late TextEditingController _departmentCtrl;
  late TextEditingController _dobCtrl;
  late TextEditingController _genderCtrl;
  late TextEditingController _maritalStatusCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _stateCtrl;
  late TextEditingController _nationalityCtrl;

  bool _isEditing = false;
  bool _isSaving = false;

  final Color _green = ThemeProvider.primaryBlue;

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController(text: widget.user.firstName);
    _lastNameCtrl = TextEditingController(text: widget.user.lastName);
    _mobileCtrl = TextEditingController(
      text: extractIndianPhoneDigits(widget.user.mobileNumber),
    );
    _personalEmailCtrl =
        TextEditingController(text: widget.user.personalEmail ?? '');
    _designationCtrl = TextEditingController(text: widget.user.designation);
    _departmentCtrl = TextEditingController(text: widget.user.department);
    _dobCtrl = TextEditingController(text: widget.user.dateOfBirth ?? '');
    _genderCtrl = TextEditingController(text: widget.user.gender ?? '');
    _maritalStatusCtrl =
        TextEditingController(text: widget.user.maritalStatus ?? '');
    _addressCtrl = TextEditingController(text: widget.user.address ?? '');
    _cityCtrl = TextEditingController(text: widget.user.city ?? '');
    _stateCtrl = TextEditingController(text: widget.user.state ?? '');
    _nationalityCtrl = TextEditingController(text: widget.user.nationality ?? '');
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _mobileCtrl.dispose();
    _personalEmailCtrl.dispose();
    _designationCtrl.dispose();
    _departmentCtrl.dispose();
    _dobCtrl.dispose();
    _genderCtrl.dispose();
    _maritalStatusCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _nationalityCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final mobileError = indianPhoneValidationMessage(_mobileCtrl.text.trim());
    if (mobileError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mobileError),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updateData = {
        'firstName': _firstNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        'mobileNumber': _mobileCtrl.text.trim(),
        'personalEmail': _personalEmailCtrl.text.trim(),
        'designation': _designationCtrl.text.trim(),
        'department': _departmentCtrl.text.trim(),
        'dateOfBirth': _dobCtrl.text.trim(),
        'gender': _genderCtrl.text.trim(),
        'maritalStatus': _maritalStatusCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'state': _stateCtrl.text.trim(),
        'nationality': _nationalityCtrl.text.trim(),
      };

      final success =
          await context.read<AuthProvider>().updateProfile(updateData);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() => _isEditing = false);
        } else {
          final auth = context.read<AuthProvider>();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(auth.errorMessage ?? 'Failed to update profile'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ac = widget.appColors;
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
              color: isDark ? ac.toolbarBackground : _green.withOpacity(0.06),
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
                Row(
                  children: [
                    if (_isEditing)
                      TextButton.icon(
                        onPressed: () {
                          setState(() => _isEditing = false);
                          _resetFields();
                        },
                        icon: const Icon(Icons.close),
                        label: const Text('Cancel'),
                      ),
                    if (!_isEditing)
                      TextButton.icon(
                        onPressed: () => setState(() => _isEditing = true),
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                      ),
                    IconButton(
                      icon: Icon(Icons.close, color: ac.textMuted),
                      onPressed: widget.onClose,
                    ),
                  ],
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
                    _buildField('First Name', _firstNameCtrl),
                    const SizedBox(height: 12),
                    _buildField('Last Name', _lastNameCtrl),
                    const SizedBox(height: 12),
                    _buildField('Mobile Number', _mobileCtrl, isPhone: true),
                    const SizedBox(height: 12),
                    _buildField('Gender', _genderCtrl),
                    const SizedBox(height: 12),
                    _buildField('Date of Birth', _dobCtrl),
                    const SizedBox(height: 12),
                    _buildField('Marital Status', _maritalStatusCtrl),
                  ]),
                  const SizedBox(height: 20),
                  _buildSection('Contact Information', [
                    _buildField('Personal Email', _personalEmailCtrl),
                    const SizedBox(height: 12),
                    _buildField('Address', _addressCtrl),
                    const SizedBox(height: 12),
                    _buildField('City', _cityCtrl),
                    const SizedBox(height: 12),
                    _buildField('State', _stateCtrl),
                    const SizedBox(height: 12),
                    _buildField('Nationality', _nationalityCtrl),
                  ]),
                  const SizedBox(height: 20),
                  _buildSection('Professional Information', [
                    _buildField('Designation', _designationCtrl),
                    const SizedBox(height: 12),
                    _buildField('Department', _departmentCtrl),
                  ]),
                  const SizedBox(height: 20),
                  if (_isEditing)
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _isSaving ? null : _saveChanges,
                            child: _isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Save Changes',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _resetFields() {
    _firstNameCtrl.text = widget.user.firstName;
    _lastNameCtrl.text = widget.user.lastName;
    _mobileCtrl.text = extractIndianPhoneDigits(widget.user.mobileNumber);
    _personalEmailCtrl.text = widget.user.personalEmail ?? '';
    _designationCtrl.text = widget.user.designation;
    _departmentCtrl.text = widget.user.department;
    _dobCtrl.text = widget.user.dateOfBirth ?? '';
    _genderCtrl.text = widget.user.gender ?? '';
    _maritalStatusCtrl.text = widget.user.maritalStatus ?? '';
    _addressCtrl.text = widget.user.address ?? '';
    _cityCtrl.text = widget.user.city ?? '';
    _stateCtrl.text = widget.user.state ?? '';
    _nationalityCtrl.text = widget.user.nationality ?? '';
  }

  Widget _buildSection(String title, List<Widget> fields) {
    final ac = widget.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: _green,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: _green.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: fields,
          ),
        ),
      ],
    );
  }

  Widget _buildField(String label, TextEditingController controller, {bool isPhone = false}) {
    final ac = widget.appColors;
    return Column(
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
        TextField(
          controller: controller,
          readOnly: !_isEditing,
          keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
          inputFormatters: isPhone ? indianPhoneInputFormatters() : null,
          decoration: isPhone
              ? buildIndianPhoneDecoration(
                  context,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                        color: _green.withOpacity(0.2),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                        color: _green.withOpacity(0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: _green),
                    ),
                    filled: !_isEditing,
                    fillColor:
                        !_isEditing ? _green.withOpacity(0.05) : Colors.transparent,
                  ),
                )
              : InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: _green.withOpacity(0.2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: _green.withOpacity(0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: _green),
            ),
            filled: !_isEditing,
            fillColor: !_isEditing ? _green.withOpacity(0.05) : Colors.transparent,
          ),
          style: TextStyle(color: ac.textPrimary, fontSize: 14),
        ),
      ],
    );
  }
}
