import 'package:flutter/material.dart';

import '../model/notification_model.dart';
import '../services/notification_service.dart';
import '../utils/notification_template_helper.dart';

const Map<String, String> kNotificationPreferenceEventLabels = {
  'newTask': 'New Task',
  'newTaskInLoop': 'New Task (In-Loop)',
  'taskEdit': 'Task Edited',
  'taskEditInLoop': 'Task Edited (In-Loop)',
  'taskComment': 'Task Comment',
  'taskCommentInLoop': 'Task Comment (In-Loop)',
  'taskInProgress': 'Task In-Progress',
  'taskInProgressInLoop': 'Task In-Progress (In-Loop)',
  'taskComplete': 'Task Complete',
  'taskCompleteInLoop': 'Task Complete (In-Loop)',
  'taskReOpen': 'Task Re-Open',
  'taskReOpenInLoop': 'Task Re-Open (In-Loop)',
  'dailyPendingReminders': 'Daily Pending Task Reminders',
  'reminderInLoop': 'Task Reminder (In-Loop)',
};

const Map<String, String> kNotificationTemplateEventLabels = {
  'newTask': 'New Task (Assignee)',
  'taskEdit': 'Task Edited (Assignee)',
  'taskComment': 'Task Comment (Assignee)',
  'taskInProgress': 'Task In-Progress (Assignee)',
  'taskComplete': 'Task Complete (Assignee)',
  'taskReOpen': 'Task Re-Open (Assignee)',
  'dailyPendingReminders': 'Daily Pending Reminders',
  'reminder': 'Custom Reminder (Assignee)',
  'newTaskInLoop': 'New Task (In-Loop)',
  'taskEditInLoop': 'Task Edited (In-Loop)',
  'taskCommentInLoop': 'Task Comment (In-Loop)',
  'taskInProgressInLoop': 'Task In-Progress (In-Loop)',
  'taskCompleteInLoop': 'Task Complete (In-Loop)',
  'taskReOpenInLoop': 'Task Re-Open (In-Loop)',
  'reminderInLoop': 'Task Reminder (In-Loop)',
};

