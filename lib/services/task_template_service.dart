import 'package:dio/dio.dart';
import '../config/api_constants.dart';
import 'dio_client.dart';
import '../model/task_template_model.dart';
import '../model/category_model.dart';

class TaskTemplateService {
  late final Dio _dio;

  TaskTemplateService({Dio? dio}) {
    _dio = dio ?? DioClient().dio;
  }

  Future<List<TaskTemplateModel>> getTemplates() async {
    try {
      final response = await _dio.get(ApiConstants.taskTemplates);
      List<dynamic> data = [];

      if (response.data is List) {
        data = response.data;
      } else if (response.data is Map) {
        if (response.data['templates'] != null) {
          data = response.data['templates'];
        } else if (response.data['data'] != null) {
          data = response.data['data'];
        }
      }

      return data.map((json) => TaskTemplateModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Failed to fetch task templates');
    }
  }

  Future<void> deleteTemplate(String id) async {
    try {
      await _dio.delete('${ApiConstants.taskTemplates}/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Failed to delete template');
    }
  }

  Future<TaskTemplateModel> createTemplate(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiConstants.taskTemplates, data: data);
      
      Map<String, dynamic> resData = {};
      if (response.data is Map) {
         resData = response.data['template'] ?? response.data['data'] ?? response.data;
      }

      return TaskTemplateModel.fromJson(resData);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Failed to create template');
    }
  }

  Future<TaskTemplateModel> updateTemplate(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('${ApiConstants.taskTemplates}/$id', data: data);
      
      Map<String, dynamic> resData = {};
      if (response.data is Map) {
         resData = response.data['template'] ?? response.data['data'] ?? response.data;
      }

      return TaskTemplateModel.fromJson(resData);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Failed to update template');
    }
  }
}
