import 'package:flutter/material.dart';
import '../services/task_template_service.dart';
import '../model/task_template_model.dart';
import '../model/user_model.dart';
import '../services/activity_service.dart'; // To fetch users for 'Created By' filter

class TaskTemplateProvider extends ChangeNotifier {
  final TaskTemplateService _service = TaskTemplateService();
  final ActivityService _userService = ActivityService();

  List<TaskTemplateModel> _templates = [];
  List<UserModel> _users = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Filters
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _createdByFilter = 'All';
  String _priorityFilter = 'All';
  String _frequencyFilter = 'All';

  List<TaskTemplateModel> get templates => _templates;
  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String get createdByFilter => _createdByFilter;
  String get priorityFilter => _priorityFilter;
  String get frequencyFilter => _frequencyFilter;

  // Filter setters
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setCreatedByFilter(String userId) {
    _createdByFilter = userId;
    notifyListeners();
  }

  void setPriorityFilter(String priority) {
    _priorityFilter = priority;
    notifyListeners();
  }

  void setFrequencyFilter(String frequency) {
    _frequencyFilter = frequency;
    notifyListeners();
  }

  void resetFilters() {
    _searchQuery = '';
    _selectedCategory = 'All';
    _createdByFilter = 'All';
    _priorityFilter = 'All';
    _frequencyFilter = 'All';
    notifyListeners();
  }

  Future<void> fetchTemplates({bool skipLoadingChange = false}) async {
    if (!skipLoadingChange) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      _templates = await _service.getTemplates();
      if (_users.isEmpty) {
        _users = await _userService.getUsers();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if (!skipLoadingChange) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> deleteTemplate(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.deleteTemplate(id);
      _templates.removeWhere((t) => t.id == id);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createTemplate(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newTemplate = await _service.createTemplate(data);
      _templates.insert(0, newTemplate); // Add at the beginning of the list
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      throw Exception(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateTemplate(String id, Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedTemplate = await _service.updateTemplate(id, data);
      final index = _templates.indexWhere((t) => t.id == id);
      if (index != -1) {
        _templates[index] = updatedTemplate;
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      throw Exception(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<TaskTemplateModel> get filteredTemplates {
    return _templates.where((t) {
      final q = _searchQuery.toLowerCase();
      final matchesSearch = t.title.toLowerCase().contains(q) || (t.description?.toLowerCase().contains(q) ?? false);
      final matchesCategory = _selectedCategory == 'All' || t.category == _selectedCategory;
      final matchesUser = _createdByFilter == 'All' || t.createdBy == _createdByFilter;
      final matchesPriority = _priorityFilter == 'All' || t.priority == _priorityFilter;
      final matchesFrequency = _frequencyFilter == 'All' || (t.frequency ?? 'Once') == _frequencyFilter;
      return matchesSearch && matchesCategory && matchesUser && matchesPriority && matchesFrequency;
    }).toList();
  }

  List<Map<String, dynamic>> get categoriesWithCount {
    final Map<String, int> catCounts = {'All': _templates.length};
    for (var t in _templates) {
      if (t.category != null && t.category!.isNotEmpty) {
        catCounts[t.category!] = (catCounts[t.category!] ?? 0) + 1;
      }
    }
    return catCounts.entries.map((e) => {'name': e.key, 'count': e.value}).toList();
  }
}
