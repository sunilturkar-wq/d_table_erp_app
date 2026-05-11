import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../model/user_model.dart';
import '../services/auth_service.dart';
import '../utils/phone_number_helper.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _errorMessage;
  UserModel? _currentUser;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => _currentUser;

  // ✅ Getter to check if the user is an Admin
  bool get isAdmin =>
      _currentUser?.role?.toLowerCase() == 'admin' ||
      _currentUser?.role?.toLowerCase() == 'superadmin';

  AuthProvider() {
    restoreSession();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _authService.login(email, password);
      final box = Hive.box('settingsBox');

      await box.put('auth_token', data['token']);
      await box.put('auth_user', jsonEncode(data['user']));

      // ✅ New backend: user.id field use hota hai
      String fetchedId = data['user']['id'] ?? data['user']['userId'] ?? '';
      await box.put('auth_user_id', fetchedId);

      _currentUser = UserModel.fromJson(data['user']);
      _isAuthenticated = true;

      // 🕵️ Is print se check karein ki ID khali toh nahi?
      print(
        "🚀 LOGIN SUCCESS! ID: ${_currentUser?.id}, Role: ${_currentUser?.role}",
      );

      // 🔄 Fetch full profile details not returned by login (workEmail, designation, etc)
      await fetchCurrentUserProfile();

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print("🛑 LOGIN FAILED! Error: $_errorMessage");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- FETCH FULL PROFILE ---
  Future<void> fetchCurrentUserProfile() async {
    if (!_isAuthenticated) return;
    try {
      final data = await _authService.fetchMe();
      final merged = {...(_currentUser?.toJson() ?? {}), ...data};
      _currentUser = UserModel.fromJson(merged);

      final box = Hive.box('settingsBox');
      await box.put('auth_user', jsonEncode(_currentUser!.toJson()));

      // Update UI with full profile data
      notifyListeners();
      print("✅ Full profile fetched for: ${_currentUser?.workEmail}");
    } catch (e) {
      print("⚠️ Failed to fetch full profile: $e");
    }
  }

  Future<bool> refreshCurrentUserProfile() async {
    if (!_isAuthenticated) return false;

    _errorMessage = null;
    try {
      final data = await _authService.fetchMe();
      final merged = {...(_currentUser?.toJson() ?? {}), ...data};
      _currentUser = UserModel.fromJson(merged);

      final box = Hive.box('settingsBox');
      await box.put('auth_user', jsonEncode(_currentUser!.toJson()));

      notifyListeners();
      print("✅ Full profile refreshed for: ${_currentUser?.workEmail}");
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      print("⚠️ Failed to refresh full profile: $e");
      return false;
    }
  }

  // --- REGISTER METHOD ---
  Future<bool> register({
    required String firstName,
    required String lastName,
    required String workEmail,
    required String password,
    required String mobileNumber,
    required String role,
    required String designation,
    required String department,
    String? reportingManagerId,
    bool? taskAccess,
    bool? leaveAccess,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final Map<String, dynamic> registrationData = {
        "firstName": firstName,
        "lastName": lastName,
        "workEmail": workEmail,
        "password": password,
        "mobileNumber": normalizeIndianPhone(mobileNumber),
        "role": role,
        "designation": designation,
        "department": department,
        if (reportingManagerId != null && reportingManagerId.isNotEmpty)
          "reportingManagerId": reportingManagerId,
        if (taskAccess != null) "taskAccess": taskAccess,
        if (leaveAccess != null) "leaveAccess": leaveAccess,
      };

      final resp = await _authService.register(registrationData);

      // ✅ SUCCESS PRINT IN CONSOLE
      print("-----------------------------------------");
      print("🆕 REGISTRATION SUCCESSFUL!");
      print("📄 Response Data: ${jsonEncode(resp)}");
      print("-----------------------------------------");

      if (resp.containsKey('token') && resp.containsKey('user')) {
        final box = Hive.box('settingsBox');

        // Store token
        await box.put('auth_token', resp['token']);

        // Store user data
        await box.put('auth_user', jsonEncode(resp['user']));

        // Store user ID
        String fetchedId = resp['user']['userId'] ?? resp['user']['id'] ?? '';
        await box.put('auth_user_id', fetchedId);

        // Set current user and mark as authenticated
        _currentUser = UserModel.fromJson(resp['user']);
        _isAuthenticated = true;

        print(
          "✅ User auto-authenticated after signup! ID: ${_currentUser?.id}, Designation: ${_currentUser?.designation}",
        );
        return true;
      } else if (resp['message'] == "User registered successfully") {
        // Fallback for backward compatibility - signup successful but need to login
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');

      // ❌ ERROR PRINT IN CONSOLE
      print("-----------------------------------------");
      print("🛑 REGISTRATION FAILED!");
      print("⚠️ Error: $_errorMessage");
      print("-----------------------------------------");

      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- UPDATE PROFILE (AND PICTURE) ---
  // ✅ New backend: userId required — PUT /auth/users/:userId
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userId =
          _currentUser?.id ?? Hive.box('settingsBox').get('auth_user_id') ?? '';
      if (userId.isEmpty) throw 'User ID not found — please login again';

      final normalizedUpdates = Map<String, dynamic>.from(updates);
      if (normalizedUpdates.containsKey('mobileNumber')) {
        normalizedUpdates['mobileNumber'] = normalizeIndianPhone(
          normalizedUpdates['mobileNumber']?.toString(),
        );
      }

      final updatedData = await _authService.updateProfile(
        userId,
        normalizedUpdates,
      );

      // Merge updated data with existing user (backend may return partial)
      final merged = {
        ...(_currentUser?.toJson() ?? {}),
        ...normalizedUpdates,
        ...updatedData,
      };
      _currentUser = UserModel.fromJson(merged);

      final box = Hive.box('settingsBox');
      await box.put('auth_user', jsonEncode(_currentUser!.toJson()));

      print("✅ PROFILE UPDATED SUCCESSFULLY!");
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      print("🛑 PROFILE UPDATE FAILED! Error: $_errorMessage");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- CHANGE PASSWORD ---
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userId =
          _currentUser?.id ?? Hive.box('settingsBox').get('auth_user_id') ?? '';
      if (userId.isEmpty) throw 'User ID not found — please login again';

      await _authService.changePassword(
        userId,
        {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );

      print("✅ PASSWORD CHANGED SUCCESSFULLY!");
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      print("🛑 PASSWORD CHANGE FAILED! Error: $_errorMessage");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- UPLOAD PROFILE IMAGE ---
  Future<bool> uploadProfileImage(File file) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final responseData = await _authService.uploadProfileImage(file);
      final newUrl = responseData['url'];

      if (newUrl == null) throw 'Failed to get image URL from server';

      final merged = {
        ...(_currentUser?.toJson() ?? {}),
        'profilePhotoUrl': newUrl,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      _currentUser = UserModel.fromJson(merged);

      final box = Hive.box('settingsBox');
      await box.put('auth_user', jsonEncode(_currentUser!.toJson()));

      print("✅ PROFILE IMAGE UPLOADED & UPDATED SUCCESSFULLY!");
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      print("🛑 UPLOAD FAILED! Error: $_errorMessage");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- ADMIN: GET ALL USERS ---
  List<UserModel> _allUsers = [];
  List<UserModel> get allUsers => _allUsers;

  Future<void> fetchAllUsers() async {
    _isLoading = true;
    notifyListeners();
    try {
      final List<dynamic> usersData = await _authService.getAllUsers();
      _allUsers = usersData.map((data) => UserModel.fromJson(data)).toList();
    } catch (e) {
      _errorMessage = e.toString();
      print("🛑 FAILED TO FETCH USERS: $_errorMessage");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- ADMIN: DELETE USER ---
  Future<bool> deleteUser(String userId) async {
    try {
      await _authService.deleteUser(userId);
      _allUsers.removeWhere((user) => user.id == userId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print("🛑 FAILED TO DELETE USER: $_errorMessage");
      return false;
    }
  }

  // --- ADMIN: UPDATE TEAM MEMBER ---
  // ✅ New backend: PUT /auth/users/:userId
  Future<bool> updateTeamMemberDetails(
    String memberId,
    Map<String, dynamic> updates,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final normalizedUpdates = Map<String, dynamic>.from(updates);
      if (normalizedUpdates.containsKey('mobileNumber')) {
        normalizedUpdates['mobileNumber'] = normalizeIndianPhone(
          normalizedUpdates['mobileNumber']?.toString(),
        );
      }

      await _authService.updateUser(memberId, normalizedUpdates);
      print("✅ TEAM MEMBER UPDATED SUCCESSFULLY!");
      // Refresh users list
      final idx = _allUsers.indexWhere((u) => u.id == memberId);
      if (idx != -1) {
        final updated = {..._allUsers[idx].toJson(), ...normalizedUpdates};
        _allUsers[idx] = UserModel.fromJson(updated);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      print("🛑 TEAM MEMBER UPDATE FAILED! Error: $_errorMessage");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final box = Hive.box('settingsBox');
    await box.clear(); // Token aur user delete
    _isAuthenticated = false;
    _currentUser = null;
    print("🚪 User Logged Out & Console Cleared");
    notifyListeners();
  }

  void restoreSession() {
    final box = Hive.box('settingsBox');
    final token = box.get('auth_token');
    final userStr = box.get('auth_user');
    if (token != null && userStr != null) {
      _isAuthenticated = true;
      _currentUser = UserModel.fromJson(jsonDecode(userStr));
      print(
        "✅ Session Restored for: ${_currentUser?.workEmail} as ${_currentUser?.role}",
      );

      // Fetch latest full profile data in the background
      fetchCurrentUserProfile();
    }
  }
}
