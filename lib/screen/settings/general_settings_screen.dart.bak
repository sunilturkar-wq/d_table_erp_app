import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/settings_provider.dart';
import '../../provider/export_provider.dart';
import 'notifications_reminders_screen.dart';
import 'export_tasks_logs_screen.dart';
import 'role_permission_screen.dart';

class GeneralSettingsScreen extends StatefulWidget {
  const GeneralSettingsScreen({Key? key}) : super(key: key);

  @override
  State<GeneralSettingsScreen> createState() => _GeneralSettingsScreenState();
}

class _GeneralSettingsScreenState extends State<GeneralSettingsScreen> {
  final _companyNameController = TextEditingController();
  late String _selectedIndustry;
  late String _selectedSize;
  bool _remarksEnabled = true;
  bool _attachmentsEnabled = false;
  bool _imagesEnabled = false;

  // Export Tasks Dialog
  String _exportDateRange = 'This Month';
  String? _exportAssignedTo;
  String? _exportAssignedBy;
  String? _exportTaskType;

  final List<String> _industries = [
    'Technology',
    'Healthcare',
    'Finance',
    'Retail',
    'Manufacturing',
    'Other'
  ];

  final List<String> _sizes = [
    '1-10',
    '11-30',
    '31-50',
    '51-100',
    '100-500',
    '500+'
  ];

