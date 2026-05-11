import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/user_model.dart';
import '../../services/auth_service.dart';
import '../../provider/auth_provider.dart';
import '../../provider/roles_provider.dart';
import '../../provider/user_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../utils/phone_number_helper.dart';

void showSnackbar(BuildContext context, String msg, {bool isSuccess = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: isSuccess ? Colors.green : Colors.red,
    )
  );
}

// -------------------------------------------------------------
// UPDATE CREDENTIALS DIALOG
// -------------------------------------------------------------
class UpdateCredentialsDialog extends StatefulWidget {
  final UserModel member;
  final VoidCallback onSuccess;
  const UpdateCredentialsDialog({Key? key, required this.member, required this.onSuccess}) : super(key: key);

  @override
  State<UpdateCredentialsDialog> createState() => _UpdateCredentialsDialogState();
}

class _UpdateCredentialsDialogState extends State<UpdateCredentialsDialog> {
  String? _mode;
  late TextEditingController _emailCtrl;
  final TextEditingController _oldPassCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  final TextEditingController _confirmPassCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.member.workEmail);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _oldPassCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_mode == null) {
      showSnackbar(context, "Please choose what you want to update");
      return;
    }
    if (_oldPassCtrl.text.trim().isEmpty) {
      showSnackbar(context, "Current password is required");
      return;
    }
    if ((_mode == 'password' || _mode == 'both') &&
        _passCtrl.text != _confirmPassCtrl.text) {
      showSnackbar(context, "New passwords do not match");
      return;
    }
    if ((_mode == 'email' || _mode == 'both') &&
        _emailCtrl.text.trim().isEmpty) {
      showSnackbar(context, "New email is required");
      return;
    }
    if ((_mode == 'password' || _mode == 'both') &&
        _passCtrl.text.trim().isEmpty) {
      showSnackbar(context, "New password is required");
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService().updateCredentials(widget.member.id, {
        'oldPassword': _oldPassCtrl.text.trim(),
        'newEmail': (_mode == 'email' || _mode == 'both')
            ? _emailCtrl.text.trim()
            : null,
        'newPassword': (_mode == 'password' || _mode == 'both')
            ? _passCtrl.text.trim()
            : null,
      });
      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
        showSnackbar(context, "Credentials updated successfully", isSuccess: true);
      }
    } catch (e) {
      if (mounted) showSnackbar(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Update Credentials", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: _mode,
            decoration: const InputDecoration(labelText: "What do you want to update?"),
            items: const [
              DropdownMenuItem(value: 'email', child: Text('Email')),
              DropdownMenuItem(value: 'password', child: Text('Password')),
              DropdownMenuItem(value: 'both', child: Text('Both')),
            ],
            onChanged: (value) => setState(() => _mode = value),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _oldPassCtrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: "Current Password"),
          ),
          if (_mode == 'email' || _mode == 'both') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: "New Work Email"),
            ),
          ],
          if (_mode == 'password' || _mode == 'both') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _passCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: "New Password"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPassCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Confirm Password"),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003366)),
          child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Update", style: TextStyle(color: Colors.white)),
        )
      ],
    );
  }
}

// -------------------------------------------------------------
// DELETE TASKS DIALOG
// -------------------------------------------------------------
class DeleteTasksDialog extends StatefulWidget {
  final UserModel member;
  final VoidCallback onSuccess;
  const DeleteTasksDialog({Key? key, required this.member, required this.onSuccess}) : super(key: key);

  @override
  State<DeleteTasksDialog> createState() => _DeleteTasksDialogState();
}

class _DeleteTasksDialogState extends State<DeleteTasksDialog> {
  final TextEditingController _emailCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_emailCtrl.text.trim().isEmpty) {
      showSnackbar(context, "Please enter the member email to confirm");
      return;
    }
    if (_emailCtrl.text.trim() != widget.member.workEmail) {
      showSnackbar(context, "Confirmation email does not match");
      return;
    }
    setState(() => _isLoading = true);
    try {
      await AuthService().deleteUserTasks(widget.member.id, _emailCtrl.text.trim());
      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
        showSnackbar(context, "All tasks deleted successfully", isSuccess: true);
      }
    } catch (e) {
      if (mounted) showSnackbar(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Delete All Tasks", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("This action will permanently delete all tasks associated with ${widget.member.fullName}.", style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 12),
          TextField(
            controller: _emailCtrl,
            decoration: InputDecoration(
              labelText: "Confirm member email",
              hintText: widget.member.workEmail,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Delete All Tasks", style: TextStyle(color: Colors.white)),
        )
      ],
    );
  }
}

