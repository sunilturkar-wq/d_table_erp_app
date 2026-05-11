import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../model/user_model.dart';
import '../../provider/user_provider.dart';
import '../../services/team_service.dart';

class CreateTeamDialog extends StatefulWidget {
  final VoidCallback onSuccess;
  const CreateTeamDialog({Key? key, required this.onSuccess}) : super(key: key);

  @override
  State<CreateTeamDialog> createState() => _CreateTeamDialogState();
}

class _CreateTeamDialogState extends State<CreateTeamDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  
  List<Map<String, String>> _selectedMembers = [];
  bool _isLoading = false;

  void _addMember() {
    setState(() {
      _selectedMembers.add({'userId': '', 'role': 'TEAM MEMBER', 'reportsTo': ''});
    });
  }

  void _removeMember(int index) {
    setState(() {
      _selectedMembers.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnackbar('Team name is required');
      return;
    }
    
    for (var m in _selectedMembers) {
      if (m['userId'] == null || m['userId']!.isEmpty) {
        _showSnackbar('Please select a user for all members');
        return;
      }
      if (m['role'] != 'ADMIN' && m['role'] != 'MANAGER' && (m['reportsTo'] == null || m['reportsTo']!.isEmpty)) {
        _showSnackbar('Please select a Reporting Manager for all team members (except ADMIN/MANAGER)');
        return;
      }
    }

    setState(() => _isLoading = true);
    
    try {
      await TeamService().createTeam({
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'members': _selectedMembers.map((m) => {
          'userId': m['userId'],
          'role': m['role'],
          'reportsTo': m['reportsTo'] == 'Top Level' || m['reportsTo']!.isEmpty ? null : m['reportsTo']
        }).toList(),
      });
      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
        _showSnackbar('Team created successfully', isSuccess: true);
      }
    } catch (e) {
      if (mounted) _showSnackbar('Failed to create team: $e');
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
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final themeText = isDark ? Colors.white : const Color(0xFF1E293B);
    final surfaceColor = isDark ? const Color(0xFF243244) : Colors.white;
    final mutedSurface = isDark ? const Color(0xFF182433) : Colors.grey.shade50;
    final borderColor = isDark ? const Color(0xFF334155) : Colors.grey.shade200;
    final hintColor = isDark ? const Color(0xFF94A3B8) : Colors.grey;
    final users = context.read<UserProvider>().users;

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
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
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
                        Text('Create New Team', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: themeText)),
                        Text('Define your team structure', style: TextStyle(fontSize: 12, color: hintColor, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: hintColor),
                    onPressed: () => Navigator.pop(context),
                  )
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
                    // Team Info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: mutedSurface, borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Team Name'),
                          const SizedBox(height: 6),
                          _buildTextField(_nameController, "e.g., Marketing Squad, Backend Core"),
                          const SizedBox(height: 16),
                          _buildLabel('Team Description'),
                          const SizedBox(height: 6),
                          _buildTextField(_descController, "What is the purpose of this team?", maxLines: 3),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Members Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(LucideIcons.users, size: 18, color: Color(0xFF003366)),
                            const SizedBox(width: 8),
                            Text('Team Members', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: themeText)),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: _addMember,
                          icon: const Icon(Icons.add, size: 16, color: Colors.white),
                          label: const Text('Add Member', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF003366),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: Size.zero,
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Members List
                    if (_selectedMembers.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid), // Dart flutter has no dashed easily without package, defaulting solid 
                          borderRadius: BorderRadius.circular(16),
                          color: mutedSurface
                        ),
                        child: Column(
                          children: [
                            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: surfaceColor, shape: BoxShape.circle), child: Icon(LucideIcons.users, size: 24, color: hintColor)),
                            const SizedBox(height: 12),
                            Text('No members added yet.', style: TextStyle(color: hintColor, fontSize: 13)),
                            TextButton(onPressed: _addMember, child: const Text('Click here to add your first member', style: TextStyle(fontSize: 12, color: Color(0xFF003366), fontWeight: FontWeight.bold)))
                          ],
                        ),
                      )
                    else
                      ..._selectedMembers.asMap().entries.map((e) {
                        int i = e.key;
                        Map<String, String> m = e.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: borderColor),
                            borderRadius: BorderRadius.circular(12),
                            color: mutedSurface
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('MEMBER #${i + 1}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF003366), letterSpacing: 1.2)),
                                  GestureDetector(
                                    onTap: () => _removeMember(i),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(color: isDark ? const Color(0xFF3F1D24) : Colors.red.shade50, borderRadius: BorderRadius.circular(6)),
                                      child: const Icon(LucideIcons.trash2, size: 14, color: Colors.redAccent)
                                    )
                                  )
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildLabel('Assign User'),
                              const SizedBox(height: 6),
                              _buildUserDropdown(users, m['userId']!, (v) => setState(() => m['userId'] = v!)),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildLabel('Team Role'),
                                        const SizedBox(height: 6),
                                        _buildRoleDropdown(m['role']!, (v) => setState(() => m['role'] = v!)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildLabel('Reports To'),
                                        const SizedBox(height: 6),
                                        _buildManagerDropdown(users.where((u) => u.id != m['userId']).toList(), m['reportsTo']!, (v) => setState(() => m['reportsTo'] = v!)),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        );
                      }).toList(),
                  ],
                ),
              ),
            ),
            
            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: mutedSurface,
                border: Border(top: BorderSide(color: borderColor)),
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20))
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Discard', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003366),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isLoading 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Initialize Team', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFCBD5E1) : Colors.grey, letterSpacing: 0.5));
  }

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF243244) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : Colors.grey.shade200;
    final hintColor = isDark ? const Color(0xFF94A3B8) : Colors.grey.shade400;
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black87),
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
    );
  }

  Widget _buildUserDropdown(List<UserModel> users, String current, Function(String?) onChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF243244) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : Colors.grey.shade200;
    final hintColor = isDark ? const Color(0xFF94A3B8) : Colors.grey;
    final textColor = isDark ? Colors.white : Colors.black87;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: borderColor)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: surfaceColor,
          isExpanded: true,
          value: current.isEmpty ? null : current,
          hint: Text('Select User', style: TextStyle(fontSize: 13, color: hintColor)),
          items: users.map((u) => DropdownMenuItem(value: u.id, child: Text('${u.firstName} ${u.lastName} (${u.role})', style: TextStyle(fontSize: 13, color: textColor)))).toList(),
          onChanged: onChanged,
          icon: Icon(LucideIcons.chevronDown, size: 16, color: hintColor),
        ),
      ),
    );
  }

  Widget _buildRoleDropdown(String current, Function(String?) onChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF243244) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : Colors.grey.shade200;
    final hintColor = isDark ? const Color(0xFF94A3B8) : Colors.grey;
    final textColor = isDark ? Colors.white : Colors.black87;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: borderColor)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: surfaceColor,
          isExpanded: true,
          value: current.isEmpty ? 'TEAM MEMBER' : current,
          items: ['TEAM MEMBER', 'MANAGER', 'ADMIN'].map((r) => DropdownMenuItem(value: r, child: Text(r, style: TextStyle(fontSize: 12, color: textColor)))).toList(),
          onChanged: onChanged,
          icon: Icon(LucideIcons.chevronDown, size: 16, color: hintColor),
        ),
      ),
    );
  }

  Widget _buildManagerDropdown(List<UserModel> users, String current, Function(String?) onChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF243244) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : Colors.grey.shade200;
    final hintColor = isDark ? const Color(0xFF94A3B8) : Colors.grey;
    final textColor = isDark ? Colors.white : Colors.black87;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: borderColor)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: surfaceColor,
          isExpanded: true,
          value: current.isEmpty ? 'Top Level' : current,
          items: [
            DropdownMenuItem(value: 'Top Level', child: Text('Top Level', style: TextStyle(fontSize: 12, color: textColor))),
            ...users.map((u) => DropdownMenuItem(value: u.id, child: Text('${u.firstName} ${u.lastName}', style: TextStyle(fontSize: 12, color: textColor))))
          ],
          onChanged: onChanged,
          icon: Icon(LucideIcons.chevronDown, size: 16, color: hintColor),
        ),
      ),
    );
  }
}