  @override
  void initState() {
    super.initState();
    // Initialize with defaults
    _selectedIndustry = _industries.first;
    _selectedSize = _sizes.first;
    
    // Load settings when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      settingsProvider.fetchGeneralSettings().then((_) {
        final general = settingsProvider.generalSettings;
        setState(() {
          _companyNameController.text = general['companyName'] ?? '';
          // Validate industry against available options
          final industry = general['businessIndustry'];
          _selectedIndustry = (industry != null && _industries.contains(industry)) 
            ? industry 
            : _industries.first;
          // Validate size against available options
          final size = general['companySize'];
          _selectedSize = (size != null && _sizes.contains(size)) 
            ? size 
            : _sizes.first;
        });
      });
      settingsProvider.fetchTaskUpdateSettings().then((_) {
        final taskSettings = settingsProvider.taskUpdateSettings;
        setState(() {
          _remarksEnabled = taskSettings['remarksRequired'] ?? true;
          _attachmentsEnabled = taskSettings['attachmentsRequired'] ?? false;
          _imagesEnabled = taskSettings['imagesRequired'] ?? false;
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text(
          "GENERAL SETTINGS",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: const Color(0xFF20E19F),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company Info Section
              const Padding(
                padding: EdgeInsets.only(left: 8.0, bottom: 12.0),
                child: Text(
                  "COMPANY INFORMATION",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: Color(0xFF8B95A5),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextField(
                      controller: _companyNameController,
                      decoration: InputDecoration(
                        labelText: 'Company Name',
                        hintText: 'Enter company name',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        floatingLabelStyle: const TextStyle(color: Color(0xFF20E19F)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF20E19F), width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedIndustry,
                      decoration: InputDecoration(
                        labelText: 'Business Industry',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        floatingLabelStyle: const TextStyle(color: Color(0xFF20E19F)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF20E19F), width: 2),
                        ),
                      ),
                      items: _industries.map((industry) {
                        return DropdownMenuItem(
                          value: industry,
                          child: Text(industry),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedIndustry = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedSize,
                      decoration: InputDecoration(
                        labelText: 'Company Size',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        floatingLabelStyle: const TextStyle(color: Color(0xFF20E19F)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF20E19F), width: 2),
                        ),
                      ),
                      items: _sizes.map((size) {
                        return DropdownMenuItem(
                          value: size,
                          child: Text(size),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedSize = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: Consumer<SettingsProvider>(
                        builder: (context, settingsProvider, _) => ElevatedButton(
                          onPressed: () async {
                            final success = await settingsProvider.updateGeneralSettings(
                              companyName: _companyNameController.text,
                              businessIndustry: _selectedIndustry,
                              companySize: _selectedSize,
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(success
                                      ? 'Settings updated successfully'
                                      : 'Error: ${settingsProvider.errorMessage}'),
                                  backgroundColor: success
                                      ? const Color(0xFF20E19F)
                                      : Colors.red,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF20E19F),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: settingsProvider.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Update',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Settings Sections
              const Padding(
                padding: EdgeInsets.only(left: 8.0, bottom: 12.0),
                child: Text(
                  "TASK SETTINGS",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: Color(0xFF8B95A5),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
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
                    _buildSettingsTile('Task Update Settings', Icons.edit_outlined, () {
                      _showTaskUpdateSettingsDialog(context);
                    }),
                    _buildSettingsTile('Notifications & Reminders', Icons.notifications_none_outlined, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsRemindersScreen(),
                        ),
                      );
                    }),
                    _buildSettingsTile('Export Tasks', Icons.download_outlined, () {
                      _showExportTasksDialog(context);
                    }, isLast: true),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Data Management
              const Padding(
                padding: EdgeInsets.only(left: 8.0, bottom: 12.0),
                child: Text(
                  "DATA MANAGEMENT",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: Color(0xFF8B95A5),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
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
                    _buildSettingsTile('Export Tasks Logs', Icons.download_outlined, () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ExportedTasksLogsScreen()));
                    }),
                    _buildSettingsTile('Import Tasks', Icons.upload_outlined, () {}, isLast: true),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Access Control
              const Padding(
                padding: EdgeInsets.only(left: 8.0, bottom: 12.0),
                child: Text(
                  "ACCESS CONTROL",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: Color(0xFF8B95A5),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _buildSettingsTile('Role and Permission', Icons.security_outlined, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const RolePermissionScreen()));
                }, isLast: true),
              ),
              const SizedBox(height: 20),

              // Danger Zone
              const Padding(
                padding: EdgeInsets.only(left: 8.0, bottom: 12.0),
                child: Text(
                  "DANGER ZONE",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _buildDangerTile('Reset Task', Icons.restart_alt, () {
                  _showResetConfirmation(context);
                }),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile(String title, IconData icon, VoidCallback onTap, {bool isLast = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF5E6B81), size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDangerTile(String title, IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFFFEE2E2),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFFDC2626), size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFDC2626), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Task', style: TextStyle(color: Color(0xFFDC2626))),
        content: const Text('Are you sure you want to reset all tasks? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tasks have been reset'),
                  backgroundColor: Color(0xFFDC2626),
                ),
              );
            },
            child: const Text('Reset', style: TextStyle(color: Color(0xFFDC2626))),
          ),
        ],
      ),
    );
  }

  void _showTaskUpdateSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Task Update Settings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'Set Mandatory Fields',
                style: TextStyle(fontSize: 12, color: Color(0xFF8B95A5), fontWeight: FontWeight.w500),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildToggleTile(
                  'Remarks',
                  _remarksEnabled,
                  (value) {
                    setDialogState(() {
                      _remarksEnabled = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildToggleTile(
                  'Attachments',
                  _attachmentsEnabled,
                  (value) {
                    setDialogState(() {
                      _attachmentsEnabled = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildToggleTile(
                  'Images',
                  _imagesEnabled,
                  (value) {
                    setDialogState(() {
                      _imagesEnabled = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                final success = await Provider.of<SettingsProvider>(context, listen: false)
                    .updateTaskUpdateSettings(
                      remarksRequired: _remarksEnabled,
                      attachmentsRequired: _attachmentsEnabled,
                      imagesRequired: _imagesEnabled,
                    );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? 'Task update settings saved successfully'
                          : 'Error saving settings'),
                      backgroundColor: success
                          ? const Color(0xFF20E19F)
                          : Colors.red,
                    ),
                  );
                }
              },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF20E19F),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleTile(String label, bool value, Function(bool) onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF20E19F),
          ),
        ],
      ),
    );
  }

  void _showExportTasksDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Export Tasks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Date Range Dropdown
                DropdownButtonFormField<String>(
                  value: _exportDateRange,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF20E19F), width: 2),
                    ),
                  ),
                  items: ['This Month', 'Last Month', 'Last 3 Months', 'Last 6 Months', 'This Year', 'All Time'].map((date) {
                    return DropdownMenuItem(value: date, child: Text(date));
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() => _exportDateRange = value ?? 'This Month');
                  },
                ),
                const SizedBox(height: 16),

                // Assigned To Dropdown
                DropdownButtonFormField<String>(
                  value: _exportAssignedTo,
                  hint: const Text('Assigned To'),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF20E19F), width: 2),
                    ),
                  ),
                  items: ['All', 'John Doe', 'Jane Smith', 'Mike Johnson'].map((name) {
                    return DropdownMenuItem(value: name, child: Text(name));
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() => _exportAssignedTo = value);
                  },
                ),
                const SizedBox(height: 16),

                // Assigned By Dropdown
                DropdownButtonFormField<String>(
                  value: _exportAssignedBy,
                  hint: const Text('Assigned By'),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF20E19F), width: 2),
                    ),
                  ),
                  items: ['All', 'Admin', 'Manager 1', 'Manager 2'].map((name) {
                    return DropdownMenuItem(value: name, child: Text(name));
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() => _exportAssignedBy = value);
                  },
                ),
                const SizedBox(height: 16),

                // Task Type Dropdown
                DropdownButtonFormField<String>(
                  value: _exportTaskType,
                  hint: const Text('Task Type'),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF20E19F), width: 2),
                    ),
                  ),
                  items: ['All', 'General', 'Urgent', 'Regular', 'Follow-up'].map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() => _exportTaskType = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final exportProvider =
                      Provider.of<ExportProvider>(context, listen: false);
                  final success = await exportProvider.createExport(
                    dateRange: _exportDateRange,
                    assignedTo: _exportAssignedTo != 'All' && _exportAssignedTo != null
                        ? [_exportAssignedTo!]
                        : null,
                    assignedBy: _exportAssignedBy != 'All' && _exportAssignedBy != null
                        ? [_exportAssignedBy!]
                        : null,
                    taskType: _exportTaskType != 'All' && _exportTaskType != null
                        ? [_exportTaskType!]
                        : null,
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success
                            ? 'Tasks exported successfully'
                            : 'Error exporting tasks'),
                        backgroundColor: success
                            ? const Color(0xFF20E19F)
                            : Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF20E19F),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Export Tasks', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    super.dispose();
  }
}
