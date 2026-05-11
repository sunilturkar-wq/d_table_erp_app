import 'package:d_table_erp_app/model/user_model.dart';
import 'package:d_table_erp_app/services/user_service.dart';
import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  final UserService _userService = UserService();
  List<UserModel> _users = [];
  List<UserModel> _myTeam = [];
  bool _isLoading = false;

  // ── Member Detail Panel ──────────────────────────────
  UserModel? _selectedMember;
  Map<String, dynamic>? _memberProfile;
  bool _isMemberLoading = false;

  List<UserModel> get users => _users;
  List<UserModel> get myTeam => _myTeam;
  bool get isLoading => _isLoading;

  UserModel? get selectedMember => _selectedMember;
  Map<String, dynamic>? get memberProfile => _memberProfile;
  bool get isMemberLoading => _isMemberLoading;

  Future<void> fetchUsers() async {
    _isLoading = true;
    notifyListeners();
    try {
      _users = await _userService.getAllUsers();
      print("✅ Total Users fetched in Provider: ${_users.length}");
    } catch (e) {
      print("❌ User Provider Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyTeam() async {
    _isLoading = true;
    notifyListeners();
    try {
      _myTeam = await _userService.getMyTeam();
      print("✅ My Team fetched in Provider: ${_myTeam.length}");
    } catch (e) {
      print("❌ User Provider Error (My Team): $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Select a member and fetch their detailed profile from /auth/users/:userId
  Future<void> fetchMemberProfile(UserModel member) async {
    _selectedMember = member;
    _memberProfile = null;
    _isMemberLoading = true;
    notifyListeners();
    try {
      // ✅ New backend: use getUserById instead of getMemberProfile
      _memberProfile = await _userService.getUserById(member.id);
      print("✅ Member profile fetched for: ${member.fullName}");
    } catch (e) {
      // Fall back to user model data if fetch fails
      _memberProfile = member.toJson();
      print("⚠️ Member Profile fallback: $e");
    } finally {
      _isMemberLoading = false;
      notifyListeners();
    }
  }

  void clearSelectedMember() {
    _selectedMember = null;
    _memberProfile = null;
    notifyListeners();
  }
}
