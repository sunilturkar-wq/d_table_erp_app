import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../provider/auth_provider.dart';
import '../../provider/roles_provider.dart';
import '../../provider/user_provider.dart';
import '../../model/user_model.dart';
import '../utils/phone_number_helper.dart';

class CreateMemberDialog extends StatefulWidget {
  final VoidCallback onSuccess;
  const CreateMemberDialog({Key? key, required this.onSuccess}) : super(key: key);

  @override
  State<CreateMemberDialog> createState() => _CreateMemberDialogState();
}

class _CreateMemberDialogState extends State<CreateMemberDialog> {
  final TextEditingController _fNameCtrl = TextEditingController();
  final TextEditingController _lNameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _mobileCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  final TextEditingController _desigCtrl = TextEditingController();
  final TextEditingController _deptCtrl = TextEditingController();
  final TextEditingController _customRoleCtrl = TextEditingController();

  String _selectedRole = "TEAM MEMBER";
  String _selectedManagerId = "";
  bool _taskAccess = true;
  bool _leaveAccess = true;
  bool _isLoading = false;

  List<dynamic> _roles = [];
  bool _isCustomRole = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchRoles();
      }
    });
  }

  Future<void> _fetchRoles() async {
    try {
      final rolesProvider = context.read<RolesProvider>();
      await rolesProvider.fetchAllRoles();
      final roles = rolesProvider.roles;
      final currentUser = context.read<AuthProvider>().currentUser;
      final isManager = currentUser?.role?.toUpperCase() == 'MANAGER';
      if (mounted) {
        setState(() {
          if (isManager) {
            _roles = roles.where((r) => r['name'].toString().toUpperCase() != 'ADMIN' && r['name'].toString().toUpperCase() != 'SUPERADMIN').toList();
          } else {
            _roles = roles;
          }
        });
      }
    } catch (e) {
      // Handle error gracefully silently or log
    }
  }

  Future<void> _submit() async {
    if (_fNameCtrl.text.isEmpty || _lNameCtrl.text.isEmpty || _emailCtrl.text.isEmpty) {
      _showSnackbar('Highlighted fields are required');
      return;
    }
    final mobileError = indianPhoneValidationMessage(_mobileCtrl.text.trim());
    if (mobileError != null) {
      _showSnackbar(mobileError);
      return;
    }

    String finalRole = _isCustomRole ? _customRoleCtrl.text.trim() : _selectedRole;
    if (finalRole.isEmpty) {
      _showSnackbar('Role is required');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // If custom role, create it first via API
      if (_isCustomRole && _customRoleCtrl.text.isNotEmpty) {
         try {
           final success = await context.read<RolesProvider>().createRole(
             name: finalRole,
             description: 'Created from team member dialog',
           );
           if (!success) {
             if (mounted) {
               _showSnackbar(
                 context.read<RolesProvider>().errorMessage ?? 'Failed to create custom role',
               );
             }
             return;
           }
         } catch(e) {
           final message = e.toString();
           if (!message.toLowerCase().contains('already exists')) {
             if (mounted) {
               _showSnackbar(message.replaceAll('Exception: ', ''));
             }
             return;
           }
         }
      }

      // Add Member via AuthProvider
      final success = await context.read<AuthProvider>().register(
        firstName: _fNameCtrl.text.trim(),
        lastName: _lNameCtrl.text.trim(),
        workEmail: _emailCtrl.text.trim(),
        mobileNumber: _mobileCtrl.text.trim(),
        password: _passCtrl.text.trim().isNotEmpty ? _passCtrl.text.trim() : "Welcome@123",
        role: finalRole,
        designation: _desigCtrl.text.trim(),
        department: _deptCtrl.text.trim(),
        reportingManagerId: _selectedManagerId,
        taskAccess: _taskAccess,
        leaveAccess: _leaveAccess,
      );
      if (success) {
        if (mounted) {
          Navigator.pop(context);
          widget.onSuccess();
          _showSnackbar('Member added successfully', isSuccess: true);
        }
      } else {
        if (mounted) {
          final err = context.read<AuthProvider>().errorMessage ?? 'Failed to add member';
          _showSnackbar(err);
        }
      }
    } catch (e) {
      if (mounted) _showSnackbar(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final themeText = isDark ? Colors.white : const Color(0xFF1E293B);
    final surfaceColor = isDark ? const Color(0xFF243244) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : Colors.grey.shade200;
    final hintColor = isDark ? const Color(0xFF94A3B8) : Colors.grey.shade400;
    final footerColor = isDark ? const Color(0xFF182433) : Colors.grey.shade50;
    final users = context.read<UserProvider>().users;
    final currentUserInfo = context.read<AuthProvider>().currentUser;
    final bool canAddCustomRole = !(currentUserInfo?.role?.toUpperCase() == 'MANAGER');

    return Dialog(
      backgroundColor: themeBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 800),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: borderColor))),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFF003366).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(LucideIcons.userPlus, color: Color(0xFF003366), size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Add New Team Member', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: themeText)),
                        Text('Create a new user account', style: TextStyle(fontSize: 12, color: hintColor, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                  IconButton(icon: Icon(Icons.close, color: hintColor), onPressed: () => Navigator.pop(context))
                ],
              ),
            ),
            
            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildInput('First Name', _fNameCtrl, req: true, hint: "E.g. Aashish")),
                        const SizedBox(width: 12),
                        Expanded(child: _buildInput('Last Name', _lNameCtrl, req: true, hint: "Yadav")),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInput('Work Email', _emailCtrl, req: true, hint: "example@company.com"),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildInput('Mobile Number', _mobileCtrl, hint: "9876543210", isPhone: true)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildInput('Password', _passCtrl, hint: "â€¢â€¢â€¢â€¢â€¢â€¢â€¢â€¢", helper: "Default: Welcome@123")),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Role
                    _buildLabel('Role'),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: borderColor)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          dropdownColor: surfaceColor,
                          isExpanded: true,
                          value: _isCustomRole ? 'Custom' : (_roles.map((e)=>e['name'].toString()).contains(_selectedRole) || _roles.isEmpty ? _selectedRole : null),
                          hint: Text("Select Role", style: TextStyle(fontSize: 13, color: hintColor)),
                          items: [
                            ..._roles.map((r) => DropdownMenuItem(value: r['name'].toString(), child: Text(r['name'].toString(), style: TextStyle(fontSize: 13, color: themeText)))),
                            if (_roles.isEmpty) ...[
                              DropdownMenuItem(value: 'TEAM MEMBER', child: Text('TEAM MEMBER', style: TextStyle(fontSize: 13, color: themeText))),
                              DropdownMenuItem(value: 'MANAGER', child: Text('MANAGER', style: TextStyle(fontSize: 13, color: themeText))),
                              DropdownMenuItem(value: 'ADMIN', child: Text('ADMIN', style: TextStyle(fontSize: 13, color: themeText))),
                            ],
                            if (canAddCustomRole) const DropdownMenuItem(value: 'Custom', child: Text('Custom Role...', style: TextStyle(fontSize: 13, color: Color(0xFF003366), fontWeight: FontWeight.bold))),
                          ],
                          onChanged: (val) {
                            if (val == 'Custom') {
                              setState(() => _isCustomRole = true);
                            } else {
                              setState(() {
                                _isCustomRole = false;
                                _selectedRole = val ?? "TEAM MEMBER";
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    if (_isCustomRole) ...[
                      const SizedBox(height: 8),
                      _buildInput('Custom Role Name', _customRoleCtrl, hint: "E.g., Senior Designer"),
                    ],
                    const SizedBox(height: 16),

                    // Manager
                    _buildLabel('Reporting Manager'),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: borderColor)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          dropdownColor: surfaceColor,
                          isExpanded: true,
                          value: _selectedManagerId.isEmpty ? null : _selectedManagerId,
                          hint: Text('Select Reporting Manager', style: TextStyle(fontSize: 13, color: hintColor)),
                          items: users.map((u) => DropdownMenuItem(value: u.id, child: Text('${u.firstName} ${u.lastName} (${u.role})', style: TextStyle(fontSize: 13, color: themeText)))).toList(),
                          onChanged: (val) => setState(() => _selectedManagerId = val ?? ""),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Designation & Department
                    Row(
                      children: [
                        Expanded(child: _buildInput('Designation', _desigCtrl, hint: "e.g., Software Engineer")),
                        const SizedBox(width: 12),
                        Expanded(child: _buildInput('Department', _deptCtrl, hint: "e.g., IT")),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Toggles
                    _buildToggleRow('Task Access', _taskAccess, (v) => setState(() => _taskAccess = v)),
                    const SizedBox(height: 16),
                    _buildToggleRow('Leave & Attendance Access', _leaveAccess, (v) => setState(() => _leaveAccess = v)),
                  ],
                ),
              ),
            ),
            
            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: footerColor, border: Border(top: BorderSide(color: borderColor)), borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Discard', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003366), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: _isLoading 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Add Team Member', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller, {bool req = false, String hint = "", String helper = "", bool isPhone = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF243244) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : Colors.grey.shade200;
    final hintColor = isDark ? const Color(0xFF94A3B8) : Colors.grey.shade400;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
          inputFormatters: isPhone ? indianPhoneInputFormatters() : null,
          style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black87),
          decoration: isPhone
              ? buildIndianPhoneDecoration(
                  context,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(color: hintColor, fontSize: 13),
                    filled: true,
                    fillColor: surfaceColor,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF003366))),
                  ),
                  hintText: hint,
                )
              : InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: hintColor, fontSize: 13),
            filled: true,
            fillColor: surfaceColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF003366))),
          ),
        ),
        if (helper.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(helper, style: TextStyle(fontSize: 10, color: hintColor)),
        ]
      ],
    );
  }

  Widget _buildLabel(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFCBD5E1) : Colors.grey));
  }

  Widget _buildToggleRow(String title, bool val, ValueChanged<bool> onChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        Switch(
          value: val, 
          onChanged: onChanged,
          activeColor: Colors.white,
          activeTrackColor: const Color(0xFF003366),
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: Colors.grey.shade300,
        )
      ],
    );
  }
}
