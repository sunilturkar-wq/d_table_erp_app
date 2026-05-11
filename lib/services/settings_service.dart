import 'package:dio/dio.dart';

import '../config/api_constants.dart';

class SettingsService {
  final Dio _dio;
  static const String _unsupportedMessage =
      'These settings are not supported by the current backend.';

  SettingsService(this._dio);

  Future<Map<String, dynamic>> getGeneralSettings() async {
    throw UnsupportedError(_unsupportedMessage);
  }

  Future<Map<String, dynamic>> updateGeneralSettings({
    required String? companyName,
    required String? businessIndustry,
    required String? companySize,
  }) async {
    throw UnsupportedError(_unsupportedMessage);
  }

  Future<Map<String, dynamic>> getTaskUpdateSettings() async {
    throw UnsupportedError(_unsupportedMessage);
  }

  Future<Map<String, dynamic>> updateTaskUpdateSettings({
    required bool remarksRequired,
    required bool attachmentsRequired,
    required bool imagesRequired,
  }) async {
    throw UnsupportedError(_unsupportedMessage);
  }

  Future<Map<String, dynamic>> getNotificationSettings() async {
    try {
      final response = await _dio.get(ApiConstants.notificationSettings);
      return Map<String, dynamic>.from(response.data['data'] ?? {});
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateNotificationSettings({
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
    try {
      final response = await _dio.post(
        ApiConstants.notificationSettings,
        data: {
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
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> changeCredentials({
    required String userId,
    required String oldPassword,
    required String newPassword,
    String? newEmail,
  }) async {
    try {
      final response = await _dio.put(
        '/auth/users/$userId/credentials',
        data: {
          'oldPassword': oldPassword,
          'newPassword': newPassword,
          if (newEmail != null) 'newEmail': newEmail,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}
