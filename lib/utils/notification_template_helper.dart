const String kNotificationEmailSenderName = 'RLD Group';

Map<String, bool> buildDefaultNotificationFrequencyEntry() => {
      'once': true,
      'daily': false,
      'weekly': false,
      'monthly': false,
      'yearly': false,
    };

Map<String, dynamic> buildDefaultNotificationChannels({
  required Iterable<String> events,
  required Iterable<String> roles,
}) => {
      for (final event in events)
        event: {
          for (final role in roles) role: true,
        },
    };

Map<String, dynamic> buildDefaultNotificationFrequency({
  required Iterable<String> events,
  required Iterable<String> roles,
}) => {
      for (final role in roles)
        role: {
          for (final event in events) event: buildDefaultNotificationFrequencyEntry(),
        },
    };

Map<String, dynamic> mergeNotificationChannels({
  required Iterable<String> events,
  required Iterable<String> roles,
  required dynamic rawValue,
  Map<String, String> legacyEventKeyMap = const {},
}) {
  final normalized = buildDefaultNotificationChannels(
    events: events,
    roles: roles,
  );
  if (rawValue is! Map) {
    return normalized;
  }

  final rawMap = Map<String, dynamic>.from(rawValue);
  for (final entry in rawMap.entries) {
    final eventKey = legacyEventKeyMap[entry.key] ?? entry.key;
    if (!normalized.containsKey(eventKey) || entry.value is! Map) {
      continue;
    }

    final mergedEvent = Map<String, dynamic>.from(normalized[eventKey] as Map);
    final roleMap = Map<String, dynamic>.from(entry.value as Map);
    for (final role in roles) {
      mergedEvent[role] = roleMap[role] ?? mergedEvent[role];
    }
    normalized[eventKey] = mergedEvent;
  }

  return normalized;
}

Map<String, dynamic> mergeNotificationFrequency({
  required Iterable<String> events,
  required Iterable<String> roles,
  required dynamic rawValue,
  Map<String, String> legacyEventKeyMap = const {},
}) {
  final normalized = buildDefaultNotificationFrequency(
    events: events,
    roles: roles,
  );
  if (rawValue is String || rawValue is! Map) {
    return normalized;
  }

  final rawMap = Map<String, dynamic>.from(rawValue);
  for (final role in roles) {
    final roleValue = rawMap[role];
    if (roleValue is! Map) {
      continue;
    }

    final mergedRole = Map<String, dynamic>.from(normalized[role] as Map);
    final roleMap = Map<String, dynamic>.from(roleValue);
    for (final eventEntry in roleMap.entries) {
      final eventKey = legacyEventKeyMap[eventEntry.key] ?? eventEntry.key;
      if (!mergedRole.containsKey(eventKey) || eventEntry.value is! Map) {
        continue;
      }

      final mergedEvent = Map<String, dynamic>.from(
        mergedRole[eventKey] as Map,
      );
      final eventMap = Map<String, dynamic>.from(eventEntry.value as Map);
      for (final frequency in buildDefaultNotificationFrequencyEntry().keys) {
        mergedEvent[frequency] = eventMap[frequency] ?? mergedEvent[frequency];
      }
      mergedRole[eventKey] = mergedEvent;
    }

    normalized[role] = mergedRole;
  }

  return normalized;
}

String replaceNotificationTemplatePlaceholders(
  String template,
  Map<String, dynamic> data,
) {
  if (template.trim().isEmpty) {
    return '';
  }

  return template.replaceAllMapped(RegExp(r'\{([^{}]+)\}'), (match) {
    final cleanKey = match.group(1)?.trim() ?? '';
    final value = data[cleanKey];
    if (value == null) {
      return '';
    }

    final normalized = value.toString();
    if (normalized.trim().isEmpty) {
      return '';
    }

    return normalized;
  });
}

Map<String, String> buildNotificationTemplatePreviewData({
  required String eventLabel,
  required String channel,
}) {
  final isWhatsApp = channel.toLowerCase() == 'whatsapp';
  return {
    'taskId': 'TASK-241',
    'taskTitle': 'Quarterly sales follow-up',
    'taskDescription': 'Review pending client updates and close open actions.',
    'priority': 'High',
    'category': 'Sales',
    'dueDate': '12 Apr 2026, 05:30 PM',
    'assignerName': 'Ravi Sharma',
    'doerName': 'Neha Singh',
    'updatedBy': 'Aman Verma',
    'status': 'In Progress',
    'remark': 'Client callback moved to the evening slot.',
    'commenterName': 'Priya Patel',
    'taskList': '1. Review pending tasks\n2. Follow up with assignee\n3. Close completed items',
    'frequency': 'Weekly',
    'startDate': '10 Apr 2026',
    'endDate': '30 Apr 2026',
    'voiceNoteUrl': 'https://rld-group.example/audio/task-241',
    'referenceDocs': 'https://rld-group.example/docs/task-241',
    'evidenceUrl': 'https://rld-group.example/evidence/task-241',
    'eventLabel': eventLabel,
    'channelLabel': isWhatsApp ? 'WhatsApp' : 'Email',
  };
}
