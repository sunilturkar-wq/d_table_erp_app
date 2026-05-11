import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hive/hive.dart';

import '../config/api_constants.dart';
import 'dio_client.dart';

class DelegationService {
  final Dio _dio = DioClient().dio;

  Future<List<dynamic>> getAllDelegations() async {
    try {
      final response = await _dio.get(ApiConstants.delegations);
      return response.data['data'];
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getDelegationById(String id) async {
    try {
      final response = await _dio.get('${ApiConstants.delegations}/$id');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getDeletedDelegations() async {
    try {
      final response = await _dio.get(ApiConstants.deletedDelegations);
      return response.data['data'] ?? [];
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createDelegation(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiConstants.delegations, data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateDelegation(String id, Map<String, dynamic> data) async {
    try {
      await _dio.patch('${ApiConstants.delegations}/$id', data: data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteDelegation(String id) async {
    try {
      await _dio.delete('${ApiConstants.delegations}/$id');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> restoreDelegation(String id) async {
    try {
      await _dio.patch(ApiConstants.delegationRestore(id));
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addRemark(String id, String remark, String userId) async {
    try {
      await _dio.post(
        '${ApiConstants.delegations}/$id/remarks',
        data: {
          'remark': remark,
          'userId': userId,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateRemark(String delegationId, String remarkId, String remark) async {
    throw UnsupportedError('Remark editing is not supported by the current backend.');
  }

  Future<void> deleteRemark(String delegationId, String remarkId) async {
    throw UnsupportedError('Remark deletion is not supported by the current backend.');
  }

  Future<String> uploadFile(dynamic file, {String folder = 'general'}) async {
    try {
      late final String fileName;
      late final MultipartFile multipartFile;

      if (file is File) {
        fileName = file.path.split('/').last.split('\\').last;
        multipartFile = await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        );
      } else if (file is PlatformFile) {
        if (file.bytes == null || file.bytes!.isEmpty) {
          throw Exception('Selected file data is unavailable for upload.');
        }
        fileName = file.name.trim().isNotEmpty ? file.name.trim() : 'upload';
        multipartFile = MultipartFile.fromBytes(
          file.bytes!,
          filename: fileName,
        );
      } else {
        throw ArgumentError('Unsupported file type for upload.');
      }

      final uploadDio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: ApiConstants.connectTimeout,
          receiveTimeout: ApiConstants.requestTimeout,
        ),
      );

      final token = Hive.box('settingsBox').get('auth_token');
      final extraHeaders = token != null
          ? {'Authorization': 'Bearer $token'}
          : <String, String>{};

      final formData = FormData.fromMap({
        'file': multipartFile,
      });

      final response = await uploadDio.post(
        '${ApiConstants.delegations}/upload?folder=$folder',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          headers: extraHeaders,
        ),
      );

      return response.data['url'] as String;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateChecklistStatus(String delegationId, String checklistId, String status) async {
    try {
      final detailResponse = await getDelegationById(delegationId);
      final payload = Map<String, dynamic>.from(detailResponse['data'] ?? {});
      final rawChecklist = payload['checklistItems'];
      final checklistItems = (rawChecklist is List)
          ? rawChecklist
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList()
          : <Map<String, dynamic>>[];

      int itemIndex = checklistItems.indexWhere(
        (item) => item['id']?.toString() == checklistId,
      );
      if (itemIndex == -1) {
        final parsedIndex = int.tryParse(checklistId);
        if (parsedIndex != null &&
            parsedIndex >= 0 &&
            parsedIndex < checklistItems.length) {
          itemIndex = parsedIndex;
        }
      }

      if (itemIndex == -1) {
        throw Exception('Checklist item not found');
      }

      final isCompleted = status == 'Completed' || status == 'Done';
      checklistItems[itemIndex]['status'] = status;
      checklistItems[itemIndex]['completed'] = isCompleted;

      await _dio.patch(
        '${ApiConstants.delegations}/$delegationId',
        data: {'checklistItems': checklistItems},
      );
    } catch (e) {
      rethrow;
    }
  }
}
