import 'package:d_table_erp_app/config/api_constants.dart';
import 'package:d_table_erp_app/model/user_model.dart';
import 'package:d_table_erp_app/services/dio_client.dart';
import 'package:dio/dio.dart';

class UserService {
  final Dio _dio = DioClient().dio;

  /// GET /auth/users — returns direct array in new backend
  Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await _dio.get(ApiConstants.getAllUser);
      final dynamic responseData = response.data;
      List<dynamic> usersList = [];
      if (responseData is Map) {
        usersList = responseData['users'] ?? responseData['data'] ?? [];
      } else if (responseData is List) {
        usersList = responseData;
      }
      return usersList.map((u) => UserModel.fromJson(u)).toList();
    } catch (e) {
      print("❌ User Service Error: $e");
      rethrow;
    }
  }

  /// GET /teams/my-members — replaced old /auth/my-team
  Future<List<UserModel>> getMyTeam() async {
    try {
      final response = await _dio.get(ApiConstants.myTeamMembers);
      final dynamic responseData = response.data;
      List<dynamic> usersList = [];
      if (responseData is Map) {
        usersList = responseData['members'] ?? responseData['data'] ?? responseData['users'] ?? [];
      } else if (responseData is List) {
        usersList = responseData;
      }
      return usersList.map((u) => UserModel.fromJson(u)).toList();
    } catch (e) {
      print("❌ User Service Error (Team): $e");
      rethrow;
    }
  }

  /// GET /auth/users/:userId — get single user details
  Future<Map<String, dynamic>> getUserById(String userId) async {
    try {
      final response = await _dio.get(ApiConstants.userById(userId));
      final data = response.data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return {};
    } catch (e) {
      print("❌ Get User Error: $e");
      rethrow;
    }
  }
}
