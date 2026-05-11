import 'dart:convert';
import 'user_model.dart';

class RemarkModel {
  final String id;
  final String remark;
  final String date;
  final String assignedUserId;

  RemarkModel({
    required this.id,
    required this.remark,
    required this.date,
    required this.assignedUserId,
  });

  factory RemarkModel.fromJson(Map<String, dynamic> json) {
    return RemarkModel(
      id: json['id']?.toString() ?? '',
      remark: json['remark'] ?? '',
      date: json['createdAt'] ?? json['date'] ?? '',
      // Backend stores as 'userId', fallback to old keys for safety
      assignedUserId: json['userId'] ?? json['assignedUserId'] ?? json['assigned_user_id'] ?? '',
    );
  }
}

class RevisionModel {
  final String id;
  final String oldStatus;
  final String newStatus;
  final String reason;
  final String changedBy;
  final String createdAt;

  RevisionModel({
    required this.id,
    required this.oldStatus,
    required this.newStatus,
    required this.reason,
    required this.changedBy,
    required this.createdAt,
  });

  factory RevisionModel.fromJson(Map<String, dynamic> json) {
    return RevisionModel(
      id: json['id']?.toString() ?? '',
      oldStatus: json['oldStatus']?.toString() ?? json['old_status']?.toString() ?? '',
      newStatus: json['newStatus']?.toString() ?? json['new_status']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      changedBy: json['changedBy']?.toString() ?? json['changed_by']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? json['created_at']?.toString() ?? '',
    );
  }
}

