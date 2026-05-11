import 'package:flutter/material.dart';

import '../services/dio_client.dart';
import '../services/settings_service.dart';

class SettingsProvider extends ChangeNotifier {
  final SettingsService _service = SettingsService(DioClient().dio);
  static const String _unsupportedMessage =
      'These workspace settings are not available in the current backend yet.';

  Map<String, dynamic> _generalSettings = {
    'companyName': '',
    'businessIndustry': '',
    'companySize': ''
  };

  Map<String, dynamic> _taskUpdateSettings = {
    'remarksRequired': true,
    'attachmentsRequired': false,
    'imagesRequired': false
  };

  Map<String, dynamic> _notificationSettings = {
    'whatsappNotifications': false,
    'emailNotifications': false,
    'timezone': 'Asia/Kolkata',
    'dailyReminderTime': '09:00',
    'whatsappReminders': false,
    'emailReminders': false,
    'dailyTaskReport': false,
    'weeklyOffs': ['Sunday'],
    'notificationChannels': {},
    'notificationFrequency': {}
  };

  bool _isLoading = false;
  String? _errorMessage;

  Map<String, dynamic> get generalSettings => _generalSettings;
  Map<String, dynamic> get taskUpdateSettings => _taskUpdateSettings;
  Map<String, dynamic> get notificationSettings => _notificationSettings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchGeneralSettings() async {
    _errorMessage = _unsupportedMessage;
    notifyListeners();
  }

  Future<bool> updateGeneralSettings({
    required String? companyName,
    required String? businessIndustry,
    required String? companySize,
  }) async {
    _errorMessage = _unsupportedMessage;
    notifyListeners();
    return false;
  }

  Future<void> fetchTaskUpdateSettings() async {
    _errorMessage = _unsupportedMessage;
    notifyListeners();
  }

  Future<bool> updateTaskUpdateSettings({
    required bool remarksRequired,
    required bool attachmentsRequired,
    required bool imagesRequired,
  }) async {
    _errorMessage = _unsupportedMessage;
    notifyListeners();
    return false;
  }

  Future<void> fetchNotificationSettings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _service.getNotificationSettings();
      _notificationSettings = {
        'whatsappNotifications': data['whatsappNotifications'] ?? false,
        'emailNotifications': data['emailNotifications'] ?? false,
        'timezone': data['timezone'] ?? 'Asia/Kolkata',
        'dailyReminderTime': data['dailyReminderTime'] ?? '09:00',
        'whatsappReminders': data['whatsappReminders'] ?? false,
        'emailReminders': data['emailReminders'] ?? false,
        'dailyTaskReport': data['dailyTaskReport'] ?? false,
        'weeklyOffs': List<String>.from(data['weeklyOffs'] ?? ['Sunday']),
        'notificationChannels': Map<String, dynamic>.from(
          data['notificationChannels'] ?? {},
        ),
        'notificationFrequency': Map<String, dynamic>.from(
          data['notificationFrequency'] ?? {},
        )
      };
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateNotificationSettings({
    required bool whatsappNotifications,
    required bool emailNotifications,
    required String timezone,
    required String dailyReminderTime,
    required bool whatsappReminders,
    required bool emailReminders,
    required bool dailyTaskReport,
    required List<String> weeklyOffs,
    required Map<String, dynamic> notificationChannels,
    required Map<String, dynamic> notificationFrequency,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final settingsMap = {
        'whatsappNotifications': whatsappNotifications,
        'emailNotifications': emailNotifications,
        'timezone': timezone,
        'dailyReminderTime': dailyReminderTime,
        'whatsappReminders': whatsappReminders,
        'emailReminders': emailReminders,
        'dailyTaskReport': dailyTaskReport,
        'weeklyOffs': weeklyOffs,
        'notificationChannels': notificationChannels,
        'notificationFrequency': notificationFrequency
      };
      await _service.updateNotificationSettings(
        whatsappNotifications: whatsappNotifications,
        emailNotifications: emailNotifications,
        timezone: timezone,
        dailyReminderTime: dailyReminderTime,
        whatsappReminders: whatsappReminders,
        emailReminders: emailReminders,
        dailyTaskReport: dailyTaskReport,
        weeklyOffs: weeklyOffs,
        notificationChannels: notificationChannels,
        notificationFrequency: notificationFrequency,
      );
      _notificationSettings = settingsMap;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> changeCredentials({
    required String userId,
    required String oldPassword,
    required String newPassword,
    String? newEmail,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.changeCredentials(
        userId: userId,
        oldPassword: oldPassword,
        newPassword: newPassword,
        newEmail: newEmail,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllSettings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.wait([
        fetchGeneralSettings(),
        fetchTaskUpdateSettings(),
        fetchNotificationSettings(),
      ]);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
