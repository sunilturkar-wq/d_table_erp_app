import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../provider/auth_provider.dart';
import '../../utils/phone_number_helper.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final List<Map<String, dynamic>> _usersInput = [];
  bool _isSubmitting = false;

  final List<String> _roles = ['ADMIN', 'User'];

  @override
  void initState() {
    super.initState();
    _addRow();
  }

  void _addRow() {
    setState(() {
      _usersInput.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
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

  void _removeRow(String id) {
    if (_usersInput.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one user is required')),
      );
      return;
    }
    setState(() {
      _usersInput.removeWhere((user) => user['id'] == id);
    });
  }

  void _updateField(String id, String field, String value) {
    setState(() {
      final user = _usersInput.firstWhere((element) => element['id'] == id);
      user[field] = value;
    });
  }

  Future<void> _handleSubmit() async {
    // Basic validation
    final invalidUser = _usersInput.any(
      (user) =>
          user['firstName'] == '' ||
          user['workEmail'] == '' ||
          user['password'] == '',
    );

    if (invalidUser) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill First Name, Work Email, and Password for all.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final invalidPhoneUser = _usersInput.any(
      (user) => !isValidIndianPhone(user['mobileNumber']?.toString()),
    );
    if (invalidPhoneUser) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('If entered, mobile number must be exactly 10 digits'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authService = AuthService();
      // Remove local UI 'id' before sending
      final payload = _usersInput.map((u) {
        final map = Map<String, dynamic>.from(u);
        map.remove('id');
        return map;
      }).toList();

      final res = await authService.bulkRegister(payload);

      if (!mounted) return;

      final results = res['results'];
      if (results != null) {
        final successCount = (results['success'] as List).length;
        final failCount = (results['failed'] as List).length;

        if (successCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully added $successCount users!'),
              backgroundColor: Colors.green,
            ),
          );
          if (failCount == 0) {
            setState(() {
              _usersInput.clear();
              _addRow();
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to add $failCount users. Check details.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to add users. Please check data.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "ADD MULTIPLE USERS",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        backgroundColor: const Color(0xFF003366),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isSubmitting ? null : _addRow,
                icon: const Icon(Icons.add, color: Color(0xFF003366)),
                label: const Text(
                  'Add Row',
                  style: TextStyle(color: Color(0xFF003366)),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF003366)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _handleSubmit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save, color: Colors.white),
                label: const Text(
                  'Save All',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003366),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: _usersInput.length,
        itemBuilder: (context, index) {
          final user = _usersInput[index];
          final uId = user['id'];
          return Card(
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'User ${index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () => _removeRow(uId),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          'First Name *',
                          user['firstName'],
                          (v) => _updateField(uId, 'firstName', v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          'Last Name',
                          user['lastName'],
                          (v) => _updateField(uId, 'lastName', v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildTextField(
                          'Work Email *',
                          user['workEmail'],
                          (v) => _updateField(uId, 'workEmail', v),
                          keyboard: TextInputType.emailAddress,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Role',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: user['role'],
                                  items: _roles
                                      .map(
                                        (r) => DropdownMenuItem(
                                          value: r,
                                          child: Text(
                                            r,
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) =>
                                      _updateField(uId, 'role', v!),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          'Temporary Password *',
                          user['password'],
                          (v) => _updateField(uId, 'password', v),
                          obscureText: false,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          'Mobile No.',
                          user['mobileNumber'],
                          (v) => _updateField(uId, 'mobileNumber', v),
                          keyboard: TextInputType.phone,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          'Designation',
                          user['designation'],
                          (v) => _updateField(uId, 'designation', v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          'Department',
                          user['department'],
                          (v) => _updateField(uId, 'department', v),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String value,
    Function(String) onChanged, {
    TextInputType keyboard = TextInputType.text,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 6),
        SizedBox(
          height: 40,
          child: TextFormField(
            initialValue: keyboard == TextInputType.phone
                ? extractIndianPhoneDigits(value)
                : value,
            onChanged: onChanged,
            keyboardType: keyboard,
            inputFormatters: keyboard == TextInputType.phone
                ? indianPhoneInputFormatters()
                : null,
            obscureText: obscureText,
            style: const TextStyle(fontSize: 13),
            decoration: keyboard == TextInputType.phone
                ? buildIndianPhoneDecoration(
                    context,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF003366)),
                      ),
                    ),
                  )
                : InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF003366)),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