class DelegationModel {
  static List<String> _parseStringList(dynamic rawValue) {
    if (rawValue is List) {
      return rawValue
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    if (rawValue is String && rawValue.trim().isNotEmpty) {
      final trimmed = rawValue.trim();
      if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
        try {
          final decoded = jsonDecode(trimmed);
          if (decoded is List) {
            return decoded
                .map((item) => item.toString().trim())
                .where((item) => item.isNotEmpty)
                .toList();
          }
        } catch (_) {}
      }

      return trimmed
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    return const [];
  }

  static String normalizeStatus(dynamic rawStatus) {
    final original = rawStatus?.toString().trim() ?? '';
    final status = original.toLowerCase();

    switch (status) {
      case 'completed':
      case 'done':
        return 'Completed';
      case 'in progress':
      case 'in-progress':
      case 'working':
        return 'In Progress';
      case 'overdue':
      case 'over due':
      case 'late':
        return 'Overdue';
      case 'pending':
        return 'Pending';
      default:
        return original.isEmpty ? 'Pending' : original;
    }
  }

  String? id;
  String? parentId;
  String? groupId;
  String delegationName;
  String description;
  String delegatorId;
  String assingDoerId;
  String priority;
  String dueDate;
  String? startDate;
  String status;
  bool evidenceRequired;
  List<RemarkModel> remarks;
  String createdAt;
  String? deletedAt;
  String? deletedBy;
  String deletedByName;

  // Additional fields from backend
  List<String> inLoopIds;
  String category;
  String? asset;
  List<Map<String, dynamic>> checklistItems;
  List<String> tagsList;
  String? evidenceUrl;
  List<RevisionModel> revisionHistory;
  List<DelegationModel> subtasks;

  // Media & references
  String? voiceNoteUrl;       // uploaded voice recording URL
  List<String> referenceDocs; // uploaded attachment URLs
  String? reminderAt;         // ISO string of reminder time (stored in tags)
  List<Map<String, dynamic>> reminders;
  
  // Recurrence
  bool isRecurring;
  String? recurringFrequency;
  int? recurringInterval;
  String? recurringType;
  List<String> recurringDays;
  int? periodicallyDays;

  // Backend se directly aane wale names (list API se)
  String delegatorName;
  String assigneeName;

  DelegationModel({
    this.id,
    this.parentId,
    this.groupId,
    required this.delegationName,
    required this.description,
    required this.delegatorId,
    required this.assingDoerId,
    required this.priority,
    required this.dueDate,
    this.startDate,
    this.status = "Pending",
    this.evidenceRequired = false,
    this.remarks = const [],
    this.inLoopIds = const [],
    this.category = "General",
    this.checklistItems = const [],
    this.tagsList = const [],
    this.evidenceUrl,
    this.revisionHistory = const [],
    this.subtasks = const [],
    this.delegatorName = '',
    this.assigneeName = '',
    this.asset,
    this.voiceNoteUrl,
    this.referenceDocs = const [],
    this.reminderAt,
    this.reminders = const [],
    this.isRecurring = false,
    this.recurringFrequency,
    this.recurringInterval,
    this.recurringType,
    this.recurringDays = const [],
    this.periodicallyDays,
    this.createdAt = '',
    this.deletedAt,
    this.deletedBy,
    this.deletedByName = '',
  });

  factory DelegationModel.fromJson(Map<String, dynamic> json) {
    var list = json['remarks'] as List? ?? [];
    List<RemarkModel> remarksList =
        list.map((i) => RemarkModel.fromJson(i as Map<String, dynamic>)).toList();

    var inLoop = json['inLoopIds'] ?? json['in_loop_ids'] ?? [];
    List<String> inLoopList = [];
    if (inLoop is List) {
      inLoopList = inLoop.map((i) => i.toString()).toList();
    } else if (inLoop is String && inLoop.isNotEmpty) {
      if (inLoop.startsWith('[')) {
        try {
          final List decoded = jsonDecode(inLoop);
          inLoopList = decoded.map((i) => i.toString()).toList();
        } catch (_) {}
      } else {
        inLoopList = inLoop.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
    }

    final rawChecklist = json['checklistItems'] ?? json['checklist_items'];
    List<Map<String, dynamic>> checklistItemsList = [];
    if (rawChecklist is List) {
      checklistItemsList = rawChecklist
          .whereType<Map>()
          .map((i) => Map<String, dynamic>.from(i))
          .toList();
    } else if (rawChecklist is String && rawChecklist.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawChecklist);
        if (decoded is List) {
          checklistItemsList = decoded
              .whereType<Map>()
              .map((i) => Map<String, dynamic>.from(i))
              .toList();
        }
      } catch (_) {}
    }

    // Backend se direct names parse karo
    final delegatorFirst = json['delegatorFirstName'] ?? json['delegator_first_name'] ?? '';
    final delegatorLast = json['delegatorLastName'] ?? json['delegator_last_name'] ?? '';
    final assigneeFirst = json['assigneeFirstName'] ??
        json['assignee_first_name'] ??
        json['doerFirstName'] ??
        json['doer_first_name'] ??
        '';
    final assigneeLast = json['assigneeLastName'] ??
        json['assignee_last_name'] ??
        json['doerLastName'] ??
        json['doer_last_name'] ??
        '';
    final deletedByFirst = json['deletedByFirstName'] ?? json['deleted_by_first_name'] ?? '';
    final deletedByLast = json['deletedByLastName'] ?? json['deleted_by_last_name'] ?? '';

    // Parse referenceDocs — stored as JSON string or list
    final rawRefDocs = json['referenceDocs'] ?? json['reference_docs'];
    final refDocsList = _parseStringList(rawRefDocs);

    // Parse reminderAt from tags jsonb and also parse text tags
    String? reminderAt;
    List<String> tagsList = [];
    final rawTags = json['tags'];
    if (rawTags is Map) {
      reminderAt = rawTags['reminderAt']?.toString();
    } else if (rawTags is List) {
      tagsList = rawTags.map((e) {
        if (e is Map) {
          final text = e['text']?.toString().trim();
          if (text != null && text.isNotEmpty) return text;
        }
        return e.toString();
      }).where((e) => e.trim().isNotEmpty).toList();
    } else if (rawTags is String && rawTags.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawTags);
        if (decoded is List) {
          tagsList = decoded.map((e) {
            if (e is Map) {
              final text = e['text']?.toString().trim();
              if (text != null && text.isNotEmpty) return text;
            }
            return e.toString();
          }).where((e) => e.trim().isNotEmpty).toList();
        } else {
          tagsList = rawTags
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      } catch (_) {}
    }

