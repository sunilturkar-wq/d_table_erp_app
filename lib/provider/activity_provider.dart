import 'package:flutter/material.dart';
import '../services/activity_service.dart';
import '../model/activity_model.dart';
import '../model/user_model.dart';

class ActivityProvider extends ChangeNotifier {
  final ActivityService _service = ActivityService();

  List<ActivityModel> _activities = [];
  List<UserModel> _usersList = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Filters state
  String _searchQuery = '';
  String _dateRange = 'This Month'; // 'Today', 'This Week', 'This Month', 'All Time'
  String? _updatedBy; // User ID

  List<ActivityModel> get activities => _activities;
  List<UserModel> get usersList => _usersList;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get dateRange => _dateRange;
  String? get updatedBy => _updatedBy;
  String get searchQuery => _searchQuery;

  // Setters for filters
  void setDateRange(String range) {
    _dateRange = range;
    fetchActivities();
  }

  void setUpdatedBy(String? userId) {
    _updatedBy = userId;
    fetchActivities();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    // Debounce can be handled at UI
    notifyListeners();
  }
  
  void executeSearch() {
     fetchActivities();
  }

  Future<void> initActivities() async {
    _isLoading = true;
    notifyListeners();
    // Fetch users for dropdown once
    if (_usersList.isEmpty) {
      _usersList = await _service.getUsers();
    }
    await fetchActivities(skipLoadingChange: true);
  }

  Future<void> fetchActivities({bool skipLoadingChange = false}) async {
    if (!skipLoadingChange) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      String? startDateIso;
      final now = DateTime.now();

      if (_dateRange == 'Today') {
        startDateIso = DateTime(now.year, now.month, now.day).toIso8601String();
      } else if (_dateRange == 'This Week') {
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        startDateIso = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day).toIso8601String();
      } else if (_dateRange == 'This Month') {
        startDateIso = DateTime(now.year, now.month, 1).toIso8601String();
      }

      _activities = await _service.getActivities(
        userId: _updatedBy,
        startDate: startDateIso,
        search: _searchQuery.trim(),
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get filtered activities if client-side search is needed
  List<ActivityModel> get filteredActivities {
    if (_searchQuery.isEmpty) return _activities;
    final s = _searchQuery.toLowerCase();
    return _activities.where((a) =>
      a.title.toLowerCase().contains(s) ||
      a.description.toLowerCase().contains(s) ||
      (a.user != null && '${a.user!.firstName} ${a.user!.lastName}'.toLowerCase().contains(s))
    ).toList();
  }

  // Aggregated Stats
  List<Map<String, dynamic>> get userStats {
    final Map<String, Map<String, dynamic>> stats = {};
    for (var act in _activities) {
      if (act.user != null) {
        final uid = act.user!.id;
        if (!stats.containsKey(uid)) {
          stats[uid] = {
            'user': act.user,
            'count': 0,
          };
        }
        stats[uid]!['count'] = (stats[uid]!['count'] as int) + 1;
      }
    }
    
    final sortedStats = stats.values.toList();
    sortedStats.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    return sortedStats;
  }
}
