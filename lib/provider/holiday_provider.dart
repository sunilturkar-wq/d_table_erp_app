import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../config/api_constants.dart';
import '../services/dio_client.dart';

class HolidayProvider with ChangeNotifier {
  HolidayProvider();

  final Dio _dio = DioClient().dio;

  List<dynamic> _holidays = [];
  bool _isLoading = false;
  String? _error;

  List<dynamic> get holidays => _holidays;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchHolidays() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _dio.get(ApiConstants.holidays);
      if (response.data is List) {
        _holidays = List<dynamic>.from(response.data);
      } else if (response.data is Map && response.data['holidays'] is List) {
        _holidays = List<dynamic>.from(response.data['holidays']);
      } else {
        _holidays = [];
      }
    } on DioException catch (e) {
      _error = _extractError(
        e.response?.data,
        e.message ?? 'Failed to fetch holidays',
      );
    } catch (_) {
      _error = 'Failed to fetch holidays';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addHoliday(String name, String date) async {
    return addHolidays([
      {'name': name, 'date': date},
    ]);
  }

  Future<bool> addHolidays(List<Map<String, String>> holidays) async {
    try {
      _error = null;
      final payload = holidays
          .where(
            (holiday) =>
                (holiday['name'] ?? '').trim().isNotEmpty &&
                (holiday['date'] ?? '').trim().isNotEmpty,
          )
          .map(
            (holiday) => {
              'name': holiday['name']!.trim(),
              'date': holiday['date']!.trim(),
            },
          )
          .toList();

      if (payload.isEmpty) {
        _error = 'Please add at least one valid holiday';
        notifyListeners();
        return false;
      }

      final response = await _dio.post(ApiConstants.holidays, data: payload);
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchHolidays();
        return true;
      }

      _error = 'Failed to add holidays';
      notifyListeners();
      return false;
    } on DioException catch (e) {
      _error = _extractError(e.response?.data, 'Failed to add holidays');
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Failed to add holidays';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteHoliday(String id) async {
    try {
      _error = null;
      final response = await _dio.delete(
        '${ApiConstants.holidays}/$id',
        data: const <String, dynamic>{},
      );

      if (response.statusCode == 200) {
        _holidays = _holidays
            .where((holiday) => holiday['id'].toString() != id.toString())
            .toList();
        notifyListeners();
        return true;
      }

      _error = 'Failed to delete holiday';
      notifyListeners();
      return false;
    } on DioException catch (e) {
      _error = _extractError(e.response?.data, 'Failed to delete holiday');
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Failed to delete holiday';
      notifyListeners();
      return false;
    }
  }

  String _extractError(dynamic data, String fallback) {
    if (data is Map) {
      final message = data['message'] ?? data['error'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }
    return fallback;
  }
}
