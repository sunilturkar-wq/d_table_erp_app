import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/export_provider.dart';

class ExportedTasksLogsScreen extends StatefulWidget {
  const ExportedTasksLogsScreen({Key? key}) : super(key: key);

  @override
  State<ExportedTasksLogsScreen> createState() =>
      _ExportedTasksLogsScreenState();
}

class _ExportedTasksLogsScreenState extends State<ExportedTasksLogsScreen> {
  @override
  void initState() {
    super.initState();
    // Load export logs when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExportProvider>().fetchExportLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "EXPORT TASKS LOGS",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: const Color(0xFF003366),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<ExportProvider>(
        builder: (context, exportProvider, _) {
          if (exportProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (exportProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${exportProvider.errorMessage}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      exportProvider.fetchExportLogs();
                      exportProvider.clearError();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Note
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFDC2626)),
                    ),
                    child: const Text(
                      'Note: Logs older than 60 days are automatically deleted',
                      style: TextStyle(
                        color: Color(0xFFDC2626),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Table or Empty State
                  if (exportProvider.exportLogs.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32.0),
                        child: Column(
                          children: const [
                            Icon(
                              Icons.inbox_outlined,
                              size: 48,
                              color: Color(0xFFCBD5E1),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No export logs yet',
                              style: TextStyle(
                                color: Color(0xFF8B95A5),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Header
                            Container(
                              color: const Color(0xFF003366),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Exported At',
                                      style: _headerStyle(),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Exported By',
                                      style: _headerStyle(),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text('Info', style: _headerStyle()),
                                  ),
                                  Expanded(
                                    child: Text(
                                      'Action',
                                      style: _headerStyle(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Rows
                            ...exportProvider.exportLogs.asMap().entries.map((
                              entry,
                            ) {
                              int index = entry.key;
                              Map<String, dynamic> log = entry.value;
                              bool isLast =
                                  index == exportProvider.exportLogs.length - 1;
                              return Container(
                                decoration: BoxDecoration(
                                  border: isLast
                                      ? null
                                      : Border(
                                          bottom: BorderSide(
                                            color: Colors.grey.withOpacity(0.1),
                                          ),
                                        ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        log['createdAt'] ?? 'N/A',
                                        style: _rowStyle(),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        log['exportedBy'] ?? 'Unknown',
                                        style: _rowStyle(),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Date Range: ${log['dateRange'] ?? 'N/A'}',
                                            style: _infoStyle(),
                                          ),
                                          Text(
                                            'Format: ${log['exportFormat'] ?? 'N/A'}',
                                            style: _infoStyle(),
                                          ),
                                          Text(
                                            'Size: ${(log['fileSize'] ?? 0) ~/ 1024} KB',
                                            style: _infoStyle(),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.download,
                                              size: 18,
                                              color: Color(0xFF003366),
                                            ),
                                            onPressed: () =>
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Download started',
                                                    ),
                                                    backgroundColor: Color(
                                                      0xFF003366,
                                                    ),
                                                  ),
                                                ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              size: 18,
                                              color: Colors.red,
                                            ),
                                            onPressed: () =>
                                                _showDeleteConfirmation(
                                                  context,
                                                  log['id'],
                                                  exportProvider,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    String exportId,
    ExportProvider exportProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Export Log'),
        content: const Text('Are you sure you want to delete this export log?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              exportProvider.deleteExport(exportId).then((success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'Export deleted' : 'Error deleting export',
                    ),
                    backgroundColor: success
                        ? const Color(0xFF003366)
                        : Colors.red,
                  ),
                );
              });
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  TextStyle _headerStyle() => const TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
    fontSize: 12,
  );
  TextStyle _rowStyle() => const TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: Color(0xFF334155),
  );
  TextStyle _infoStyle() =>
      const TextStyle(fontSize: 11, color: Color(0xFF6B7280), height: 1.5);
}