// -------------------------------------------------------------
// DELETE USER DIALOG
// -------------------------------------------------------------
class DeleteUserDialog extends StatefulWidget {
  final UserModel member;
  final VoidCallback onSuccess;
  const DeleteUserDialog({Key? key, required this.member, required this.onSuccess}) : super(key: key);

  @override
  State<DeleteUserDialog> createState() => _DeleteUserDialogState();
}

class _DeleteUserDialogState extends State<DeleteUserDialog> {
  bool _isLoading = false;

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      final success = await context.read<AuthProvider>().deleteUser(widget.member.id);
      if (success) {
        if (mounted) {
          Navigator.pop(context);
          widget.onSuccess();
          showSnackbar(context, "User deleted successfully", isSuccess: true);
        }
      } else {
         if (mounted) showSnackbar(context, context.read<AuthProvider>().errorMessage ?? "Failed to delete user");
      }
    } catch (e) {
      if (mounted) showSnackbar(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("DELETE USER", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.red, fontStyle: FontStyle.italic)),
      content: Text("Are you sure you want to permanently delete ${widget.member.fullName}? This action cannot be undone.", style: const TextStyle(fontSize: 13)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("DELETE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        )
      ],
    );
  }
}

// -------------------------------------------------------------
// UPDATE MEMBER DIALOG (Simplified Version of CreateMemberDialog)
// -------------------------------------------------------------
class UpdateMemberDialog extends StatefulWidget {
  final UserModel member;
  final VoidCallback onSuccess;
  const UpdateMemberDialog({Key? key, required this.member, required this.onSuccess}) : super(key: key);

  @override
  State<UpdateMemberDialog> createState() => _UpdateMemberDialogState();
}

class _UpdateMemberDialogState extends State<UpdateMemberDialog> {
  late TextEditingController _fNameCtrl;
  late TextEditingController _lNameCtrl;
  late TextEditingController _mobileCtrl;
  late TextEditingController _desigCtrl;
  late TextEditingController _deptCtrl;
  final TextEditingController _customRoleCtrl = TextEditingController();

  late String _selectedRole;
  late String _selectedManagerId;
  bool _taskAccess = true;
  bool _leaveAccess = true;
  bool _isLoading = false;
  bool _isCustomRole = false;
  List<dynamic> _roles = [];

