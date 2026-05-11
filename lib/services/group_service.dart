import 'package:dio/dio.dart';
import '../config/api_constants.dart';
import 'dio_client.dart';

class GroupService {
  final Dio _dio = DioClient().dio;

  Future<List<dynamic>> getMyGroups() async {
    try {
      final response = await _dio.get(ApiConstants.groupsList);
      final data = response.data;
      if (data is Map) return data['data'] ?? [];
      if (data is List) return data;
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createGroup(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiConstants.groupsCreate, data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getGroupById(String id) async {
    try {
      final response = await _dio.get(ApiConstants.groupById(id));
      final data = response.data;
      if (data is Map && data['data'] != null) return Map<String, dynamic>.from(data['data']);
      return Map<String, dynamic>.from(data ?? {});
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getGroupMembers(String id) async {
    try {
      final response = await _dio.get(ApiConstants.groupMembers(id));
      final data = response.data;
      if (data is Map) return data['data'] ?? [];
      if (data is List) return data;
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateGroup(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch(ApiConstants.groupUpdate(id), data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getGroupTasks(String id) async {
    try {
      final response = await _dio.get(ApiConstants.delegations, queryParameters: {'groupId': id});
      final data = response.data;
      if (data is Map) return data['data'] ?? [];
      if (data is List) return data;
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// New method to fetch tasks with full filters matching backend controller
  Future<List<dynamic>> getGroupTasksFiltered(Map<String, dynamic> params) async {
    try {
      final response = await _dio.get(ApiConstants.delegations, queryParameters: params);
      final data = response.data;
      if (data is Map) return data['data'] ?? [];
      if (data is List) return data;
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createGroupTask(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiConstants.delegations, data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}
