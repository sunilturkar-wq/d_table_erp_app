import 'package:dio/dio.dart';

import '../config/api_constants.dart';
import 'dio_client.dart';

class NotificationService {
  final Dio _dio = DioClient().dio;

  Future<Map<String, dynamic>> getMyNotifications() async {
    final response = await _dio.get(ApiConstants.notifications);
    return Map<String, dynamic>.from(response.data);
  }

  Future<void> markAllRead() async {
    await _dio.put(
      '${ApiConstants.notifications}/read-all',
      data: <String, dynamic>{},
    );
  }

  Future<void> markOneRead(String id) async {
    await _dio.put(
      '${ApiConstants.notifications}/$id/read',
      data: <String, dynamic>{},
    );
  }

  Future<void> deleteNotification(String id) async {
    await _dio.delete(
      '${ApiConstants.notifications}/$id',
      data: <String, dynamic>{},
    );
  }

  Future<void> clearAllNotifications() async {
    await _dio.delete(
      '${ApiConstants.notifications}/clear-all',
      data: <String, dynamic>{},
    );
  }

  Future<Map<String, dynamic>?> getNotificationSettings() async {
    try {
      final response = await _dio.get(ApiConstants.notificationSettings);
      if (response.data != null && response.data['success'] == true) {
        return Map<String, dynamic>.from(response.data['data'] ?? {});
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> saveNotificationSettings(Map<String, dynamic> data) async {
    await _dio.post(ApiConstants.notificationSettings, data: data);
  }

  Future<Map<String, dynamic>?> getTemplate(String event, String channel) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.notificationTemplates}/$event/$channel',
      );
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getTemplates() async {
    try {
      final response = await _dio.get(ApiConstants.notificationTemplates);
      final data = List<dynamic>.from(response.data['data'] ?? []);
      return data.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> saveTemplate(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(
        ApiConstants.notificationTemplates,
        data: data,
      );
      return response.data['success'] == true;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> deleteTemplate(String id) async {
    try {
      final response = await _dio.delete(
        '${ApiConstants.notificationTemplates}/$id',
      );
      return response.data['success'] == true;
    } catch (e) {
      rethrow;
    }
  }
}