  @override
  void initState() {
    super.initState();
    _fNameCtrl = TextEditingController(text: widget.member.firstName);
    _lNameCtrl = TextEditingController(text: widget.member.lastName);
    _mobileCtrl = TextEditingController(
      text: extractIndianPhoneDigits(widget.member.mobileNumber),
    );
    _desigCtrl = TextEditingController(text: widget.member.designation);
    _deptCtrl = TextEditingController(text: widget.member.department);
    _selectedRole = widget.member.role.isNotEmpty ? widget.member.role : "TEAM MEMBER";
    _selectedManagerId = widget.member.reportingManagerId ?? "";
    _taskAccess = widget.member.taskAccess != false;
    _leaveAccess = widget.member.leaveAccess != false;
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
      final currentUser = context.read<AuthProvider>().currentUser;
      final isManager = currentUser?.role.toUpperCase() == 'MANAGER';
      final roles = rolesProvider.roles;
      if (!mounted) return;
      setState(() {
        _roles = isManager
            ? roles
                .where((r) =>
                    !['ADMIN', 'SUPERADMIN']
                        .contains(r['name'].toString().toUpperCase()))
                .toList()
            : roles;
      });
    } catch (_) {
      // Keep fallback role list below working.
    }
  }

  @override
  void dispose() {
    _fNameCtrl.dispose();
    _lNameCtrl.dispose();
    _mobileCtrl.dispose();
    _desigCtrl.dispose();
    _deptCtrl.dispose();
    _customRoleCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    String finalRole = _isCustomRole ? _customRoleCtrl.text.trim() : _selectedRole;
    if (finalRole.isEmpty) {
      showSnackbar(context, "Role is required");
      return;
    }
    final mobileError = indianPhoneValidationMessage(_mobileCtrl.text.trim());
    if (mobileError != null) {
      showSnackbar(context, mobileError);
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isCustomRole && _customRoleCtrl.text.trim().isNotEmpty) {
        final rolesProvider = context.read<RolesProvider>();
        final created = await rolesProvider.createRole(
          name: finalRole,
          description: 'Created from team member update dialog',
        );
        if (!created &&
            !(rolesProvider.errorMessage ?? '')
                .toLowerCase()
                .contains('already exists')) {
          if (mounted) {
            showSnackbar(
              context,
              rolesProvider.errorMessage ?? 'Failed to create custom role',
            );
          }
          return;
        }
      }

      final success = await context.read<AuthProvider>().updateTeamMemberDetails(widget.member.id, {
        "firstName": _fNameCtrl.text,
        "lastName": _lNameCtrl.text,
        "mobileNumber": _mobileCtrl.text,
        "role": finalRole,
        "designation": _desigCtrl.text,
        "department": _deptCtrl.text,
        "reportingManagerId":
            _selectedManagerId.trim().isEmpty ? null : _selectedManagerId.trim(),
        "taskAccess": _taskAccess,
        "leaveAccess": _leaveAccess,
      });
      if (success) {
        if (mounted) {
          Navigator.pop(context);
          widget.onSuccess();
          showSnackbar(context, "Member updated successfully", isSuccess: true);
        }
      } else {
        if (mounted) showSnackbar(context, "Update failed");
      }
    } catch (e) {
      if (mounted) showSnackbar(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final users = context
        .read<UserProvider>()
        .users
        .where((u) => u.id != widget.member.id)
        .toList();
    final currentUser = context.read<AuthProvider>().currentUser;
    final bool canAddCustomRole =
        currentUser?.role.toUpperCase() != 'MANAGER';
    final roleItems = _roles.isNotEmpty
        ? _roles.map((r) => r['name'].toString()).toList()
        : ['TEAM MEMBER', 'MANAGER', 'ADMIN', 'SUPERADMIN'];

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      title: const Text("Edit Member", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      content: SizedBox(
        width: screenWidth > 600 ? 520 : screenWidth * 0.88,
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _fNameCtrl, decoration: const InputDecoration(labelText: "First Name")),
            const SizedBox(height: 12),
            TextField(controller: _lNameCtrl, decoration: const InputDecoration(labelText: "Last Name")),
            const SizedBox(height: 12),
            TextField(
              controller: _mobileCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: indianPhoneInputFormatters(),
              decoration: buildIndianPhoneDecoration(
                context,
                decoration: const InputDecoration(labelText: "Mobile Number"),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: _isCustomRole
                  ? 'Custom'
                  : (roleItems.contains(_selectedRole) ? _selectedRole : null),
              items: [
                ...roleItems
                    .map(
                      (r) => DropdownMenuItem(
                        value: r,
                        child: Text(
                          r,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                if (canAddCustomRole)
                  const DropdownMenuItem(
                    value: 'Custom',
                    child: Text('Custom Role...'),
                  ),
              ],
              onChanged: (v) {
                if (v == 'Custom') {
                  setState(() => _isCustomRole = true);
                  return;
                }
                setState(() {
                  _isCustomRole = false;
                  _selectedRole = v ?? 'TEAM MEMBER';
                });
              },
              decoration: const InputDecoration(labelText: "Role"),
            ),
            if (_isCustomRole) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customRoleCtrl,
                decoration: const InputDecoration(labelText: "Custom Role Name"),
              ),
            ],
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: _selectedManagerId.isEmpty ? null : _selectedManagerId,
              items: users
                  .map(
                    (u) => DropdownMenuItem(
                      value: u.id,
                      child: Text(
                        '${u.firstName} ${u.lastName} (${u.role})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _selectedManagerId = v ?? ''),
              decoration:
                  const InputDecoration(labelText: "Reporting Manager"),
            ),
            const SizedBox(height: 12),
            TextField(controller: _desigCtrl, decoration: const InputDecoration(labelText: "Designation")),
            const SizedBox(height: 12),
            TextField(controller: _deptCtrl, decoration: const InputDecoration(labelText: "Department")),
            const SizedBox(height: 16),
            SwitchListTile(
              value: _taskAccess,
              onChanged: (value) => setState(() => _taskAccess = value),
              contentPadding: EdgeInsets.zero,
              title: const Text("Task Access"),
              activeColor: const Color(0xFF003366),
            ),
            SwitchListTile(
              value: _leaveAccess,
              onChanged: (value) => setState(() => _leaveAccess = value),
              contentPadding: EdgeInsets.zero,
              title: const Text("Leave & Attendance Access"),
              activeColor: const Color(0xFF003366),
            ),
          ],
        ),
      ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003366)),
          child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Save Changes", style: TextStyle(color: Colors.white)),
        )
      ],
    );
  }
}
