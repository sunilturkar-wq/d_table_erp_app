import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../model/user_model.dart';
import '../../provider/auth_provider.dart';
import '../../utils/phone_number_helper.dart';

class GeneralSettingsScreen extends StatefulWidget {
  const GeneralSettingsScreen({super.key});

  @override
  State<GeneralSettingsScreen> createState() => _GeneralSettingsScreenState();
}

class _GeneralSettingsScreenState extends State<GeneralSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _workEmailController;
  late final TextEditingController _mobileController;
  String? _dateOfBirth;
  String? _joiningDate;
  String? _anniversaryDate;

  bool _taskAccess = true;
  bool _isSaving = false;
  bool _isUploading = false;
  bool _isRefreshing = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _workEmailController = TextEditingController();
    _mobileController = TextEditingController();
    _syncFromUser(user);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshProfile();
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _workEmailController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  void _syncFromUser(UserModel? user) {
    _firstNameController.text = user?.firstName ?? '';
    _lastNameController.text = user?.lastName ?? '';
    _workEmailController.text = user?.workEmail ?? '';
    _mobileController.text = extractIndianPhoneDigits(user?.mobileNumber);
    _taskAccess = user?.taskAccess ?? true;
    _dateOfBirth = user?.dateOfBirth;
    _joiningDate = user?.joiningDate;
    _anniversaryDate = user?.anniversaryDate;
  }

  Future<void> _refreshProfile({bool showLoader = true}) async {
    if (showLoader && mounted) {
      setState(() {
        _isRefreshing = true;
        _loadError = null;
      });
    }

    final authProvider = context.read<AuthProvider>();
    final ok = await authProvider.refreshCurrentUserProfile();
    if (!mounted) return;

    _syncFromUser(authProvider.currentUser);
    setState(() {
      _isRefreshing = false;
      _loadError = ok
          ? null
          : (authProvider.errorMessage ?? 'Failed to load profile information');
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final mobileError = indianPhoneValidationMessage(
      _mobileController.text.trim(),
    );
    if (mobileError != null) {
      _showSnack(mobileError, true);
      return;
    }

    final user = context.read<AuthProvider>().currentUser;
    final Map<String, dynamic> updates = {};

    final currentFirstName = _firstNameController.text.trim();
    if (user?.firstName != currentFirstName)
      updates['firstName'] = currentFirstName;

    final currentLastName = _lastNameController.text.trim();
    if (user?.lastName != currentLastName)
      updates['lastName'] = currentLastName;

    final currentEmail = _workEmailController.text.trim();
    if (user?.workEmail != currentEmail) updates['workEmail'] = currentEmail;

    final currentMobile = _mobileController.text.trim();
    if (extractIndianPhoneDigits(user?.mobileNumber) != currentMobile) {
      updates['mobileNumber'] = currentMobile;
    }

    if (user?.taskAccess != _taskAccess) updates['taskAccess'] = _taskAccess;

    if (_dateOfBirth != user?.dateOfBirth)
      updates['dateOfBirth'] = _dateOfBirth;
    if (_joiningDate != user?.joiningDate)
      updates['joiningDate'] = _joiningDate;
    if (_anniversaryDate != user?.anniversaryDate)
      updates['anniversaryDate'] = _anniversaryDate;

    if (updates.isEmpty) {
      _showSnack('No changes to save', false);
      return;
    }

    setState(() => _isSaving = true);
    final ok = await context.read<AuthProvider>().updateProfile(updates);
    if (!mounted) return;
    setState(() => _isSaving = false);
    _syncFromUser(context.read<AuthProvider>().currentUser);
    final error = context.read<AuthProvider>().errorMessage;
    _showSnack(
      ok
          ? 'Profile updated successfully'
          : (error ?? 'Failed to update profile'),
      !ok,
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
      );
      if (picked == null) return;
      setState(() => _isUploading = true);
      final ok = await context.read<AuthProvider>().uploadProfileImage(
        File(picked.path),
      );
      if (!mounted) return;
      setState(() => _isUploading = false);
      final error = context.read<AuthProvider>().errorMessage;
      _showSnack(
        ok ? 'Profile photo updated' : (error ?? 'Failed to update photo'),
        !ok,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      _showSnack('Error: $e', true);
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Update Profile Photo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF3B82F6)),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.image, color: Color(0xFF003366)),
              title: const Text('Browse Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    if (_isRefreshing && user == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: _buildLoadingState(),
      );
    }

    if (_loadError != null && user == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: _buildErrorState(),
      );
    }

    final lastUpdated =
        _formatDate(user?.updatedAt) ??
        _formatDate(user?.createdAt) ??
        DateFormat('dd/MM/yyyy').format(DateTime.now());
    final location = [
      user?.city,
      user?.state,
      user?.nationality,
    ].where((e) => e != null && e.trim().isNotEmpty).join(', ');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        color: const Color(0xFF003366),
        onRefresh: () => _refreshProfile(showLoader: false),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                if (_isRefreshing)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: LinearProgressIndicator(
                      minHeight: 3,
                      backgroundColor: Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation(Color(0xFF003366)),
                    ),
                  ),
                if (_loadError != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Color(0xFFDC2626),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _loadError!,
                            style: const TextStyle(
                              color: Color(0xFF991B1B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          Container(
                            height: 150,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(24),
                              ),
                            ),
                            child: Center(
                              child:
                                  (user?.profilePhotoUrl?.isNotEmpty ?? false)
                                  ? ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(24),
                                      ),
                                      child: Image.network(
                                        user!.profilePhotoUrl!,
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(Icons.person, size: 64),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person_outline,
                                      size: 64,
                                      color: Color(0xFFCBD5E1),
                                    ),
                            ),
                          ),
                          if (_isUploading)
                            const Positioned.fill(
                              child: ColoredBox(
                                color: Color(0x66000000),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            right: 12,
                            bottom: 12,
                            child: IconButton.filled(
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF475569),
                              ),
                              onPressed: _isUploading || _isRefreshing
                                  ? null
                                  : _showPhotoOptions,
                              icon: const Icon(Icons.camera_alt_outlined),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'My profile',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Text(
                                      'LAST UPDATE: $lastUpdated',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF94A3B8),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                _statusChip(user?.status),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: _field(
                                    'FIRST NAME',
                                    _firstNameController,
                                    validator: _requiredValidator,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _field(
                                    'LAST NAME',
                                    _lastNameController,
                                    validator: _requiredValidator,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _field(
                              'WORK EMAIL',
                              _workEmailController,
                              icon: Icons.mail_outline,
                              keyboardType: TextInputType.emailAddress,
                              validator: _emailValidator,
                            ),
                            const SizedBox(height: 16),
                            _field(
                              'MOBILE NUMBER',
                              _mobileController,
                              icon: Icons.phone_outlined,
                              isPhone: true,
                            ),
                            const SizedBox(height: 24),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              value: _taskAccess,
                              activeColor: const Color(0xFF003366),
                              title: const Text(
                                'Task Access activation',
                                style: TextStyle(
                                  color: Color(0xFFFB923C),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: const Text(
                                'Allow user to manage and see assigned tasks',
                                style: TextStyle(fontSize: 12),
                              ),
                              onChanged: _isSaving || _isRefreshing
                                  ? null
                                  : (value) =>
                                        setState(() => _taskAccess = value),
                            ),
                            const SizedBox(height: 16),
                            _dateField('DATE OF BIRTH', _dateOfBirth, 'dob'),
                            const SizedBox(height: 16),
                            _dateField('JOINING DATE', _joiningDate, 'joining'),
                            const SizedBox(height: 16),
                            _dateField(
                              'ANNIVERSARY (OPTIONAL)',
                              _anniversaryDate,
                              'anniversary',
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed:
                                    _isSaving || _isUploading || _isRefreshing
                                    ? null
                                    : _saveProfile,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  backgroundColor: const Color(0xFFFB923C),
                                  foregroundColor: Colors.white,
                                ),
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('SAVE PROFILE'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _infoCard(
                  'Career & Role',
                  Icons.work_outline,
                  const Color(0xFF003366),
                  [
                    _infoRow('Designation', _fallback(user?.designation)),
                    _infoRow('Department', _fallback(user?.department)),
                    _infoRow(
                      'Official Role',
                      (user?.role ?? 'TEAM MEMBER').toUpperCase(),
                      badgeText: 'OFFICIAL',
                      badgeColor: const Color(0xFFEFF6FF),
                      badgeTextColor: const Color(0xFF2563EB),
                    ),
                    _infoRow(
                      'Reporting To',
                      _fallback(user?.manager, 'No Manager Assigned'),
                      leadingIcon: Icons.account_circle_outlined,
                    ),
                    _infoRow(
                      'Joining Date',
                      _formatDate(user?.joiningDate, pattern: 'd MMMM yyyy') ??
                          'Not Provided',
                      leadingIcon: Icons.access_time,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _infoCard(
                  'Personal Info',
                  Icons.access_time,
                  const Color(0xFFEC4899),
                  [
                    _infoRow(
                      'Personal Email',
                      _fallback(user?.personalEmail),
                      badgeText: 'VERIFIED',
                      badgeColor: const Color(0xFF34D399),
                    ),
                    _infoRow(
                      'Birthday & Gender',
                      _birthdayGender(user),
                      badgeText: 'PRIVATE',
                      badgeColor: const Color(0xFFEC4899),
                    ),
                    _infoRow(
                      'Current Location',
                      location.isEmpty ? 'Not Provided' : location,
                      badgeText: 'PUBLIC',
                      badgeColor: const Color(0xFF34D399),
                    ),
                    _infoRow(
                      'Marital Status',
                      _fallback(user?.maritalStatus),
                      badgeText: 'ACTIVE',
                      badgeColor: const Color(0xFF34D399),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text(
        'GENERAL',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
      backgroundColor: const Color(0xFF003366),
      centerTitle: true,
      iconTheme: const IconThemeData(color: Colors.black),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _card(
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF003366)),
                SizedBox(height: 16),
                Text(
                  'Fetching your profile details...',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Color(0xFFDC2626),
                  size: 40,
                ),
                const SizedBox(height: 12),
                Text(
                  _loadError ?? 'Failed to load profile information',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF991B1B),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _refreshProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003366),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('TRY AGAIN'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    IconData? icon,
    bool isPhone = false,
    bool readOnly = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final decoration = InputDecoration(
      suffixIcon: icon == null
          ? null
          : Icon(icon, size: 18, color: const Color(0xFFCBD5E1)),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFE2E8F0), width: 2),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFFB923C), width: 2),
      ),
      filled: readOnly,
      fillColor: readOnly ? Colors.white : null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: Color(0xFF94A3B8),
            letterSpacing: 1.1,
          ),
        ),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          keyboardType:
              keyboardType ??
              (isPhone ? TextInputType.phone : TextInputType.text),
          inputFormatters: isPhone ? indianPhoneInputFormatters() : null,
          validator: validator,
          decoration: isPhone
              ? buildIndianPhoneDecoration(context, decoration: decoration)
              : decoration,
        ),
      ],
    );
  }

  Future<void> _pickDateFor(String fieldName, String? currentValue) async {
    final initialDate = currentValue != null
        ? DateTime.tryParse(currentValue) ?? DateTime.now()
        : DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final formatted = DateFormat('yyyy-MM-dd').format(picked);
      setState(() {
        if (fieldName == 'dob')
          _dateOfBirth = formatted;
        else if (fieldName == 'joining')
          _joiningDate = formatted;
        else if (fieldName == 'anniversary')
          _anniversaryDate = formatted;
      });
    }
  }

  Widget _dateField(String label, String? value, String type) {
    return InkWell(
      onTap: _isSaving || _isRefreshing
          ? null
          : () => _pickDateFor(type, value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFE2E8F0), width: 2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value != null
                      ? DateFormat('dd MMM yyyy').format(DateTime.parse(value))
                      : 'Not Specified',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
            const Icon(
              Icons.calendar_today_outlined,
              color: Color(0xFFCBD5E1),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _infoCard(
    String title,
    IconData icon,
    Color accentColor,
    List<Widget> children,
  ) {
    return _card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: accentColor, size: 22),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    String label,
    String value, {
    IconData? leadingIcon,
    String? badgeText,
    Color? badgeColor,
    Color? badgeTextColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (leadingIcon != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2, right: 6),
                        child: Icon(
                          leadingIcon,
                          size: 16,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    Expanded(
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (badgeText != null) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: badgeColor ?? const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: badgeTextColor ?? Colors.white,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusChip(String? rawStatus) {
    final status =
        (rawStatus?.trim().isNotEmpty == true ? rawStatus!.trim() : 'active')
            .toUpperCase();
    final isActive = status == 'ACTIVE';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFEAF1F8) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: isActive ? const Color(0xFF003366) : const Color(0xFF64748B),
        ),
      ),
    );
  }

  String _fallback(String? value, [String fallback = 'Not Provided']) {
    if (value == null || value.trim().isEmpty) return fallback;
    return value.trim();
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Work email is required';
    }
    final emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailPattern.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String _birthdayGender(UserModel? user) {
    final parts = [
      _formatDate(user?.dateOfBirth),
      user?.gender?.trim(),
    ].where((e) => e != null && e.isNotEmpty).cast<String>().toList();
    return parts.isEmpty ? 'Unknown' : parts.join(' | ');
  }

  String? _formatDate(String? raw, {String pattern = 'dd/MM/yyyy'}) {
    if (raw == null || raw.trim().isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    return DateFormat(pattern).format(parsed);
  }

  void _showSnack(String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}
