import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:d_table_erp_app/model/delegate_model.dart';
import 'package:d_table_erp_app/model/user_model.dart';
import 'package:d_table_erp_app/provider/auth_provider.dart';
import 'package:d_table_erp_app/provider/delegation_provider.dart';
import 'package:d_table_erp_app/provider/theme_provider.dart';
import 'package:d_table_erp_app/provider/user_provider.dart';
import 'package:d_table_erp_app/provider/category_provider.dart';
import 'package:d_table_erp_app/services/local_notification_service.dart';
import 'package:d_table_erp_app/widget/app_dropdown.dart';

class AssignTaskSheet extends StatefulWidget {
  const AssignTaskSheet({super.key});

  @override
  State<AssignTaskSheet> createState() => _AssignTaskSheetState();
}

class _AssignTaskSheetState extends State<AssignTaskSheet>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _checklistController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController(); // ← Remark field
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _descFocus = FocusNode();

  bool _assignMoreTask = false;
  bool _repeat = false;
  String _repeatFrequency = 'Daily';
  bool _isSubmitting = false;

  UserModel? _selectedDoer;
  DateTime? _startDate;
  DateTime? _endDate;
  String _priority = 'High';
  String _category = 'General';
  String _status = 'Pending';
  List<UserModel> _selectedInLoop = [];
  List<String> _checklist = [];
  bool _showChecklist = false;

  // ── Attachments ──
  List<PlatformFile> _attachedFiles = [];

  // ── Reminder ──
  DateTime? _reminderDateTime;

  // ── Voice Recording ──
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordedPath;
  Duration _recordDuration = Duration.zero;
  // ignore: unused_field
  DateTime? _recordStart;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  static const Color _primary = ThemeProvider.primaryBlue;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final catProv = Provider.of<CategoryProvider>(context, listen: false);
      if (catProv.categories.isEmpty) catProv.fetchCategories();
      final userProv = Provider.of<UserProvider>(context, listen: false);
      if (userProv.users.isEmpty) userProv.fetchUsers();
    });

    _titleFocus.addListener(() => setState(() {}));
    _descFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _checklistController.dispose();
    _remarkController.dispose();
    _titleFocus.dispose();
    _descFocus.dispose();
    _recorder.dispose();
    super.dispose();
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  Color _priorityColor(String p) {
    switch (p) {
      case 'High':
        return const Color(0xFFEF4444);
      case 'Medium':
        return const Color(0xFFF59E0B);
      case 'Low':
        return const Color(0xFF10B981);
      default:
        return Colors.grey;
    }
  }

  IconData _priorityIcon(String p) {
    switch (p) {
      case 'High':
        return Icons.keyboard_double_arrow_up_rounded;
      case 'Medium':
        return Icons.drag_handle_rounded;
      case 'Low':
        return Icons.keyboard_double_arrow_down_rounded;
      default:
        return Icons.flag_rounded;
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? now) : (_endDate ?? now),
      firstDate: isStart ? now.subtract(const Duration(days: 30)) : (now),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _addChecklist() {
    final text = _checklistController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _checklist.add(text);
      _checklistController.clear();
    });
  }

  void _resetForm() {
    _titleController.clear();
    _descController.clear();
    _checklistController.clear();
    _remarkController.clear();
    setState(() {
      _selectedDoer = null;
      _selectedInLoop = [];
      _startDate = null;
      _endDate = null;
      _priority = 'High';
      _category = 'General';
      _status = 'Pending';
      _checklist = [];
      _repeat = false;
      _repeatFrequency = 'Daily';
      _showChecklist = false;
    });
  }

  Future<void> _handleAssign() async {
    print('🚀 _handleAssign TRIGGERED');
    if (_titleController.text.trim().isEmpty) {
      print('❌ ERROR: Title is empty');
      _showError('Please enter a task title');
      return;
    }
    if (_selectedDoer == null) {
      print('❌ ERROR: _selectedDoer is null');
      _showError('Please select an assignee');
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final delegationProv =
        Provider.of<DelegationProvider>(context, listen: false);

    setState(() => _isSubmitting = true);

    // ── 1. Upload voice recording ──────────────────────────────────────────
    String? voiceNoteUrl;
    if (_recordedPath != null) {
      try {
        _showSuccess('Uploading voice note...');
        voiceNoteUrl = await delegationProv.uploadFile(
          File(_recordedPath!),
          folder: 'voice-notes',
        );
        print('✅ Voice uploaded: $voiceNoteUrl');
      } catch (e) {
        print('⚠️ Voice upload failed (continuing): $e');
        // Non-fatal — task will still be created without voice
      }
    }

    // ── 2. Upload file attachments ─────────────────────────────────────────
    List<String> refDocUrls = [];
    for (final pf in _attachedFiles) {
      if (pf.path == null) continue;
      try {
        final url = await delegationProv.uploadFile(
          File(pf.path!),
          folder: 'attachments',
        );
        refDocUrls.add(url);
        print('✅ File uploaded: $url');
      } catch (e) {
        print('⚠️ File upload failed (${pf.name}): $e');
      }
    }

    // ── 3. Build the task ──────────────────────────────────────────────────
    final task = DelegationModel(
      delegationName: _titleController.text.trim(),
      description: _descController.text.trim(),
      delegatorId: auth.currentUser!.id,
      assingDoerId: _selectedDoer!.id,
      priority: _priority,
      status: _status,
      dueDate: _endDate?.toIso8601String() ??
          _startDate?.toIso8601String() ??
          DateTime.now().toIso8601String(),
      category: _category,
      inLoopIds: _selectedInLoop.map((u) => u.id).toList(),
      checklistItems:
          _checklist.map((t) => {'text': t, 'status': 'Pending'}).toList(),
      voiceNoteUrl: voiceNoteUrl,
      referenceDocs: refDocUrls,
      reminderAt: _reminderDateTime?.toIso8601String(),
    );

    final createdData = await delegationProv.createAndReturn(task);
    setState(() => _isSubmitting = false);

    if (!mounted) return;

    final success = createdData != null;

    if (success) {
      // ── 4. Agar remark likha hai toh task create hone ke baad post karo ──
      final remarkText = _remarkController.text.trim();
      if (remarkText.isNotEmpty && createdData!['id'] != null) {
        try {
          await delegationProv.postRemark(
            createdData['id'].toString(),
            remarkText,
            auth.currentUser!.id,
          );
          print('✅ Remark posted with task: $remarkText');
        } catch (e) {
          print('⚠️ Remark post failed: $e');
        }
      }

      if (_reminderDateTime != null) {
        final taskTitle = _titleController.text.trim();
        final notifId = LocalNotificationService.notifIdFromTaskId(taskTitle + DateTime.now().toString());
        await LocalNotificationService.scheduleReminder(
          id: notifId, 
          taskTitle: taskTitle, 
          scheduledTime: _reminderDateTime!
        );
      }

      if (_assignMoreTask) {
        _resetForm();
        _showSuccess('Task assigned! Add another one.');
      } else {
        Navigator.pop(context);
        _showSuccess('Task assigned successfully!');
      }
    } else {
      _showError(delegationProv.errorMessage ?? 'Something went wrong');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Flexible(child: Text(msg)),
        ]),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 150,
          left: 16,
          right: 16,
        ),
      ),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Flexible(child: Text(msg)),
        ]),
        backgroundColor: _primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 150,
          left: 16,
          right: 16,
        ),
      ),
    );
  }

  // File Attachment
  void _showAttachmentPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BottomSheetWrapper(
        title: 'Add Attachment',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _attachOption(icon: Icons.folder_open_rounded, color: const Color(0xFF6366F1), label: 'Browse Files', subtitle: 'PDF, DOC, XLS, ZIP...', onTap: () async {
              Navigator.pop(ctx);
              final result = await FilePicker.platform.pickFiles(allowMultiple: true, type: FileType.any);
              if (result != null) { setState(() => _attachedFiles.addAll(result.files)); _showSuccess(result.files.length.toString() + ' file(s) attached'); }
            }),
            _attachOption(icon: Icons.image_rounded, color: const Color(0xFF3B82F6), label: 'Pick Image', subtitle: 'From gallery', onTap: () async {
              Navigator.pop(ctx);
              final result = await FilePicker.platform.pickFiles(allowMultiple: true, type: FileType.image);
              if (result != null) { setState(() => _attachedFiles.addAll(result.files)); _showSuccess(result.files.length.toString() + ' image(s) attached'); }
            }),
            _attachOption(icon: Icons.video_library_rounded, color: const Color(0xFF10B981), label: 'Pick Video', subtitle: 'From gallery', onTap: () async {
              Navigator.pop(ctx);
              final result = await FilePicker.platform.pickFiles(type: FileType.video);
              if (result != null) { setState(() => _attachedFiles.addAll(result.files)); _showSuccess('Video attached'); }
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _attachOption({required IconData icon, required Color color, required String label, required String subtitle, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
    );
  }

  Widget _buildAttachmentsRow() {
    if (_attachedFiles.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(children: [
          Container(width: 3, height: 14, decoration: BoxDecoration(color: const Color(0xFF6366F1), borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text('ATTACHMENTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey[500], letterSpacing: 0.8)),
          const Spacer(),
          Text(_attachedFiles.length.toString() + ' file(s)', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
        ]),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _attachedFiles.map((f) {
            final isImg = ['jpg','jpeg','png','gif','webp'].contains(f.extension?.toLowerCase() ?? '');
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isImg && f.path != null)
                    ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.file(File(f.path!), width: 28, height: 28, fit: BoxFit.cover))
                  else
                    Icon(_fileIcon(f.extension ?? ''), size: 18, color: const Color(0xFF6366F1)),
                  const SizedBox(width: 7),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 110),
                    child: Text(f.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(onTap: () => setState(() => _attachedFiles.remove(f)), child: Icon(Icons.cancel, size: 15, color: Colors.grey[400])),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  IconData _fileIcon(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf': return Icons.picture_as_pdf_rounded;
      case 'doc': case 'docx': return Icons.description_rounded;
      case 'xls': case 'xlsx': return Icons.table_chart_rounded;
      case 'zip': case 'rar': return Icons.folder_zip_rounded;
      case 'mp4': case 'mov': return Icons.video_file_rounded;
      case 'mp3': case 'wav': case 'm4a': return Icons.audio_file_rounded;
      default: return Icons.insert_drive_file_rounded;
    }
  }

  // Reminder
  Future<void> _showReminderPicker() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _reminderDateTime ?? now,
      firstDate: now, lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: _primary, onPrimary: Colors.white)), child: child!),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_reminderDateTime ?? now),
      builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: _primary, onPrimary: Colors.white)), child: child!),
    );
    if (time == null) return;
    setState(() { _reminderDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute); });
    _showSuccess('Reminder set for ' + DateFormat('dd MMM, hh:mm a').format(_reminderDateTime!));
  }

  Widget _buildReminderChip() {
    if (_reminderDateTime == null) return const SizedBox.shrink();
    return Column(children: [
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B).withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
        ),
        child: Row(children: [
          const Icon(Icons.alarm_on_rounded, size: 18, color: Color(0xFFF59E0B)),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Reminder Set', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFF59E0B))),
            Text(DateFormat('EEE, dd MMM yyyy hh:mm a').format(_reminderDateTime!),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1D23))),
          ]),
          const Spacer(),
          GestureDetector(onTap: () => setState(() => _reminderDateTime = null), child: Icon(Icons.cancel, size: 18, color: Colors.grey[400])),
        ]),
      ),
    ]);
  }

  // Voice Recording
  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) { if (mounted) _showError('Microphone permission denied'); return; }
    
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000), path: path);
    setState(() { _isRecording = true; _recordedPath = null; _recordDuration = Duration.zero; _recordStart = DateTime.now(); });
    _tickRecording();
  }

  void _tickRecording() async {
    if (!_isRecording) return;
    await Future.delayed(const Duration(seconds: 1));
    if (!_isRecording || !mounted) return;
    setState(() => _recordDuration += const Duration(seconds: 1));
    _tickRecording();
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    setState(() { _isRecording = false; _recordedPath = path; });
    if (path != null) _showSuccess('Voice note recorded!');
  }

  void _discardRecording() {
    if (_recordedPath != null) { try { File(_recordedPath!).deleteSync(); } catch (_) {} }
    setState(() { _recordedPath = null; _recordDuration = Duration.zero; });
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return m + ':' + s;
  }

  Widget _buildRecordingBar() {
    if (!_isRecording && _recordedPath == null) return const SizedBox.shrink();
    final isRec = _isRecording;
    final recColor = isRec ? const Color(0xFFEF4444) : const Color(0xFFF59E0B);
    return Column(children: [
      const SizedBox(height: 16),
      AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: recColor.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: recColor.withOpacity(0.25)),
        ),
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: recColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(isRec ? Icons.mic_rounded : Icons.mic_none_rounded, color: recColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isRec ? 'Recording...' : 'Voice Note', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: recColor)),
            const SizedBox(height: 4),
            if (isRec) _buildWaveform()
            else Text('Duration: ' + _formatDuration(_recordDuration), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ])),
          const SizedBox(width: 8),
          Text(_formatDuration(_recordDuration),
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isRec ? const Color(0xFFEF4444) : Colors.grey[700])),
          const SizedBox(width: 10),
          if (isRec)
            GestureDetector(
              onTap: _stopRecording,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.stop_rounded, size: 18, color: Colors.white),
              ),
            )
          else
            Row(children: [
              GestureDetector(
                onTap: _startRecording,
                child: Container(padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(color: const Color(0xFFF59E0B).withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.replay_rounded, size: 16, color: Color(0xFFF59E0B))),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: _discardRecording,
                child: Container(padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.delete_outline_rounded, size: 16, color: Colors.grey[500])),
              ),
            ]),
        ]),
      ),
    ]);
  }

  Widget _buildWaveform() {
    final heights = [6.0,10.0,16.0,8.0,14.0,20.0,10.0,6.0,18.0,12.0,8.0,16.0,6.0,10.0,14.0,8.0,12.0,6.0];
    return SizedBox(height: 22, child: Row(
      children: List.generate(18, (i) => AnimatedContainer(
        duration: Duration(milliseconds: 200 + i * 30),
        margin: const EdgeInsets.symmetric(horizontal: 1.5),
        width: 3,
        height: _isRecording ? (heights[i % heights.length] + (_recordDuration.inSeconds % 2 == 0 ? 3.0 : 0.0)) : 4,
        decoration: BoxDecoration(color: const Color(0xFFEF4444).withOpacity(0.5 + (i % 3) * 0.15), borderRadius: BorderRadius.circular(2)),
      )),
    ));
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        constraints: BoxConstraints(maxHeight: size.height * 0.92),
        decoration: const BoxDecoration(
          color: Color(0xFF003366),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            _buildHandle(),
            _buildHeader(),
            _buildDivider(),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topRight: Radius.circular(20), topLeft: Radius.circular(20))
                ),
                child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 14),
                      _buildTitleField(),
                      const SizedBox(height: 10),
                      _buildDescField(),
                      const SizedBox(height: 20),
                      _buildSectionLabel('Task Details'),
                      const SizedBox(height: 12),
                      _buildDetailsGrid(),
                      const SizedBox(height: 20),
                      _buildSectionLabel('People'),
                      const SizedBox(height: 12),
                      _buildPeopleRow(),
                      const SizedBox(height: 20),
                      _buildChecklistSection(),
                      _buildAttachmentsRow(),
                      _buildReminderChip(),
                      _buildRecordingBar(),
                      const SizedBox(height: 20),
                      _buildRemarkField(),
                      const SizedBox(height: 20),
                      _buildRepeatSection(),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ── Handle ──────────────────────────────────────────────────────────────────

  Widget _buildHandle() => Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 4),
        child: Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      );

  // ── Header ───────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Icon badge ──
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF087F23)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.rocket_launch_rounded,
                color: Colors.white, size: 17),
          ),
          const SizedBox(width: 10),
          // ── Title + subtitle — shrinks if space is tight ──
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Assign New Task',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Fill in details to delegate',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // ── Assign-more toggle ──
          _buildAssignMoreToggle(),
          const SizedBox(width: 6),
          // ── Close button ──
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(50),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 17, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignMoreToggle() {
    return GestureDetector(
      onTap: () => setState(() => _assignMoreTask = !_assignMoreTask),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _assignMoreTask
              ? Colors.white.withOpacity(0.25)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _assignMoreTask ? Colors.white : Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: _assignMoreTask ? Colors.white : Colors.transparent,
                border: Border.all(
                  color: _assignMoreTask ? Colors.white : Colors.white.withOpacity(0.5),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: _assignMoreTask
                  ? const Icon(Icons.check, size: 10, color: Color(0xFF003366))
                  : null,
            ),
            const SizedBox(width: 5),
            Text(
              'Assign More',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _assignMoreTask ? Colors.white : Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Title & Description ──────────────────────────────────────────────────────

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Row(children: [
          const Icon(Icons.drive_file_rename_outline_rounded,
              size: 13, color: Color(0xFF4CAF50)),
          const SizedBox(width: 5),
          Text('Task Title',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[500],
                  letterSpacing: 0.4)),
          const Text(' *',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFEF4444))),
        ]),
        const SizedBox(height: 6),
        // Input card
        Container(
          decoration: BoxDecoration(
            color: _titleFocus.hasFocus 
                ? const Color(0xFF003366).withOpacity(0.04) 
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: _titleFocus.hasFocus ? const Color(0xFF003366) : Colors.grey[300]!, 
                width: 0.7),
            boxShadow: _titleFocus.hasFocus ? [
              BoxShadow(
                color: const Color(0xFF003366).withOpacity(0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ] : [],
          ),
          child: TextField(
            controller: _titleController,
            focusNode: _titleFocus,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1D23),
              letterSpacing: -0.2,
            ),
            decoration: InputDecoration(
              hintText: 'e.g. Prepare Q2 report...',
              hintStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[400],
                letterSpacing: -0.2,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Row(children: [
          const Icon(Icons.notes_rounded, size: 13, color: Color(0xFF6366F1)),
          const SizedBox(width: 5),
          Text('Description',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[500],
                  letterSpacing: 0.4)),
          Text('  (optional)',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[400])),
        ]),
        const SizedBox(height: 6),
        // Input card
        Container(
          decoration: BoxDecoration(
            color: _descFocus.hasFocus 
                ? const Color(0xFF003366).withOpacity(0.04) 
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: _descFocus.hasFocus ? const Color(0xFF003366) : Colors.grey[300]!, 
                width: 0.7),
            boxShadow: _descFocus.hasFocus ? [
              BoxShadow(
                color: const Color(0xFF003366).withOpacity(0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ] : [],
          ),
          child: TextField(
            controller: _descController,
            focusNode: _descFocus,
            maxLines: 3,
            minLines: 2,
            style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1A1D23),
                fontWeight: FontWeight.w500,
                height: 1.6),
            decoration: InputDecoration(
              hintText: 'Add context, notes or any details...',
              hintStyle:
                  TextStyle(fontSize: 14, color: Colors.grey[400], height: 1.6),
              border: InputBorder.none,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }


  // ── Section Label ────────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String label) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: _primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.grey[500],
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  // ── Remark Field (Optional) ────────────────────────────────────────────────

  Widget _buildRemarkField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Initial Remark (Optional)'),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey[300]!, width: 0.7),
          ),
          child: TextField(
            controller: _remarkController,
            maxLines: 3,
            minLines: 2,
            style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1A1D23),
                fontWeight: FontWeight.w500,
                height: 1.6),
            decoration: InputDecoration(
              hintText: 'Add a remark or note for this task...',
              hintStyle:
                  TextStyle(fontSize: 14, color: Colors.grey[400], height: 1.6),
              border: InputBorder.none,
              isDense: true,
              prefixIcon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Icon(Icons.chat_bubble_outline_rounded,
                    size: 18, color: Colors.grey[400]),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  // ── Details Grid ─────────────────────────────────────────────────────────────

  Widget _buildDetailsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.low_priority_rounded, size: 13, color: Color(0xFF6366F1)),
                    const SizedBox(width: 5),
                    Text('Priority', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey[500], letterSpacing: 0.4)),
                  ]),
                  const SizedBox(height: 6),
                  AppDropdown<String>(
                    isCompact: false,
                    value: _priority,
                    items: const ['High', 'Medium', 'Low'],
                    labelBuilder: (v) => v,
                    onChanged: (v) { if (v != null) setState(() => _priority = v); },
                    prefixIcon: _priorityIcon(_priority),
                    accentColor: _priorityColor(_priority),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Consumer<CategoryProvider>(
                builder: (_, catProv, __) {
                  final cats = catProv.categories.isNotEmpty
                      ? catProv.categories.map((c) => c['name'] as String).toList()
                      : ['General', 'Urgent', 'Maintenance', 'Sales', 'Support'];
                  final safeCategory = cats.contains(_category) ? _category : cats.first;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.category_rounded, size: 13, color: Color(0xFF8B5CF6)),
                        const SizedBox(width: 5),
                        Text('Category', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey[500], letterSpacing: 0.4)),
                      ]),
                      const SizedBox(height: 6),
                        AppDropdown<String>(
                          isCompact: false,
                          value: safeCategory,
                          items: cats,
                          labelBuilder: (v) => v,
                          onChanged: (v) { if (v != null) setState(() => _category = v); },
                          prefixIcon: Icons.category_rounded,
                          accentColor: const Color(0xFF003366), // Switched to AppBar green
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.stop_circle_outlined, size: 13, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 5),
                  Text('Due Date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey[500], letterSpacing: 0.4)),
                ]),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => _pickDate(false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    decoration: BoxDecoration(
                      color: _endDate != null ? const Color(0xFFF59E0B).withOpacity(0.06) : const Color(0xFFFAFAFB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _endDate != null ? const Color(0xFFF59E0B).withOpacity(0.3) : const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 16, color: _endDate != null ? const Color(0xFFF59E0B) : Colors.grey[400]),
                        const SizedBox(width: 8),
                        Text(
                          _endDate != null ? DateFormat('dd MMM yyyy').format(_endDate!) : 'Select Due',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _endDate != null ? const Color(0xFFF59E0B) : Colors.grey[400]),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.flag_rounded, size: 13, color: Color(0xFF10B981)),
                    const SizedBox(width: 5),
                    Text('Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey[500], letterSpacing: 0.4)),
                  ]),
                  const SizedBox(height: 6),
                  AppDropdown<String>(
                    isCompact: false,
                    value: _status,
                    items: const ['Pending', 'In Progress', 'On Hold', 'Completed', 'Cancelled'],
                    labelBuilder: (v) => v,
                    onChanged: (v) { if (v != null) setState(() => _status = v); },
                    prefixIcon: Icons.flag_rounded,
                    accentColor: const Color(0xFF10B981),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailChip({
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: iconColor),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── People Row ───────────────────────────────────────────────────────────────

  Widget _buildPeopleRow() {
    return Consumer<UserProvider>(
      builder: (context, userProv, _) {
        if (userProv.isLoading) {
          return _buildLoadingPill('Loading members...');
        }
        
        final authProv = Provider.of<AuthProvider>(context, listen: false);
        final currentUser = authProv.currentUser;
        
        List<UserModel> allowedUsers = userProv.users;
        if (currentUser != null) {
          if (authProv.isAdmin) {
            allowedUsers = userProv.users;
          } else if (authProv.currentUser?.role?.toLowerCase() == 'manager') {
            allowedUsers = userProv.users.where((u) => 
                u.role.toLowerCase() == 'manager' || 
                u.role.toLowerCase() == 'user' ||
                u.id == currentUser.id).toList();
          } else {
            allowedUsers = userProv.users.where((u) => 
                u.role.toLowerCase() == 'user' || 
                u.id == currentUser.id).toList();
          }
        }

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildPersonChip(
              isSelected: _selectedDoer != null,
              avatarText: _selectedDoer?.fullName[0].toUpperCase() ?? '?',
              label: _selectedDoer?.fullName ?? 'Assign To',
              subtitle: _selectedDoer?.role ?? 'Select person',
              color: _primary,
              onTap: () => _showUserPicker(allowedUsers, isInLoop: false),
            ),
            if (_selectedInLoop.isNotEmpty) ...[
              ..._selectedInLoop.map(
                (u) => _buildPersonChip(
                  isSelected: true,
                  avatarText: u.fullName[0].toUpperCase(),
                  label: u.fullName,
                  subtitle: 'In Loop',
                  color: const Color(0xFF6366F1),
                  onTap: () {
                    _showUserPicker(allowedUsers, isInLoop: true);
                  },
                  onRemove: () {
                    setState(() {
                      _selectedInLoop.remove(u);
                    });
                  },
                ),
              ),
            ],
            GestureDetector(
              onTap: () => _showUserPicker(allowedUsers, isInLoop: true),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.grey[200]!, style: BorderStyle.solid),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.group_add_rounded,
                        size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 7),
                    Text(
                      'Add In Loop',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPersonChip({
    required bool isSelected,
    required String avatarText,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    VoidCallback? onRemove,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.08) : Colors.grey[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: isSelected ? color.withOpacity(0.35) : Colors.grey[200]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: color.withOpacity(0.15),
              child: Text(
                isSelected ? avatarText : '+',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? color : Colors.grey[700],
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 10.5, color: Colors.grey[500]),
                ),
              ],
            ),
            if (onRemove != null) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onRemove,
                child: Icon(Icons.cancel,
                    size: 16, color: color.withOpacity(0.6)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
            ),
          ),
          const SizedBox(width: 8),
          Text(text,
              style: TextStyle(fontSize: 13, color: Colors.grey[500])),
        ],
      ),
    );
  }

  // ── Asset Field ──────────────────────────────────────────────────────────────



  // ── Checklist Section ────────────────────────────────────────────────────────

  Widget _buildChecklistSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _showChecklist = !_showChecklist),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: _showChecklist || _checklist.isNotEmpty
                  ? _primary.withOpacity(0.06)
                  : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _showChecklist || _checklist.isNotEmpty
                    ? _primary.withOpacity(0.3)
                    : Colors.grey[200]!,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.checklist_rounded,
                  size: 18,
                  color: _showChecklist || _checklist.isNotEmpty
                      ? _primary
                      : Colors.grey[500],
                ),
                const SizedBox(width: 10),
                Text(
                  _checklist.isEmpty
                      ? 'Add Checklist'
                      : '${_checklist.length} Item${_checklist.length > 1 ? 's' : ''} in Checklist',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _showChecklist || _checklist.isNotEmpty
                        ? _primary
                        : Colors.grey[600],
                  ),
                ),
                const Spacer(),
                AnimatedRotation(
                  turns: _showChecklist ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.expand_more_rounded,
                      color: Colors.grey[400], size: 20),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: _showChecklist || _checklist.isNotEmpty
              ? Column(
                  children: [
                    const SizedBox(height: 8),
                    ..._checklist.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey[200]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.grey[300]!),
                              ),
                              child: Center(
                                child: Text(
                                  '${idx + 1}',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[600]),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item,
                                style: const TextStyle(
                                    fontSize: 13.5, height: 1.3),
                              ),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _checklist.removeAt(idx)),
                              child: Icon(Icons.close_rounded,
                                  size: 16, color: Colors.grey[400]),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (_showChecklist)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: _primary.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 12),
                            Icon(Icons.add,
                                size: 18,
                                color: _primary.withOpacity(0.7)),
                            Expanded(
                              child: TextField(
                                controller: _checklistController,
                                style: const TextStyle(fontSize: 13.5),
                                decoration: const InputDecoration(
                                  hintText: 'New item name...',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 12),
                                ),
                                onSubmitted: (_) => _addChecklist(),
                                textInputAction: TextInputAction.done,
                              ),
                            ),
                            TextButton(
                              onPressed: _addChecklist,
                              child: Text('Add',
                                  style: TextStyle(
                                      color: _primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  // ── Repeat Section ───────────────────────────────────────────────────────────

  Widget _buildRepeatSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _repeat ? _primary.withOpacity(0.04) : Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _repeat ? _primary.withOpacity(0.25) : Colors.grey[200]!,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.repeat_rounded,
                  size: 18,
                  color: _repeat ? _primary : Colors.grey[500]),
              const SizedBox(width: 10),
              Text(
                'Repeat Task',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _repeat
                      ? const Color(0xFF1A1D23)
                      : Colors.grey[700],
                ),
              ),
              const Spacer(),
              Transform.scale(
                scale: 0.85,
                child: Switch.adaptive(
                  value: _repeat,
                  activeColor: _primary,
                  onChanged: (v) => setState(() => _repeat = v),
                ),
              ),
            ],
          ),
          if (_repeat) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Frequency',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[500])),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: ['Daily', 'Weekly', 'Monthly', 'Yearly']
                            .map(
                              (f) => GestureDetector(
                                onTap: () =>
                                    setState(() => _repeatFrequency = f),
                                child: AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _repeatFrequency == f
                                        ? _primary
                                        : Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _repeatFrequency == f
                                          ? _primary
                                          : Colors.grey[300]!,
                                    ),
                                  ),
                                  child: Text(
                                    f,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _repeatFrequency == f
                                          ? Colors.white
                                          : Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // File Attachment button
          _buildFooterIconBtn(
            icon: Icons.attach_file_rounded,
            color: const Color(0xFF6366F1),
            badge: _attachedFiles.isNotEmpty ? _attachedFiles.length.toString() : null,
            onTap: _showAttachmentPicker,
          ),
          const SizedBox(width: 10),
          // Reminder button
          _buildFooterIconBtn(
            icon: _reminderDateTime != null
                ? Icons.alarm_on_rounded
                : Icons.alarm_add_rounded,
            color: const Color(0xFFF59E0B),
            badge: _reminderDateTime != null ? '!' : null,
            onTap: _showReminderPicker,
          ),
          const SizedBox(width: 10),
          // Voice Recording button
          _buildFooterIconBtn(
            icon: _isRecording
                ? Icons.stop_circle_rounded
                : (_recordedPath != null
                    ? Icons.mic_rounded
                    : Icons.mic_none_rounded),
            color: _isRecording
                ? const Color(0xFFEF4444)
                : _recordedPath != null
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF10B981),
            badge: _recordedPath != null && !_isRecording ? '!' : null,
            onTap: _isRecording ? _stopRecording : _startRecording,
          ),
          const Spacer(),
          _buildAssignButton(),
        ],
      ),
    );
  }

  Widget _buildFooterIconBtn({required IconData icon, required Color color, String? badge, required VoidCallback onTap}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.25)),
            ),
            child: Icon(icon, size: 19, color: color),
          ),
        ),
        if (badge != null)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAssignButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _handleAssign,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          disabledBackgroundColor: _primary.withOpacity(0.6),
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: _isSubmitting ? 0 : 3,
          shadowColor: _primary.withOpacity(0.4),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.rocket_launch_rounded,
                      size: 16, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Assign Task',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Divider ───────────────────────────────────────────────────────────────────

  Widget _buildDivider() => const SizedBox.shrink(); // Using background color separation instead

  // ─── Pickers ─────────────────────────────────────────────────────────────────

  void _showPriorityPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BottomSheetWrapper(
        title: 'Set Priority',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['High', 'Medium', 'Low'].map((p) {
            final isSelected = _priority == p;
            return ListTile(
              onTap: () {
                setState(() => _priority = p);
                Navigator.pop(ctx);
              },
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _priorityColor(p).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(_priorityIcon(p),
                    size: 18, color: _priorityColor(p)),
              ),
              title: Text(p,
                  style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500)),
              trailing: isSelected
                  ? Icon(Icons.check_circle_rounded, color: _priorityColor(p))
                  : null,
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Consumer<CategoryProvider>(
        builder: (_, catProv, __) {
          final cats = catProv.categories.isNotEmpty
              ? catProv.categories.map((c) => c['name'] as String).toList()
              : ['General', 'Urgent', 'Maintenance', 'Sales', 'Support'];
          return _BottomSheetWrapper(
            title: 'Select Category',
            child: catProv.isLoading
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cats.length,
                    itemBuilder: (_, i) {
                      final isSelected = _category == cats[i];
                      return ListTile(
                        dense: true,
                        onTap: () {
                          setState(() => _category = cats[i]);
                          Navigator.pop(ctx);
                        },
                        leading: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF003366).withOpacity(0.1), // Toolbar color logic here
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.category_rounded,
                              size: 16, color: Color(0xFF003366)), // Toolbar color logic here
                        ),
                        title: Text(cats[i],
                            style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal)),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded,
                                color: Color(0xFF003366)) // Toolbar color logic here
                            : null,
                      );
                    },
                  ),
          );
        },
      ),
    );
  }

  void _showUserPicker(List<UserModel> users, {required bool isInLoop}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return _BottomSheetWrapper(
            title: isInLoop ? 'Add In Loop' : 'Assign To',
            child: users.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Text('No users found',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight:
                              MediaQuery.of(context).size.height * 0.45,
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: users.length,
                          itemBuilder: (_, idx) {
                            final user = users[idx];
                            final isSelected = isInLoop
                                ? _selectedInLoop.contains(user)
                                : _selectedDoer == user;
                            final color =
                                isInLoop ? const Color(0xFF6366F1) : _primary;
                            return ListTile(
                              onTap: () {
                                if (isInLoop) {
                                  setModalState(() {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedInLoop.remove(user);
                                      } else {
                                        _selectedInLoop.add(user);
                                      }
                                    });
                                  });
                                } else {
                                  setState(() => _selectedDoer = user);
                                  Navigator.pop(ctx);
                                }
                              },
                              leading: CircleAvatar(
                                radius: 20,
                                backgroundColor: color.withOpacity(0.12),
                                child: Text(
                                  user.fullName[0].toUpperCase(),
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              title: Text(user.fullName,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                  user.designation.isNotEmpty
                                      ? user.designation
                                      : user.workEmail,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500])),
                              trailing: isSelected
                                  ? Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                          color: color.withOpacity(0.1),
                                          shape: BoxShape.circle),
                                      child: Icon(Icons.check_rounded,
                                          size: 16, color: color),
                                    )
                                  : null,
                            );
                          },
                        ),
                      ),
                      if (isInLoop) ...[
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(
                                'Done (${_selectedInLoop.length} selected)',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
          );
        },
      ),
    );
  }
}

// ─── Reusable Bottom Sheet Wrapper ────────────────────────────────────────────

class _BottomSheetWrapper extends StatelessWidget {
  final String title;
  final Widget child;

  const _BottomSheetWrapper({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1D23),
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.close, size: 16, color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),
          Divider(color: Colors.grey[100], height: 20),
          child,
          SizedBox(
            height: MediaQuery.of(context).viewInsets.bottom + 12,
          ),
        ],
      ),
    );
  }
}
