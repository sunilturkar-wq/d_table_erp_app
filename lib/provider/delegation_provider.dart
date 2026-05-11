import 'package:flutter/material.dart';
import '../model/delegate_model.dart';
import '../services/delegation_service.dart';

class DelegationProvider extends ChangeNotifier {
  final DelegationService _service = DelegationService();

  List<DelegationModel> _delegations = [];
  List<DelegationModel> _deletedDelegations = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<DelegationModel> get delegations => _delegations;
  List<DelegationModel> get deletedDelegations => _deletedDelegations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // --- 1. Fetch All Delegations ---
  Future<void> fetchAll() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final List<dynamic> rawData = await _service.getAllDelegations();
      _delegations = rawData.map((item) => DelegationModel.fromJson(item)).toList();
      print("✅ Fetched ${_delegations.length} delegations");
    } catch (e) {
      _errorMessage = e.toString();
      print("❌ Fetch Error: $_errorMessage");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- 1b. Fetch Deleted Delegations ---
  Future<void> fetchDeleted() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final List<dynamic> rawData = await _service.getDeletedDelegations();
      _deletedDelegations = rawData.map((item) => DelegationModel.fromJson(item)).toList();
      print("✅ Fetched ${_deletedDelegations.length} deleted delegations");
    } catch (e) {
      _errorMessage = e.toString();
      print("❌ Fetch Deleted Error: $_errorMessage");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // --- Restore Delegation ---
  Future<bool> restoreTask(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.restoreDelegation(id);
      _deletedDelegations.removeWhere((item) => item.id == id);
      // Wait for original list to refresh
      await fetchAll();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print("❌ Restore Error: $_errorMessage");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- 2. Create New Delegation ---
  Future<bool> create(DelegationModel delegation) async {
    _isLoading = true;
    notifyListeners();
    try {
      print("Sending Data: ${delegation.toJson()}");
      await _service.createDelegation(delegation.toJson());
      await fetchAll();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print("❌ Create Error: $_errorMessage");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- 2b. Create aur naya task data return karo (remark ke liye id chahiye) ---
  Future<Map<String, dynamic>?> createAndReturn(DelegationModel delegation) async {
    _isLoading = true;
    notifyListeners();
    try {
      print("Sending Data: ${delegation.toJson()}");
      final response = await _service.createDelegation(delegation.toJson());
      // Backend response: { success: true, data: { id: ..., ... } }
      final createdData = response['data'] as Map<String, dynamic>?;
      await fetchAll();
      return createdData;
    } catch (e) {
      _errorMessage = e.toString();
      print("❌ Create Error: $_errorMessage");
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> createFromPayloadAndReturn(
    Map<String, dynamic> payload,
  ) async {
    _isLoading = true;
    notifyListeners();
    try {
      print("Sending Raw Payload: $payload");
      final response = await _service.createDelegation(payload);
      final createdData = response['data'] as Map<String, dynamic>?;
      await fetchAll();
      return createdData;
    } catch (e) {
      _errorMessage = e.toString();
      print("❌ Raw Create Error: $_errorMessage");
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }




  Future<void> refreshSingleTask(String id) async {
    try {
      final response = await _service.getDelegationById(id);

      // Backend se full data (remarks, voice, images included)
      final Map<String, dynamic> actualData = response['data'];

      // 🔍 DEBUG: Raw backend data print karo
      print('🔍 RAW Backend Data keys: ${actualData.keys.toList()}');
      print('🔍 voiceNoteUrl: ${actualData['voiceNoteUrl']}');
      print('🔍 voice_note_url: ${actualData['voice_note_url']}');
      print('🔍 referenceDocs: ${actualData['referenceDocs']}');
      print('🔍 reference_docs: ${actualData['reference_docs']}');
      print('🔍 remarks count: ${(actualData['remarks'] as List? ?? []).length}');
      print('🔍 tags: ${actualData['tags']}');

      DelegationModel updatedTask = DelegationModel.fromJson(actualData);

      // 🔍 DEBUG: Parsed model mein kya aaya
      print('🔍 PARSED Model voiceNoteUrl: ${updatedTask.voiceNoteUrl}');
      print('🔍 PARSED Model referenceDocs: ${updatedTask.referenceDocs}');
      print('🔍 PARSED Model remarks: ${updatedTask.remarks.length}');
      print('🔍 PARSED Model reminderAt: ${updatedTask.reminderAt}');

      int index = _delegations.indexWhere((t) => t.id == id);
      if (index != -1) {
        _delegations[index] = updatedTask;
        print("✅ Task Updated at index $index!");
      } else {
        _delegations.insert(0, updatedTask);
        print("✅ New Task Added to list! Id: $id");
      }
      notifyListeners();
    } catch (e) {
      print("❌ Refresh Task Error: $e");
    }
  }

  // --- fetchTaskDetail: task_detail screen ke liye direct fetch ---
  Future<DelegationModel?> fetchTaskDetail(String id) async {
    try {
      final response = await _service.getDelegationById(id);
      final Map<String, dynamic> actualData = response['data'];

      // Debug logs
      print('🔍 RAW keys: ${actualData.keys.toList()}');
      print('🔍 voiceNoteUrl: ${actualData['voiceNoteUrl']}');
      print('🔍 referenceDocs: ${actualData['referenceDocs']}');
      print('🔍 remarks count: ${(actualData['remarks'] as List? ?? []).length}');
      print('🔍 tags: ${actualData['tags']}');

      final task = DelegationModel.fromJson(actualData);
      print('🔍 PARSED voice: ${task.voiceNoteUrl}, docs: ${task.referenceDocs}, remarks: ${task.remarks.length}, reminder: ${task.reminderAt}');
      return task;
    } catch (e) {
      print('❌ fetchTaskDetail Error: $e');
      return null;
    }
  }

// --- Updated postRemark ---
  Future<bool> postRemark(String delegationId, String remark, String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.addRemark(delegationId, remark, userId);

      // 🔥 GAME CHANGER: fetchAll() ki jagah refreshSingleTask() call karein
      await refreshSingleTask(delegationId);

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

// --- Updated updateStatus ---
  Future<bool> updateStatus(String id, String newStatus, String reason, String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.updateDelegation(id, {
        "status": newStatus,
        "reason": reason,
        "changedBy": userId,
      });
      // Status change par bhi detail refresh karein taaki history update ho jaye
      await refreshSingleTask(id);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> subscribeToTask(
    String delegationId,
    String userId,
    List<String> currentLoopIds,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final normalizedLoopIds = currentLoopIds
          .map((id) => id.toString().trim())
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      if (!normalizedLoopIds.contains(userId)) {
        normalizedLoopIds.add(userId);
      }

      await _service.updateDelegation(delegationId, {
        'inLoopIds': normalizedLoopIds,
      });

      await refreshSingleTask(delegationId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print("❌ Subscribe Task Error: $_errorMessage");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveTaskReminders(
    String delegationId,
    List<Map<String, dynamic>> reminders,
    String userId,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.updateDelegation(delegationId, {
        'reminders': reminders,
        'changedBy': userId,
        'reason': 'Task reminders updated',
      });

      await refreshSingleTask(delegationId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print("❌ Save Task Reminders Error: $_errorMessage");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateTaskDetails(
    String delegationId,
    Map<String, dynamic> payload,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.updateDelegation(delegationId, payload);
      await refreshSingleTask(delegationId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print("❌ Update Task Details Error: $_errorMessage");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // DelegationProvider.dart mein add karein

  Future<bool> delete(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.deleteDelegation(id);
      _delegations.removeWhere((item) => item.id == id);
      print("✅ Deleted Delegation from local state: $id");
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print("❌ Delete Error: $_errorMessage");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteRemark(String delegationId, String remarkId) async {
    try {
      await _service.deleteRemark(delegationId, remarkId);
      await refreshSingleTask(delegationId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print("❌ Delete Remark Error: $_errorMessage");
      return false;
    }
  }

  Future<bool> updateRemark(String delegationId, String remarkId, String newText) async {
    try {
      await _service.updateRemark(delegationId, remarkId, newText);
      await refreshSingleTask(delegationId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print("❌ Update Remark Error: $_errorMessage");
      return false;
    }
  }

  Future<String> uploadFile(dynamic file, {String folder = 'general'}) {
    return _service.uploadFile(file, folder: folder);
  }

  Future<bool> updateChecklistStatus(String delegationId, String checklistId, String newStatus) async {
    try {
      await _service.updateChecklistStatus(delegationId, checklistId, newStatus);
      await refreshSingleTask(delegationId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print("❌ Update Checklist Error: $_errorMessage");
      return false;
    }
  }

}