const List<String> kNotificationRoles = ['Admin', 'Manager', 'Member'];
const List<String> kNotificationRoleKeys = ['admin', 'manager', 'member'];
const List<String> kNotificationFrequencyOptions = [
  'once',
  'daily',
  'weekly',
  'monthly',
  'yearly',
];

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();

  bool _isLoading = false;
  String? _errorMessage;
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;

  bool whatsappNotifications = false;
  bool emailNotifications = false;
  String timezone = 'Asia/Kolkata';
  String dailyReminderTime = '09:00';
  bool whatsappReminders = false;
  bool emailReminders = false;
  bool dailyTaskReport = false;
  List<String> weeklyOffs = ['Sunday'];
  Map<String, dynamic> notificationChannels = buildDefaultNotificationChannels(
    events: kNotificationPreferenceEventLabels.keys,
    roles: kNotificationRoleKeys,
  );
  Map<String, dynamic> notificationFrequency = buildDefaultNotificationFrequency(
    events: kNotificationPreferenceEventLabels.keys,
    roles: kNotificationRoleKeys,
  );

  Map<String, dynamic>? activeTemplate;
  List<Map<String, dynamic>> _templates = [];
  bool isTemplateLoading = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  List<Map<String, dynamic>> get templates => _templates;

  static const Map<String, String> _legacyEventKeyMap = {
    'custom': 'reminder',
    'inLoopNewTask': 'newTaskInLoop',
    'inLoopTaskEdit': 'taskEditInLoop',
    'inLoopTaskComment': 'taskCommentInLoop',
    'inLoopTaskInProgress': 'taskInProgressInLoop',
    'inLoopTaskComplete': 'taskCompleteInLoop',
    'inLoopTaskReOpen': 'taskReOpenInLoop',
  };

  Map<String, dynamic>? _normalizeTemplate(dynamic rawValue) {
    if (rawValue is! Map) {
      return null;
    }

    final template = Map<String, dynamic>.from(rawValue);
    final hasContent =
        template['id'] != null ||
        (template['subject']?.toString().trim().isNotEmpty ?? false) ||
        (template['body']?.toString().trim().isNotEmpty ?? false);

    if (!hasContent) {
      return null;
    }

    return {
      ...template,
      'subject': template['subject']?.toString() ?? '',
      'body': template['body']?.toString() ?? '',
      'isActive': template['isActive'] ?? true,
    };
  }

  void _syncUnreadCount() {
    _unreadCount = _notifications.where((item) => !item.isRead).length;
  }

  Future<void> fetchNotifications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final rawData = await _service.getMyNotifications();
      final listData = List<dynamic>.from(rawData['data'] ?? []);
      _notifications = listData
          .map((json) => NotificationModel.fromJson(Map<String, dynamic>.from(json)))
          .toList();
      _syncUnreadCount();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchNotificationSettings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _service.getNotificationSettings();
      if (response != null) {
        whatsappNotifications = response['whatsappNotifications'] ?? false;
        emailNotifications = response['emailNotifications'] ?? false;
        timezone = response['timezone'] ?? 'Asia/Kolkata';
        dailyReminderTime = response['dailyReminderTime'] ?? '09:00';
        whatsappReminders = response['whatsappReminders'] ?? false;
        emailReminders = response['emailReminders'] ?? false;
        dailyTaskReport = response['dailyTaskReport'] ?? false;
        weeklyOffs = List<String>.from(response['weeklyOffs'] ?? ['Sunday']);
        notificationChannels = mergeNotificationChannels(
          events: kNotificationPreferenceEventLabels.keys,
          roles: kNotificationRoleKeys,
          rawValue: response['notificationChannels'],
          legacyEventKeyMap: _legacyEventKeyMap,
        );
        notificationFrequency = mergeNotificationFrequency(
          events: kNotificationPreferenceEventLabels.keys,
          roles: kNotificationRoleKeys,
          rawValue: response['notificationFrequency'],
          legacyEventKeyMap: _legacyEventKeyMap,
        );
      } else {
        notificationChannels = buildDefaultNotificationChannels(
          events: kNotificationPreferenceEventLabels.keys,
          roles: kNotificationRoleKeys,
        );
        notificationFrequency = buildDefaultNotificationFrequency(
          events: kNotificationPreferenceEventLabels.keys,
          roles: kNotificationRoleKeys,
        );
      }
    } catch (e) {
      _errorMessage = e.toString();
      notificationChannels = buildDefaultNotificationChannels(
        events: kNotificationPreferenceEventLabels.keys,
        roles: kNotificationRoleKeys,
      );
      notificationFrequency = buildDefaultNotificationFrequency(
        events: kNotificationPreferenceEventLabels.keys,
        roles: kNotificationRoleKeys,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveSettings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final data = {
        'whatsappNotifications': whatsappNotifications,
        'emailNotifications': emailNotifications,
        'timezone': timezone,
        'dailyReminderTime': dailyReminderTime,
        'whatsappReminders': whatsappReminders,
        'emailReminders': emailReminders,
        'dailyTaskReport': dailyTaskReport,
        'weeklyOffs': weeklyOffs,
        'notificationChannels': notificationChannels,
        'notificationFrequency': notificationFrequency,
      };
      await _service.saveNotificationSettings(data);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTemplate(String event, String channel) async {
    isTemplateLoading = true;
    activeTemplate = null;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _service.getTemplate(event, channel);
      if (response != null && response['success'] == true) {
        activeTemplate = _normalizeTemplate(response['data']);
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      isTemplateLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTemplates() async {
    isTemplateLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _templates = await _service
          .getTemplates()
          .then(
            (items) => items
                .map(_normalizeTemplate)
                .whereType<Map<String, dynamic>>()
                .toList(),
          );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      isTemplateLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveTemplate(Map<String, dynamic> data) async {
    isTemplateLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      return await _service.saveTemplate(data);
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      isTemplateLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteTemplate(String id) async {
    isTemplateLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final success = await _service.deleteTemplate(id);
      if (success) {
        _templates.removeWhere((template) => template['id']?.toString() == id);
        if (activeTemplate?['id']?.toString() == id) {
          activeTemplate = null;
        }
      }
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      isTemplateLoading = false;
      notifyListeners();
    }
  }

  void updateGlobal(String key, dynamic value) {
    if (key == 'whatsappNotifications') whatsappNotifications = value;
    if (key == 'emailNotifications') emailNotifications = value;
    if (key == 'timezone') timezone = value;
    if (key == 'whatsappReminders') whatsappReminders = value;
    if (key == 'emailReminders') emailReminders = value;
    if (key == 'dailyTaskReport') dailyTaskReport = value;
    notifyListeners();
  }

  void updateReminderTime(String time) {
    dailyReminderTime = time;
    notifyListeners();
  }

  void toggleWeeklyOff(String day) {
    if (weeklyOffs.contains(day)) {
      weeklyOffs.remove(day);
    } else {
      weeklyOffs.add(day);
    }
    notifyListeners();
  }

  void toggleChannel(String event, String role) {
    if (notificationChannels[event] == null) {
      notificationChannels[event] = {
        'admin': true,
        'manager': true,
        'member': true,
      };
    }
    notificationChannels[event][role] = !(notificationChannels[event][role] ?? true);
    notifyListeners();
  }

  void toggleFrequency(String event, String freq, String role) {
    if (notificationFrequency[role] == null) {
      notificationFrequency[role] = {};
    }
    if (notificationFrequency[role][event] == null) {
      notificationFrequency[role][event] =
          buildDefaultNotificationFrequencyEntry();
    }
    notificationFrequency[role][event][freq] =
        !(notificationFrequency[role][event][freq] ?? false);
    notifyListeners();
  }

  Future<void> markAllAsRead() async {
    try {
      await _service.markAllRead();
      _notifications = _notifications
          .map((item) => item.isRead ? item : item.copyWith(isRead: true))
          .toList();
      _syncUnreadCount();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> markOneAsRead(String id) async {
    try {
      await _service.markOneRead(id);
      _notifications = _notifications
          .map((item) => item.id == id ? item.copyWith(isRead: true) : item)
          .toList();
      _syncUnreadCount();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _service.deleteNotification(id);
      _notifications.removeWhere((item) => item.id == id);
      _syncUnreadCount();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> clearAllNotifications() async {
    try {
      await _service.clearAllNotifications();
      _notifications = [];
      _syncUnreadCount();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
