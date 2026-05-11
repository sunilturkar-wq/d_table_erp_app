import 'package:dio/dio.dart';
import '../config/api_constants.dart';
import 'dio_client.dart';
import '../model/activity_model.dart';
import '../model/user_model.dart';

class ActivityService {
  late final Dio _dio;

  ActivityService({Dio? dio}) {
    _dio = dio ?? DioClient().dio;
  }

  Future<List<ActivityModel>> getActivities({
    String? userId,
    String? startDate,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (userId != null && userId != 'Updated By') queryParams['userId'] = userId;
      if (startDate != null) queryParams['startDate'] = startDate;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _dio.get(ApiConstants.activities, queryParameters: queryParams);
      List<dynamic> data = [];

      if (response.data is List) {
        data = response.data;
      } else if (response.data is Map && response.data['data'] is List) {
        data = response.data['data'];
      } else if (response.data is Map && response.data['activities'] is List) {
        data = response.data['activities'];
      }

      return data.map((json) => ActivityModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Failed to fetch activities: ${e.message}');
    }
  }

  Future<List<UserModel>> getUsers() async {
    try {
      final response = await _dio.get(ApiConstants.getAllUser);
      List<dynamic> rawData = [];
      if (response.data is List) {
        rawData = response.data;
      } else if (response.data is Map && response.data['users'] != null) {
        rawData = response.data['users'];
      } else if (response.data is Map && response.data['data'] != null) {
         rawData = response.data['data'];
      }
      return rawData.map((e) => UserModel.fromJson(e)).toList();
    } catch (e) {
       return [];
    }
  }
}
