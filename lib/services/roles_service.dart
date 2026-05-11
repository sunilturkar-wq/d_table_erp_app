import 'package:dio/dio.dart';

import '../config/api_constants.dart';

class RolesService {
  final Dio _dio;

  RolesService(this._dio);

  Future<List<dynamic>> getAllRoles() async {
    final response = await _dio.get(ApiConstants.roles);
    if (response.data is List) {
      return response.data as List<dynamic>;
    }
    if (response.data is Map) {
      final data = response.data as Map;
      return List<dynamic>.from(data['data'] ?? data['roles'] ?? []);
    }
    return <dynamic>[];
  }

  Future<Map<String, dynamic>> getRoleWithPermissions(String roleId) async {
    final roles = await getAllRoles();
    final matched = roles.cast<dynamic>().firstWhere(
      (role) => role is Map && role['id']?.toString() == roleId,
      orElse: () => <String, dynamic>{},
    );
    return Map<String, dynamic>.from(matched as Map);
  }

  Future<Map<String, dynamic>> createRole({
    required String name,
    required String? description,
    Map<String, dynamic>? permissions,
  }) async {
    final response = await _dio.post(
      ApiConstants.roles,
      data: {
        'name': name.trim(),
        'description': description?.trim().isEmpty == true ? null : description?.trim(),
        if (permissions != null) 'permissions': permissions,
      },
    );
    return Map<String, dynamic>.from(response.data ?? {});
  }

  Future<Map<String, dynamic>> updateRole({
    required String roleId,
    required String name,
    required String? description,
    Map<String, dynamic>? permissions,
  }) async {
    final response = await _dio.put(
      '${ApiConstants.roles}/$roleId',
      data: {
        'name': name.trim(),
        'description': description?.trim().isEmpty == true ? null : description?.trim(),
        if (permissions != null) 'permissions': permissions,
      },
    );
    return Map<String, dynamic>.from(response.data ?? {});
  }

  Future<Map<String, dynamic>> deleteRole(String roleId) async {
    final response = await _dio.delete(
      '${ApiConstants.roles}/$roleId',
      data: <String, dynamic>{},
    );
    return Map<String, dynamic>.from(response.data ?? {});
  }

  Future<Map<String, dynamic>> updateRolePermissions({
    required String roleId,
    required Map<String, dynamic> permissions,
  }) async {
    final response = await _dio.put(
      '${ApiConstants.roles}/$roleId',
      data: {
        'permissions': permissions,
      },
    );
    return Map<String, dynamic>.from(response.data ?? {});
  }
}
