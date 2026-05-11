import 'package:flutter/material.dart';

import '../services/dio_client.dart';
import '../services/export_service.dart';

class ExportProvider extends ChangeNotifier {
  final ExportService _service = ExportService(DioClient().dio);

  List<Map<String, dynamic>> _exportLogs = [];
  List<Map<String, dynamic>> _allExportLogs = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> get exportLogs => _exportLogs;
  List<Map<String, dynamic>> get allExportLogs => _allExportLogs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchExportLogs() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _service.getExportLogs();
      _exportLogs = List<Map<String, dynamic>>.from(response['logs'] ?? []);
    } catch (e) {
      _errorMessage = e is UnsupportedError
          ? ExportService.unsupportedMessage
          : e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllExportLogs() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _service.getAllExportLogs();
      _allExportLogs = List<Map<String, dynamic>>.from(response['logs'] ?? []);
    } catch (e) {
      _errorMessage = e is UnsupportedError
          ? ExportService.unsupportedMessage
          : e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createExport({
    required String dateRange,
    List<String>? assignedTo,
    List<String>? assignedBy,
    List<String>? taskType,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.createExport(
        dateRange: dateRange,
        assignedTo: assignedTo,
        assignedBy: assignedBy,
        taskType: taskType,
      );
      await fetchExportLogs();
      return true;
    } catch (e) {
      _errorMessage = e is UnsupportedError
          ? ExportService.unsupportedMessage
          : e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> downloadExport(String exportId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _service.downloadExport(exportId);
      return response['data'] as Map<String, dynamic>?;
    } catch (e) {
      _errorMessage = e is UnsupportedError
          ? ExportService.unsupportedMessage
          : e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteExport(String exportId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.deleteExport(exportId);
      await fetchExportLogs();
      return true;
    } catch (e) {
      _errorMessage = e is UnsupportedError
          ? ExportService.unsupportedMessage
          : e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