    final rawRevisionHistory = json['revision_history'];
    List<RevisionModel> revisionHistory = [];
    if (rawRevisionHistory is List) {
      revisionHistory = rawRevisionHistory
          .whereType<Map>()
          .map((e) => RevisionModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    final rawSubtasks = json['subtasks'];
    List<DelegationModel> subtasks = [];
    if (rawSubtasks is List) {
      subtasks = rawSubtasks
          .whereType<Map>()
          .map((e) => DelegationModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    final rawReminders = json['reminders'];
    List<Map<String, dynamic>> reminders = [];
    if (rawReminders is List) {
      reminders = rawReminders
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } else if (rawReminders is String && rawReminders.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawReminders);
        if (decoded is List) {
          reminders = decoded
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      } catch (_) {}
    }

    return DelegationModel(
      id: json['id']?.toString(),
      parentId: json['parentId']?.toString() ?? json['parent_id']?.toString(),
      groupId: json['groupId']?.toString() ?? json['group_id']?.toString(),
      delegationName: json['taskTitle'] ?? json['task_title'] ?? json['delegationName'] ?? json['delegation_name'] ?? '',
      description: json['description'] ?? '',
      delegatorId: json['assignerId'] ?? json['assigner_id'] ?? json['delegatorId'] ?? json['delegator_id'] ?? '',
      assingDoerId: json['doerId'] ?? json['doer_id'] ?? json['assingDoerId'] ?? json['assing_doer_id'] ?? '',
      priority: json['priority'] ?? 'Medium',
      dueDate: json['dueDate'] ?? json['due_date'] ?? '',
      startDate: json['startDate'] ?? json['start_date'],
      status: normalizeStatus(json['status']),
      evidenceRequired: json['evidenceRequired'] == true || json['evidence_required'] == true || json['evidenceRequired'] == 1 || json['evidence_required'] == 1,
      remarks: remarksList,
      inLoopIds: inLoopList,
      category: json['category'] ?? 'General',
      checklistItems: checklistItemsList,
      tagsList: tagsList,
      evidenceUrl: json['evidenceUrl'] ?? json['evidence_url'],
      revisionHistory: revisionHistory,
      subtasks: subtasks,
      delegatorName: '$delegatorFirst $delegatorLast'.trim(),
      assigneeName: '$assigneeFirst $assigneeLast'.trim(),
      asset: json['asset'],
      voiceNoteUrl: json['voiceNoteUrl'] ?? json['voice_note_url'],
      referenceDocs: refDocsList,
      reminderAt: reminderAt,
      reminders: reminders,
      isRecurring: json['isRecurring'] == true || json['is_recurring'] == true,
      recurringFrequency: json['recurringFrequency'] ?? json['recurring_frequency'],
      recurringInterval: json['recurringInterval'] ?? json['recurring_interval'],
      recurringType: json['recurringType'] ?? json['recurring_type'],
      recurringDays: (json['recurringDays'] is List) ? List<String>.from(json['recurringDays']) : [],
      periodicallyDays: json['periodicallyDays'] ?? json['periodically_days'],
      createdAt: json['createdAt'] ?? json['created_at'] ?? json['date'] ?? '',
      deletedAt: json['deletedAt']?.toString() ?? json['deleted_at']?.toString(),
      deletedBy: json['deletedBy']?.toString() ?? json['deleted_by']?.toString(),
      deletedByName: '$deletedByFirst $deletedByLast'.trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "taskTitle": delegationName,
      if (parentId != null) "parentId": parentId,
      if (groupId != null) "groupId": groupId,
      "description": description,
      "assignerId": delegatorId,
      "doerId": assingDoerId,
      "priority": priority,
      "dueDate": dueDate,
      "startDate": startDate,
      "status": status,
      "evidenceRequired": evidenceRequired,
      "inLoopIds": inLoopIds,
      "category": category,
      "checklistItems": checklistItems,
      "asset": asset,
      if (evidenceUrl != null) "evidenceUrl": evidenceUrl,
      if (voiceNoteUrl != null) "voiceNoteUrl": voiceNoteUrl,
      if (referenceDocs.isNotEmpty) "referenceDocs": referenceDocs,
      if (reminderAt != null) "tags": {"reminderAt": reminderAt},
      if (reminders.isNotEmpty) "reminders": reminders,
      "isRecurring": isRecurring,
      if (recurringFrequency != null) "recurringFrequency": recurringFrequency,
      if (recurringInterval != null) "recurringInterval": recurringInterval,
      if (recurringType != null) "recurringType": recurringType,
      if (recurringDays.isNotEmpty) "recurringDays": recurringDays,
      if (periodicallyDays != null) "periodicallyDays": periodicallyDays,
    };
  }

  // Backend se naam directly use karo, fallback users list se
  String getAssignedToName(List<UserModel> users) {
    if (assigneeName.isNotEmpty) return assigneeName;
    try {
      return users.firstWhere((u) => u.id == assingDoerId).fullName;
    } catch (e) {
      return assingDoerId;
    }
  }

  String getAssignedByName(List<UserModel> users) {
    if (delegatorName.isNotEmpty) return delegatorName;
    try {
      return users.firstWhere((u) => u.id == delegatorId).fullName;
    } catch (e) {
      return delegatorId;
    }
  }
}
