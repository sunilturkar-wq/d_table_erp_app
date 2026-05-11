import 'package:dio/dio.dart';
import '../config/api_constants.dart';
import 'dio_client.dart';

class TeamService {
  final Dio _dio = DioClient().dio;

  List<dynamic> _extractList(dynamic responseData, {String key = 'data'}) {
    if (responseData is List) return responseData;
    if (responseData is Map) {
      return List<dynamic>.from(responseData[key] ?? []);
    }
    return [];
  }

  Future<Map<String, dynamic>> createTeam(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiConstants.teams, data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getMyTeamMembers() async {
    try {
      final response = await _dio.get(ApiConstants.myTeamMembers);
      return _extractList(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getTeams() async {
    try {
      final response = await _dio.get(ApiConstants.teams);
      return _extractList(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getTeamMembers(String teamId) async {
    try {
      final response = await _dio.get(ApiConstants.teamMembers(teamId));
      return _extractList(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeTeamMember(String teamId, String userId) async {
    try {
      await _dio.delete('${ApiConstants.teamMembers(teamId)}/$userId');
    } catch (e) {
      rethrow;
    }
  }
}
