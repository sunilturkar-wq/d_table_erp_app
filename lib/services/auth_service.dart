import 'dart:io';

import 'package:d_table_erp_app/config/api_constants.dart';
import 'package:d_table_erp_app/services/dio_client.dart';
import 'package:dio/dio.dart';
import '../utils/phone_number_helper.dart';

class AuthService {
  final Dio _dio = DioClient().dio;

  String _errorMessageFromDio(DioException e, String fallback) {
    final responseData = e.response?.data;
    if (responseData is Map && responseData['message'] is String) {
      return responseData['message'] as String;
    }

    if (e.error is SocketException ||
        e.type == DioExceptionType.connectionError) {
      return 'Unable to connect to the backend. '
          'Tried ${DioClient().currentBaseUrl}.';
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Backend timeout. Tried ${DioClient().currentBaseUrl}.';
    }

    return e.message ?? fallback;
  }

  String _healthUrlForApiBase(String apiBaseUrl) {
    return apiBaseUrl.replaceFirst(RegExp(r'/api/?$'), '/health');
  }

  Future<String> diagnoseBackendConnection() async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    final triedUrls = <String>[];
    String? lastError;

    for (final apiBase in ApiConstants.baseUrls.toSet()) {
      final healthUrl = _healthUrlForApiBase(apiBase);
      triedUrls.add(healthUrl);
      try {
        final response = await dio.get(healthUrl);
        if (response.statusCode == 200) {
          return 'Backend reachable at $healthUrl';
        }
      } on DioException catch (e) {
        lastError = _errorMessageFromDio(e, 'Health check failed');
      } catch (e) {
        lastError = e.toString();
      }
    }

    final tried = triedUrls.join(', ');
    if (lastError != null && lastError.isNotEmpty) {
      return 'Backend health check failed. Tried: $tried. Last error: $lastError';
    }
    return 'Backend health check failed. Tried: $tried';
  }

  Future<Map<String, dynamic>> login(String workEmail, String password) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {
          'workEmail': workEmail,
          'password': password,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _errorMessageFromDio(e, 'Login failed');
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiConstants.register, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _errorMessageFromDio(e, 'Signup failed');
    }
  }

  Future<List<dynamic>> getAllUsers() async {
    try {
      final response = await _dio.get(ApiConstants.getAllUser);
      final data = response.data;
      if (data is List) return data;
      if (data is Map) return data['users'] ?? data['data'] ?? [];
      return [];
    } on DioException catch (e) {
      throw _errorMessageFromDio(e, 'Failed to load users');
    }
  }

  Future<Map<String, dynamic>> fetchMe() async {
    try {
      final response = await _dio.get(ApiConstants.me);
      return response.data;
    } on DioException catch (e) {
      throw _errorMessageFromDio(e, 'Failed to fetch user profile');
    }
  }

  Future<Map<String, dynamic>> updateUser(
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put(ApiConstants.userById(userId), data: data);
      return response.data;
    } on DioException catch (e) {
      throw _errorMessageFromDio(e, 'Failed to update user');
    }
  }

  Future<Map<String, dynamic>> updateProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put(ApiConstants.userById(userId), data: data);
      return response.data;
    } on DioException catch (e) {
      throw _errorMessageFromDio(e, 'Failed to update profile');
    }
  }

  Future<Map<String, dynamic>> uploadProfileImage(File file) async {
    try {
      final fileName = file.path.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
      });
      final response = await _dio.post(
        ApiConstants.uploadProfileImage,
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _errorMessageFromDio(e, 'Failed to upload profile image');
    }
  }

  Future<Map<String, dynamic>> updateCredentials(
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put(
        ApiConstants.userCredentials(userId),
        data: data,
      );
      return response.data;
    } on DioException catch (e) {
      throw _errorMessageFromDio(e, 'Failed to update credentials');
    }
  }

  Future<Map<String, dynamic>> changePassword(
    String userId,
    Map<String, String> data,
  ) async {
    try {
      final response = await _dio.put(
        ApiConstants.changePassword(userId),
        data: data,
      );
      return response.data;
    } on DioException catch (e) {
      throw _errorMessageFromDio(e, 'Failed to change password');
    }
  }

  Future<Map<String, dynamic>> deleteUserTasks(
    String userId,
    String confirmEmail,
  ) async {
    try {
      final response = await _dio.delete(
        ApiConstants.userDeleteTasks(userId),
        data: {'confirmEmail': confirmEmail},
      );
      return response.data;
    } on DioException catch (e) {
      throw _errorMessageFromDio(e, 'Failed to delete user tasks');
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _dio.delete(ApiConstants.userById(userId));
    } on DioException catch (e) {
      throw _errorMessageFromDio(e, 'Failed to delete user');
    }
  }

  Future<Map<String, dynamic>> updateTeamMember(
    String memberId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put(ApiConstants.userById(memberId), data: data);
      if (response.data is Map && response.data['data'] != null) {
        return Map<String, dynamic>.from(response.data['data']);
      }
      return Map<String, dynamic>.from(response.data ?? {});
    } on DioException catch (e) {
      throw _errorMessageFromDio(e, 'Failed to update team member');
    }
  }

  Future<Map<String, dynamic>> bulkRegister(
    List<Map<String, dynamic>> users,
  ) async {
    try {
      final normalizedUsers = users.map((user) {
        final normalized = Map<String, dynamic>.from(user);
        if (normalized.containsKey('mobileNumber')) {
          normalized['mobileNumber'] =
              normalizeIndianPhone(normalized['mobileNumber']?.toString());
        }
        return normalized;
      }).toList();

      final response = await _dio.post(
        ApiConstants.bulkRegister,
        data: {'users': normalizedUsers},
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(_errorMessageFromDio(e, 'Failed to bulk register users'));
    }
  }
}
