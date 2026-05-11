class ExportService {
  static const String unsupportedMessage =
      'Task export is not available in the current backend.';

  ExportService(dynamic dio);

  Future<Map<String, dynamic>> createExport({
    required String dateRange,
    required List<String>? assignedTo,
    required List<String>? assignedBy,
    required List<String>? taskType,
  }) async {
    throw UnsupportedError(unsupportedMessage);
  }

  Future<Map<String, dynamic>> getExportLogs() async {
    throw UnsupportedError(unsupportedMessage);
  }

  Future<Map<String, dynamic>> getAllExportLogs() async {
    throw UnsupportedError(unsupportedMessage);
  }

  Future<Map<String, dynamic>> downloadExport(String exportId) async {
    throw UnsupportedError(unsupportedMessage);
  }

  Future<Map<String, dynamic>> deleteExport(String exportId) async {
    throw UnsupportedError(unsupportedMessage);
  }
}
