import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../provider/auth_provider.dart';
import '../../../utils/phone_number_helper.dart';
import '../../../widget/app_dropdown.dart';

// ✅ New Backend: Register requires ADMIN/MANAGER token
// This screen is now only accessible by logged-in Admins/Managers to add new users.
// Self-signup is NOT supported by the new backend (erprld.com/api).
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final mobileController = TextEditingController();
  final designationController = TextEditingController();
  final departmentController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  String _selectedRole = 'User';
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    mobileController.dispose();
    designationController.dispose();
    departmentController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF003366);
    final authProvider = context.read<AuthProvider>();

    // ⚠️ If user is not authenticated (ajeeb case), show info screen
    if (!authProvider.isAuthenticated) {
      return _buildNotAvailableScreen(context, primaryColor);
    }

    // ⚠️ Only Admin/Manager can access this screen
    final isAdminOrManager =
        authProvider.isAdmin ||
        (authProvider.currentUser?.role?.toUpperCase() == 'MANAGER') ||
        (authProvider.currentUser?.role?.toUpperCase() == 'SUPERADMIN');

    if (!isAdminOrManager) {
      return _buildNotAvailableScreen(context, primaryColor);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with Gradient
            Container(
              height: MediaQuery.of(context).size.height * 0.22,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [primaryColor, primaryColor.withOpacity(0.8)],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(80),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Add New User',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Admin / Manager Access',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: firstNameController,
                            label: 'First Name',
                            hint: 'John',
                            icon: Icons.person_outline,
                            primaryColor: primaryColor,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildTextField(
                            controller: lastNameController,
                            label: 'Last Name',
                            hint: 'Doe',
                            icon: Icons.person_outline,
                            primaryColor: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      controller: emailController,
                      label: 'Work Email',
                      hint: 'name@company.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      primaryColor: primaryColor,
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      controller: mobileController,
                      label: 'Mobile Number',
                      hint: '9876543210',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      primaryColor: primaryColor,
                      isRequired: false,
                      isPhone: true,
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: designationController,
                            label: 'Designation',
                            hint: 'Manager',
                            icon: Icons.work_outline,
                            primaryColor: primaryColor,
                            isRequired: false,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildTextField(
                            controller: departmentController,
                            label: 'Department',
                            hint: 'Sales',
                            icon: Icons.business_outlined,
                            primaryColor: primaryColor,
                            isRequired: false,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // Role Dropdown — New backend roles: ADMIN, MANAGER, User
                    _buildDropdown(primaryColor),

                    const SizedBox(height: 15),
                    _buildTextField(
                      controller: passwordController,
                      label: 'Initial Password',
                      hint: '••••••••',
                      icon: Icons.lock_outline,
                      isPassword: true,
                      obscureText: _obscurePassword,
                      primaryColor: primaryColor,
                      onTogglePassword: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      controller: confirmController,
                      label: 'Confirm Password',
                      hint: '••••••••',
                      icon: Icons.lock_reset_outlined,
                      isPassword: true,
                      obscureText: _obscureConfirm,
                      primaryColor: primaryColor,
                      onTogglePassword: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (v != passwordController.text)
                          return 'Passwords do not match';
                        return null;
                      },
                    ),

                    const SizedBox(height: 28),

                    // Add User Button
                    Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        return SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: auth.isLoading
                                ? null
                                : () async {
                                    if (!_formKey.currentState!.validate())
                                      return;

                                    final success = await auth.register(
                                      firstName: firstNameController.text
                                          .trim(),
                                      lastName: lastNameController.text.trim(),
                                      workEmail: emailController.text.trim(),
                                      password: passwordController.text,
                                      mobileNumber: mobileController.text
                                          .trim(),
                                      role: _selectedRole,
                                      designation: designationController.text
                                          .trim(),
                                      department: departmentController.text
                                          .trim(),
                                    );

                                    if (success && mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'User Added Successfully!',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                      Navigator.pop(context);
                                    } else if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            auth.errorMessage ??
                                                'Failed to add user',
                                          ),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 5,
                              shadowColor: primaryColor.withOpacity(0.4),
                            ),
                            child: auth.isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'ADD USER',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shown when non-admin tries to access this screen
  Widget _buildNotAvailableScreen(BuildContext context, Color primaryColor) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Create Account',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.admin_panel_settings_outlined,
                size: 60,
                color: Color(0xFF003366),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Admin Access Required',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'New user registration requires an Administrator or Manager to add you to the system.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  'BACK TO LOGIN',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
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
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
    TextInputType? keyboardType,
    required Color primaryColor,
    bool isRequired = true,
    String? Function(String?)? validator,
    bool isPhone = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(15),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            inputFormatters: isPhone ? indianPhoneInputFormatters() : null,
            validator:
                validator ??
                (v) {
                  if (isRequired && (v == null || v.isEmpty)) return 'Required';
                  if (isPhone) {
                    return indianPhoneValidationMessage(v);
                  }
                  return null;
                },
            decoration: isPhone
                ? buildIndianPhoneDecoration(
                    context,
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      suffixIcon: isPassword
                          ? IconButton(
                              icon: Icon(
                                obscureText
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey[400],
                                size: 20,
                              ),
                              onPressed: onTogglePassword,
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 10,
                      ),
                      errorStyle: const TextStyle(height: 0),
                    ),
                    hintText: hint,
                  )
                : InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    prefixIcon: Icon(icon, color: primaryColor, size: 22),
                    suffixIcon: isPassword
                        ? IconButton(
                            icon: Icon(
                              obscureText
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey[400],
                              size: 20,
                            ),
                            onPressed: onTogglePassword,
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 10,
                    ),
                    errorStyle: const TextStyle(height: 0),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(Color primaryColor) {
    return AppDropdown<String>(
      isCompact: false,
      value: _selectedRole,
      // New backend roles
      items: const ['User', 'MANAGER', 'ADMIN'],
      labelBuilder: (v) => v,
      label: 'ROLE',
      prefixIcon: Icons.security_outlined,
      accentColor: primaryColor,
      onChanged: (v) {
        if (v != null) setState(() => _selectedRole = v);
      },
    );
  }
}
