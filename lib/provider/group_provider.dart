import 'dart:io';
import 'package:flutter/material.dart';
import '../model/group_model.dart';
import '../services/group_service.dart';
import '../services/delegation_service.dart';

class GroupProvider extends ChangeNotifier {
  final GroupService _service = GroupService();
  final DelegationService _delegationService = DelegationService();
  
  bool _isLoading = false;
  String? _errorMessage;
  List<GroupModel> _myGroups = [];
  GroupModel? _selectedGroup;
  List<dynamic> _groupTasks = [];
  List<dynamic> _groupMembers = [];

  // Filter states
  String _searchQuery = "";
  String _dateRange = "This Month";
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  String _assignedTo = "Assigned To";
  String _frequency = "Frequency";

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<GroupModel> get myGroups => _myGroups;
  GroupModel? get selectedGroup => _selectedGroup;
  List<dynamic> get groupTasks => _groupTasks;
  List<dynamic> get groupMembers => _groupMembers;

  String get searchQuery => _searchQuery;
  String get dateRange => _dateRange;
  DateTime? get customStartDate => _customStartDate;
  DateTime? get customEndDate => _customEndDate;
  String get assignedTo => _assignedTo;
  String get frequency => _frequency;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setDateRange(String range, {DateTime? start, DateTime? end}) {
    _dateRange = range;
    _customStartDate = start;
    _customEndDate = end;
    notifyListeners();
  }

  void setAssignedTo(String userId) {
    _assignedTo = userId;
    notifyListeners();
  }

  void setFrequency(String freq) {
    _frequency = freq;
    notifyListeners();
  }

  Future<void> fetchMyGroups() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final rawData = await _service.getMyGroups();
      final groups = rawData.map((json) => GroupModel.fromJson(json)).toList();
      final enrichedGroups = <GroupModel>[];
      for (final group in groups) {
        try {
          final members = await _service.getGroupMembers(group.id);
          enrichedGroups.add(
            group.copyWith(
              memberCount: members.length,
              members: members,
            ),
          );
        } catch (_) {
          enrichedGroups.add(group);
        }
      }
      _myGroups = enrichedGroups;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createGroup(String name, String description, List<String> memberIds, {File? image}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String? photoUrl;
      if (image != null) {
        photoUrl = await _delegationService.uploadFile(image, folder: 'groups');
      }

      await _service.createGroup({
        "name": name,
        "description": description,
        "members": memberIds,
        "imageUrl": photoUrl,
      });
      await fetchMyGroups();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchGroupDetails(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final data = await _service.getGroupById(id);
      _groupMembers = await _service.getGroupMembers(id);
      _selectedGroup = GroupModel.fromJson({
        ...data,
        'members': _groupMembers,
        'memberCount': _groupMembers.length,
      });

      final queryParams = {
        'groupId': id,
        'search': _searchQuery.isNotEmpty ? _searchQuery : null,
        'doerId': _assignedTo != "Assigned To" ? _assignedTo : null,
        'frequency': _frequency != "Frequency" ? _frequency : null,
      };

      // Handle Date Range Logic
      if (_dateRange != "All Time") {
        final now = DateTime.now();
        DateTime? start;
        DateTime? end;

        if (_dateRange == "Today") {
          start = DateTime(now.year, now.month, now.day);
          end = start.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
        } else if (_dateRange == "Yesterday") {
          start = DateTime(now.year, now.month, now.day - 1);
          end = start.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
        } else if (_dateRange == "This Week") {
          start = now.subtract(Duration(days: now.weekday - 1));
          start = DateTime(start.year, start.month, start.day);
          end = start.add(const Duration(days: 7)).subtract(const Duration(milliseconds: 1));
        } else if (_dateRange == "Last Week") {
          start = now.subtract(Duration(days: now.weekday - 1 + 7));
          start = DateTime(start.year, start.month, start.day);
          end = start.add(const Duration(days: 7)).subtract(const Duration(milliseconds: 1));
        } else if (_dateRange == "This Month") {
          start = DateTime(now.year, now.month, 1);
          end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        } else if (_dateRange == "Last Month") {
          start = DateTime(now.year, now.month - 1, 1);
          end = DateTime(now.year, now.month, 0, 23, 59, 59);
        } else if (_dateRange == "This Year") {
          start = DateTime(now.year, 1, 1);
          end = DateTime(now.year, 12, 31, 23, 59, 59);
        } else if (_dateRange == "Custom") {
          start = _customStartDate;
          end = _customEndDate;
        }

        if (start != null) queryParams['startDate'] = start.toIso8601String();
        if (end != null) queryParams['endDate'] = end.toIso8601String();
      }

      _groupTasks = await _service.getGroupTasksFiltered(queryParams);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateGroup(
    String id, {
    required String name,
    required String description,
    required List<String> memberIds,
    File? image,
    String? existingImageUrl,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String? photoUrl = existingImageUrl;
      if (image != null) {
        photoUrl = await _delegationService.uploadFile(image, folder: 'groups');
      }

      await _service.updateGroup(id, {
        'name': name,
        'description': description,
        'members': memberIds,
        'imageUrl': photoUrl,
      });

      await fetchGroupDetails(id);
      await fetchMyGroups();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> assignTaskToGroup(String groupId, Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final payload = {
        ...data,
        'groupId': groupId,
      };
      await _service.createGroupTask(payload);
      await fetchGroupDetails(groupId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
