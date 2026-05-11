import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import '../config/api_constants.dart';
import 'dio_client.dart';

// ⚠️ New backend does NOT have /dashboard/stats endpoint.
// Stats are now derived client-side from /delegations data.
class DashboardService {
  final Dio _dio = DioClient().dio;

  /// Fetches all delegations and computes dashboard stats locally
  Future<Map<String, dynamic>?> fetchDashboardStats({
    String filter = 'All Time',
    String tab = 'My Report',
    String category = 'Category',
    String status = 'Status',
    String? frequency,
    String? tag,
    String? userId,
    String search = '',
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'category': _buildCategoryParam(category),
        'tag': _buildTagParam(tag),
        'frequency': _buildFrequencyParam(frequency),
        'doerId': _buildDoerIdParam(userId),
        'search': search.trim().isEmpty ? null : search.trim(),
        ..._buildDateQueryParams(
          filter: filter,
          startDate: startDate,
          endDate: endDate,
        ),
      }..removeWhere((key, value) => value == null);

      final response = await _dio.get(
        ApiConstants.delegations,
        queryParameters: queryParameters,
      );
      final data = response.data;
      List<dynamic> delegations = [];
      if (data is Map) {
        delegations = data['data'] ?? [];
      } else if (data is List) {
        delegations = data;
      }

      List<Map<String, dynamic>> dList = [
        for (var map in delegations) Map<String, dynamic>.from(map as Map)
      ];

      if (status != 'Status' && status != 'All') {
        dList = dList.where((task) {
          if (status == 'Overdue') return _isOverdueTask(task);
          return _normalizeStatus(task['status']) == status;
        }).toList();
      }

      final currentUserId =
          Hive.box('settingsBox').get('auth_user_id')?.toString() ?? '';

      // 1. Calculate basic stats
      final total = dList.length;
      final completed = dList.where((d) => _normalizeStatus(d['status']) == 'Completed').length;
      final inProgress = dList.where((d) => _normalizeStatus(d['status']) == 'In Progress').length;
      final pending = dList.where((d) => _normalizeStatus(d['status']) == 'Pending').length;
      
      final overdueCount = dList.where(_hasOverdueStatus).length;

      final onTimeCount = dList.where(_isCompletedOnTime).length;
      final delayedCount = dList.where(_isDelayedTask).length;

      // 2. Build table data exactly like web dashboard.
      final tableData = await _buildTableData(
        tab: tab,
        tasks: dList,
        currentUserId: currentUserId,
      );

      // Handle Overdue literally for the React-like list
      List<dynamic> overdueTasksList = [];
      if (tab == 'Overdue') {
        overdueTasksList = dList.where(_isOverdueListTask).toList();
      }

      // Build Bar Chart Data
      Map<String, Map<String, int>> empGrouped = {};
      Map<String, Map<String, int>> catGrouped = {};
      Map<String, Map<String, int>> dailyGrouped = {};
      Map<String, Map<String, int>> monthlyGrouped = {};
      Map<String, Map<String, int>> delGrouped = {};

      void addToGroup(Map<String, Map<String, int>> group, String key, String status) {
        if (!group.containsKey(key)) {
          group[key] = {"Pending": 0, "Overdue": 0, "In Progress": 0, "Completed": 0};
        }
        final statusKey = status;
        if (group[key]!.containsKey(statusKey)) {
          group[key]![statusKey] = group[key]![statusKey]! + 1;
        } else {
          group[key]!["Pending"] = group[key]!["Pending"]! + 1;
        }
      }

      for (var task in dList) {
        final status = _hasOverdueStatus(task)
            ? 'Overdue'
            : _normalizeStatus(task['status']);
        
        // Assignee (Doer) Name
        final doerF = task['doerFirstName'] ?? task['assigneeFirstName'] ?? task['assignee_first_name'] ?? '';
        final doerL = task['doerLastName'] ?? task['assigneeLastName'] ?? task['assignee_last_name'] ?? '';
        final empName = "$doerF $doerL".trim();
        if (empName.isNotEmpty) addToGroup(empGrouped, empName, status);

        // Category Wise
        final catName = _categoryLabel(task['category']);
        addToGroup(catGrouped, catName, status);

        // Daily/Monthly
        final createdAt = task['createdAt'] ?? task['date'] ?? '';
        if (createdAt.isNotEmpty) {
          final dateObj = DateTime.tryParse(createdAt);
          if (dateObj != null) {
            final dayStr = "${dateObj.year}-${dateObj.month.toString().padLeft(2, '0')}-${dateObj.day.toString().padLeft(2, '0')}";
            final monthStr = "${_getMonthName(dateObj.month)} ${dateObj.year}";
            addToGroup(dailyGrouped, dayStr, status);
            addToGroup(monthlyGrouped, monthStr, status);
          }
        }

        // Assigner (Delegator) Name
        final delF = task['delegatorFirstName'] ?? task['delegator_first_name'] ?? task['assignerFirstName'] ?? task['assigner_first_name'] ?? '';
        final delL = task['delegatorLastName'] ?? task['delegator_last_name'] ?? task['assignerLastName'] ?? task['assigner_last_name'] ?? '';
        final delName = "$delF $delL".trim();
        if (delName.isNotEmpty) addToGroup(delGrouped, delName, status);
      }

      return {
        'total': total,
        'completed': completed,
        'inProgress': inProgress,
        'pending': pending,
        'overdue': overdueCount,
        'onTime': onTimeCount,
        'delayed': delayedCount,
        'tableData': tableData,
        'overdueTasks': overdueTasksList,
        'charts': {
          'employeeWise': empGrouped,
          'categoryWise': catGrouped,
          'dailyReport': dailyGrouped,
          'monthlyReport': monthlyGrouped,
          'delegatedReport': delGrouped,
        }
      };
    } catch (e) {
      rethrow;
    }
  }

  String _getMonthName(int month) {
    const names = ["", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return names[month];
  }

  String? _buildCategoryParam(String category) {
    if (category == 'Category' || category == 'All' || category.isEmpty) {
      return null;
    }
    return category;
  }

  String? _buildTagParam(String? tag) {
    if (tag == null || tag == 'Tag' || tag == 'All' || tag.isEmpty) {
      return null;
    }
    return tag;
  }

  String? _buildFrequencyParam(String? frequency) {
    if (frequency == null ||
        frequency == 'Frequency' ||
        frequency == 'All' ||
        frequency.isEmpty) {
      return null;
    }
    return frequency;
  }

  String? _buildDoerIdParam(String? userId) {
    if (userId == null || userId.isEmpty || userId == 'All') {
      return null;
    }
    return userId;
  }

  Map<String, String> _buildDateQueryParams({
    required String filter,
    String? startDate,
    String? endDate,
  }) {
    final range = _resolveDateRange(
      filter: filter,
      startDate: startDate,
      endDate: endDate,
    );

    if (range == null) return const {};

    return {
      'startDate': range[0].toIso8601String(),
      'endDate': range[1].toIso8601String(),
    };
  }

  List<DateTime>? _resolveDateRange({
    required String filter,
    String? startDate,
    String? endDate,
  }) {
    final now = DateTime.now();

    switch (filter) {
      case 'Today':
        return [
          DateTime(now.year, now.month, now.day),
          DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
        ];
      case 'Yesterday':
        final day = DateTime(now.year, now.month, now.day - 1);
        return [
          day,
          DateTime(day.year, day.month, day.day, 23, 59, 59, 999),
        ];
      case 'This Week':
        final start = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));
        return [
          start,
          start.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59, milliseconds: 999)),
        ];
      case 'Last Week':
        final thisWeekStart = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));
        final start = thisWeekStart.subtract(const Duration(days: 7));
        return [
          start,
          start.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59, milliseconds: 999)),
        ];
      case 'This Month':
        return [
          DateTime(now.year, now.month, 1),
          DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999),
        ];
      case 'Last Month':
        return [
          DateTime(now.year, now.month - 1, 1),
          DateTime(now.year, now.month, 0, 23, 59, 59, 999),
        ];
      case 'This Year':
        return [
          DateTime(now.year, 1, 1),
          DateTime(now.year, 12, 31, 23, 59, 59, 999),
        ];
      case 'Custom':
        final start = startDate == null ? null : DateTime.tryParse(startDate);
        final end = endDate == null ? null : DateTime.tryParse(endDate);
        if (start == null || end == null) return null;
        return [
          DateTime(start.year, start.month, start.day),
          DateTime(end.year, end.month, end.day, 23, 59, 59, 999),
        ];
      default:
        return null;
    }
  }

  String _normalizeStatus(dynamic rawStatus) {
    final status = (rawStatus ?? '').toString().trim().toLowerCase();
    switch (status) {
      case 'completed':
      case 'done':
        return 'Completed';
      case 'in progress':
      case 'working':
        return 'In Progress';
      case 'overdue':
      case 'over due':
      case 'late':
        return 'Overdue';
      case 'pending':
      default:
        return 'Pending';
    }
  }

  bool _isOverdueTask(Map<String, dynamic> task) {
    final status = _normalizeStatus(task['status']);
    if (status == 'Completed') return false;

    return status == 'Overdue';
  }

  bool _isCompletedOnTime(Map<String, dynamic> task) {
    if (_normalizeStatus(task['status']) != 'Completed') return false;
    final dueDate = _parseDateTime(task['dueDate']);
    final updatedAt = _parseDateTime(task['updatedAt']);
    if (dueDate == null || updatedAt == null) return true;
    return !dueDate.isBefore(updatedAt);
  }

  bool _hasOverdueStatus(Map<String, dynamic> task) {
    return _normalizeStatus(task['status']) == 'Overdue';
  }

  bool _isDelayedTask(Map<String, dynamic> task) {
    if (_normalizeStatus(task['status']) == 'Completed') return false;
    final dueDate = _parseDateTime(task['dueDate']);
    if (dueDate == null) return false;
    return dueDate.isBefore(DateTime.now());
  }

  bool _isOverdueListTask(Map<String, dynamic> task) {
    return _hasOverdueStatus(task) || _isDelayedTask(task);
  }

  DateTime? _parseDateTime(dynamic rawValue) {
    if (rawValue == null) return null;
    final parsed = DateTime.tryParse(rawValue.toString())?.toLocal();
    return parsed;
  }

  String _categoryLabel(dynamic rawCategory) {
    final raw = rawCategory?.toString().trim() ?? '';
    return raw.isEmpty ? 'Uncategorized' : raw;
  }

  String _extractPrimaryTag(dynamic rawTags) {
    if (rawTags is List && rawTags.isNotEmpty) {
      final first = rawTags.first;
      if (first is Map) {
        final text = first['text']?.toString().trim();
        if (text != null && text.isNotEmpty) return text;
      }
      final value = first.toString().trim();
      if (value.isNotEmpty) return value;
    }

    if (rawTags is String && rawTags.trim().isNotEmpty) {
      return rawTags.trim();
    }

    return 'Un-tagged';
  }

  Future<Map<String, String>> _fetchGroupNamesById() async {
    try {
      final response = await _dio.get(ApiConstants.groupsList);
      final data = response.data;
      final rawGroups = data is Map ? (data['data'] ?? []) : data;
      if (rawGroups is! List) return const {};

      final result = <String, String>{};
      for (final item in rawGroups) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final id = map['groupId']?.toString() ?? map['id']?.toString();
        final name = map['name']?.toString();
        if (id != null && id.isNotEmpty && name != null && name.isNotEmpty) {
          result[id] = name;
        }
      }
      return result;
    } catch (_) {
      return const {};
    }
  }

  Future<List<Map<String, dynamic>>> _fetchUsers() async {
    try {
      final response = await _dio.get(ApiConstants.getAllUser);
      final data = response.data;
      final rawUsers =
          data is List ? data : (data is Map ? (data['users'] ?? data['data'] ?? []) : []);
      if (rawUsers is! List) return const [];
      return rawUsers
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchGroups() async {
    try {
      final response = await _dio.get(ApiConstants.groupsList);
      final data = response.data;
      final rawGroups = data is List ? data : (data is Map ? (data['data'] ?? []) : []);
      if (rawGroups is! List) return const [];
      return rawGroups
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Map<String, dynamic> _aggregateWebStats(List<Map<String, dynamic>> tasks) {
    int total = 0;
    int overdue = 0;
    int pending = 0;
    int inProgress = 0;
    int inTime = 0;
    int delayed = 0;

    for (final task in tasks) {
      total++;
      final status = _normalizeStatus(task['status']);
      if (status == 'Overdue') overdue++;
      else if (status == 'Pending') pending++;
      else if (status == 'In Progress') inProgress++;
      else if (status == 'Completed') inTime++;
      if (_isDelayedTask(task)) delayed++;
    }

    final safeTotal = total == 0 ? 1 : total;
    return {
      'total': total,
      'overdue': overdue,
      'pending': pending,
      'in_progress': inProgress,
      'in_time': inTime,
      'delayed': delayed,
      'score': '${((inTime / safeTotal) * 100).toStringAsFixed(1)}%',
    };
  }

  List<Map<String, dynamic>> _buildRowsFromTasks({
    required List<Map<String, dynamic>> tasks,
    required String Function(Map<String, dynamic>) getKey,
    required String Function(Map<String, dynamic>) getLabel,
  }) {
    final map = <String, Map<String, dynamic>>{};

    for (final task in tasks) {
      final key = getKey(task).trim();
      if (key.isEmpty) continue;
      map.putIfAbsent(key, () {
        return {
          'name': getLabel(task),
          'total': 0,
          'overdue': 0,
          'pending': 0,
          'in_progress': 0,
          'in_time': 0,
          'delayed': 0,
          'score': '0.0%',
        };
      });

      final row = map[key]!;
      final stats = _aggregateWebStats([task]);
      row['total'] = (row['total'] as int) + (stats['total'] as int);
      row['overdue'] = (row['overdue'] as int) + (stats['overdue'] as int);
      row['pending'] = (row['pending'] as int) + (stats['pending'] as int);
      row['in_progress'] =
          (row['in_progress'] as int) + (stats['in_progress'] as int);
      row['in_time'] = (row['in_time'] as int) + (stats['in_time'] as int);
      row['delayed'] = (row['delayed'] as int) + (stats['delayed'] as int);
    }

    final rows = map.values.toList();
    for (final row in rows) {
      final total = (row['total'] as int?) ?? 0;
      final inTime = (row['in_time'] as int?) ?? 0;
      final safeTotal = total == 0 ? 1 : total;
      row['score'] = '${((inTime / safeTotal) * 100).toStringAsFixed(1)}%';
    }
    rows.sort((a, b) => (b['total'] as int).compareTo(a['total'] as int));
    return rows;
  }

  Future<List<Map<String, dynamic>>> _buildTableData({
    required String tab,
    required List<Map<String, dynamic>> tasks,
    required String currentUserId,
  }) async {
    switch (tab) {
      case 'Employees':
        final users = await _fetchUsers();
        final rows = users.map((u) {
          final userId = (u['userId'] ?? u['id'] ?? '').toString();
          final userTasks =
              tasks.where((t) => t['doerId']?.toString() == userId).toList();
          final stats = _aggregateWebStats(userTasks);
          final first = (u['firstName'] ?? '').toString().trim();
          final last = (u['lastName'] ?? '').toString().trim();
          final label = '$first $last'.trim().isEmpty ? 'Unknown' : '$first $last'.trim();
          return {
            'name': label,
            ...stats,
          };
        }).toList();
        rows.sort((a, b) => (b['total'] as int).compareTo(a['total'] as int));
        return rows;
      case 'Groups':
        final groups = await _fetchGroups();
        final rows = groups.map((g) {
          final groupId = (g['groupId'] ?? g['id'] ?? '').toString();
          final groupTasks =
              tasks.where((t) => t['groupId']?.toString() == groupId).toList();
          return {
            'name': (g['name'] ?? 'Unknown Group').toString(),
            ..._aggregateWebStats(groupTasks),
          };
        }).toList();
        rows.sort((a, b) => (b['total'] as int).compareTo(a['total'] as int));
        return rows;
      case 'Delegated':
        final delegated =
            tasks.where((t) => t['assignerId']?.toString() == currentUserId).toList();
        return _buildRowsFromTasks(
          tasks: delegated,
          getKey: (t) => (t['doerId'] ?? '').toString(),
          getLabel: (t) {
            final first = (t['doerFirstName'] ?? '').toString().trim();
            final last = (t['doerLastName'] ?? '').toString().trim();
            final label = '$first $last'.trim();
            return label.isEmpty ? 'Unknown' : label;
          },
        );
      case 'My Report':
        final mine =
            tasks.where((t) => t['doerId']?.toString() == currentUserId).toList();
        return _buildRowsFromTasks(
          tasks: mine,
          getKey: (t) => _categoryLabel(t['category']),
          getLabel: (t) => _categoryLabel(t['category']),
        );
      case 'Categories':
        return _buildRowsFromTasks(
          tasks: tasks,
          getKey: (t) => _categoryLabel(t['category']),
          getLabel: (t) => _categoryLabel(t['category']),
        );
      case 'Daily':
        return _buildRowsFromTasks(
          tasks: tasks,
          getKey: (t) {
            final createdAt = _parseDateTime(t['createdAt'] ?? t['date']);
            if (createdAt == null) return 'Unknown Date';
            return '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
          },
          getLabel: (t) {
            final createdAt = _parseDateTime(t['createdAt'] ?? t['date']);
            if (createdAt == null) return 'Unknown Date';
            return '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
          },
        );
      case 'Monthly':
        return _buildRowsFromTasks(
          tasks: tasks,
          getKey: (t) {
            final createdAt = _parseDateTime(t['createdAt'] ?? t['date']);
            if (createdAt == null) return 'Unknown Month';
            return '${_getMonthName(createdAt.month)} ${createdAt.year}';
          },
          getLabel: (t) {
            final createdAt = _parseDateTime(t['createdAt'] ?? t['date']);
            if (createdAt == null) return 'Unknown Month';
            return '${_getMonthName(createdAt.month)} ${createdAt.year}';
          },
        );
      case 'Tags':
        final tagMap = <String, Map<String, dynamic>>{};
        for (final task in tasks) {
          final parsedTags = _extractTagItems(task['tags']);
          final tagKeys = parsedTags.isEmpty ? ['__notag__'] : parsedTags;
          for (final tagKey in tagKeys) {
            tagMap.putIfAbsent(tagKey, () {
              return {
                'name': tagKey == '__notag__' ? 'No Tag' : tagKey,
                'total': 0,
                'overdue': 0,
                'pending': 0,
                'in_progress': 0,
                'in_time': 0,
                'delayed': 0,
                'score': '0.0%',
              };
            });
            final row = tagMap[tagKey]!;
            final stats = _aggregateWebStats([task]);
            row['total'] = (row['total'] as int) + (stats['total'] as int);
            row['overdue'] = (row['overdue'] as int) + (stats['overdue'] as int);
            row['pending'] = (row['pending'] as int) + (stats['pending'] as int);
            row['in_progress'] =
                (row['in_progress'] as int) + (stats['in_progress'] as int);
            row['in_time'] = (row['in_time'] as int) + (stats['in_time'] as int);
            row['delayed'] = (row['delayed'] as int) + (stats['delayed'] as int);
          }
        }
        final rows = tagMap.values.toList();
        for (final row in rows) {
          final total = (row['total'] as int?) ?? 0;
          final inTime = (row['in_time'] as int?) ?? 0;
          final safeTotal = total == 0 ? 1 : total;
          row['score'] = '${((inTime / safeTotal) * 100).toStringAsFixed(1)}%';
        }
        rows.sort((a, b) => (b['total'] as int).compareTo(a['total'] as int));
        return rows;
      default:
        return _buildRowsFromTasks(
          tasks: tasks,
          getKey: (t) => _categoryLabel(t['category']),
          getLabel: (t) => _categoryLabel(t['category']),
        );
    }
  }

  List<String> _extractTagItems(dynamic rawTags) {
    if (rawTags is List) {
      return rawTags.map((e) {
        if (e is Map) {
          final text = e['text']?.toString().trim();
          return (text == null || text.isEmpty) ? e.toString() : text;
        }
        return e.toString();
      }).where((e) => e.trim().isNotEmpty).toList();
    }

    if (rawTags is String && rawTags.trim().isNotEmpty) {
      try {
        final parsed = rawTags.trim();
        if (parsed.startsWith('[')) {
          final decoded = jsonDecode(parsed);
          if (decoded is List) {
            return decoded.map((e) {
              if (e is Map) {
                final text = e['text']?.toString().trim();
                return (text == null || text.isEmpty) ? e.toString() : text;
              }
              return e.toString();
            }).where((e) => e.trim().isNotEmpty).toList();
          }
        }
      } catch (_) {}
      return [rawTags.trim()];
    }

    return const [];
  }
}

