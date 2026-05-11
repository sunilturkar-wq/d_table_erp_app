import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../provider/user_provider.dart';
import '../../utils/phone_number_helper.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({Key? key}) : super(key: key);

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _addRow();
  }

  void _addRow() {
    setState(() {
      _users.add({
        'id': DateTime.now().millisecondsSinceEpoch,
        'firstName': '',
        'lastName': '',
        'workEmail': '',
        'password': '',
        'mobileNumber': '',
        'role': 'User',
        'designation': '',
        'department': '',
      });
    });
  }

  void _removeRow(int id) {
    if (_users.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least one user is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() {
      _users.removeWhere((u) => u['id'] == id);
    });
  }

  void _handleChange(int id, String field, String value) {
    final index = _users.indexWhere((u) => u['id'] == id);
    if (index != -1) {
      _users[index][field] = value;
    }
  }

  Future<void> _submit() async {
    // Validation
    final invalidUser = _users.any(
      (u) =>
          (u['firstName'] as String).isEmpty ||
          (u['workEmail'] as String).isEmpty ||
          (u['password'] as String).isEmpty,
    );
    if (invalidUser) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill First Name, Work Email and Password for all rows',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final invalidPhoneUser = _users.any(
      (u) => !isValidIndianPhone(u['mobileNumber']?.toString()),
    );
    if (invalidPhoneUser) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('If entered, mobile number must be exactly 10 digits'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final List<Map<String, dynamic>> payload = _users.map((u) {
        final map = Map<String, dynamic>.from(u);
        map.remove('id'); // Remove local UI id
        return map;
      }).toList();

      final res = await AuthService().bulkRegister(payload);

      int successCount = 0;
      int failCount = 0;
      List<dynamic> failedList = [];

      if (res['results'] != null) {
        successCount = (res['results']['success'] as List?)?.length ?? 0;
        failedList = res['results']['failed'] ?? [];
        failCount = failedList.length;
      }

      if (!mounted) return;

      if (successCount > 0) {
        if (failCount == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully added $successCount users!'),
              backgroundColor: Colors.green,
            ),
          );
          context.read<UserProvider>().fetchUsers();
          Navigator.pop(context, true); // Go back to team screen
        } else {
          // Partial success
          String fails = failedList
              .map((f) => '${f['email']}: ${f['reason']}')
              .join('\n');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added $successCount, Failed $failCount:\n$fails'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
          // Keep failed rows
          final failedEmails = failedList
              .map((f) => f['email'].toString())
              .toList();
          setState(() {
            _users.retainWhere((u) => failedEmails.contains(u['workEmail']));
          });
          context
              .read<UserProvider>()
              .fetchUsers(); // Refresh for the successful ones
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add users. Please check your data.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textC = isDark ? Colors.white : const Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF12161B) : Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          "Add Multiple Users",
          style: TextStyle(color: textC, fontWeight: FontWeight.bold),
        ),
        backgroundColor: bg,
        elevation: 0,
        iconTheme: IconThemeData(color: textC),
        actions: [
          TextButton.icon(
            onPressed: _addRow,
            icon: const Icon(
              LucideIcons.plus,
              color: Color(0xFF003366),
              size: 18,
            ),
            label: const Text(
              "Row",
              style: TextStyle(
                color: Color(0xFF003366),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 24),
                  elevation: 4,
                  shadowColor: Colors.black12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  color: bg,
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.grey.shade50,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          border: Border(
                            bottom: BorderSide(
                              color: isDark
                                  ? Colors.white10
                                  : Colors.grey.shade200,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: const Color(0xFF003366),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "USER DETAILS",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: textC,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(
                                LucideIcons.trash2,
                                size: 18,
                                color: Colors.red,
                              ),
                              onPressed: () => _removeRow(user['id']),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                      // Fields
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInput(
                                    'First Name',
                                    user['firstName'],
                                    (val) => _handleChange(
                                      user['id'],
                                      'firstName',
                                      val,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildInput(
                                    'Last Name',
                                    user['lastName'],
                                    (val) => _handleChange(
                                      user['id'],
                                      'lastName',
                                      val,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildInput(
                              'Work Email',
                              user['workEmail'],
                              (val) =>
                                  _handleChange(user['id'], 'workEmail', val),
                              icon: LucideIcons.mail,
                              type: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInput(
                                    'Mobile No',
                                    user['mobileNumber'],
                                    (val) => _handleChange(
                                      user['id'],
                                      'mobileNumber',
                                      val,
                                    ),
                                    icon: LucideIcons.phone,
                                    type: TextInputType.phone,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildInput(
                                    'Password',
                                    user['password'],
                                    (val) => _handleChange(
                                      user['id'],
                                      'password',
                                      val,
                                    ),
                                    icon: LucideIcons.lock,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildDropdown(
                              'Role',
                              user['role'],
                              ['ADMIN', 'MANAGER', 'TEAM MEMBER', 'User'],
                              (val) => _handleChange(user['id'], 'role', val!),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInput(
                                    'Designation',
                                    user['designation'],
                                    (val) => _handleChange(
                                      user['id'],
                                      'designation',
                                      val,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildInput(
                                    'Department',
                                    user['department'],
                                    (val) => _handleChange(
                                      user['id'],
                                      'department',
                                      val,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Bottom Bar
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: bg,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(LucideIcons.save, color: Colors.white),
                label: const Text(
                  "Save All Users",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003366),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(
    String label,
    String value,
    Function(String) onChanged, {
    IconData? icon,
    TextInputType? type,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1,
            ),
          ),
        ),
        TextFormField(
          initialValue: type == TextInputType.phone
              ? extractIndianPhoneDigits(value)
              : value,
          onChanged: onChanged,
          keyboardType: type,
          inputFormatters: type == TextInputType.phone
              ? indianPhoneInputFormatters()
              : null,
          style: const TextStyle(fontSize: 13),
          decoration: type == TextInputType.phone
              ? buildIndianPhoneDecoration(
                  context,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF12161B)
                        : Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white10 : Colors.grey.shade200,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white10 : Colors.grey.shade200,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF003366)),
                    ),
                  ),
                )
              : InputDecoration(
                  prefixIcon: icon != null
                      ? Icon(icon, size: 16, color: Colors.grey)
                      : null,
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF12161B)
                      : Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white10 : Colors.grey.shade200,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white10 : Colors.grey.shade200,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF003366)),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    if (!items.contains(value)) items.add(value); // Safety fallback
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1,
            ),
          ),
        ),
        DropdownButtonFormField<String>(
          value: value,
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e, style: const TextStyle(fontSize: 13)),
                ),
              )
              .toList(),
          onChanged: onChanged,
          icon: const Icon(
            LucideIcons.chevronDown,
            size: 16,
            color: Colors.grey,
          ),
          decoration: InputDecoration(
            prefixIcon: const Icon(
              LucideIcons.userCircle,
              size: 16,
              color: Colors.grey,
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF12161B) : Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.white10 : Colors.grey.shade200,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.white10 : Colors.grey.shade200,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF003366)),
            ),
          ),
        ),
      ],
    );
  }
}
