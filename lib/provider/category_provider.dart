import 'package:flutter/material.dart';

import '../model/category_model.dart';
import '../services/category_service.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryService _service = CategoryService();

  List<Map<String, dynamic>> _categories = [];
  List<CategoryModel> _categoryModels = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> get categories => _categories;
  List<CategoryModel> get categoryModels => _categoryModels;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchCategories() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _categories = await _service.getAllCategories();
      _categoryModels = _categories
          .map((item) => CategoryModel.fromJson(item))
          .toList();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createCategory({
    required String name,
    required String color,
    String? createdBy,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newCategory = await _service.createCategory(
        name: name,
        color: color,
        createdBy: createdBy,
      );
      _categories.insert(0, newCategory);
      _categoryModels.insert(0, CategoryModel.fromJson(newCategory));
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateCategory({
    required String categoryId,
    required String name,
    required String color,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _errorMessage = 'Category editing is not available in the current backend.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteCategory(String categoryId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.deleteCategory(categoryId);
      _categories.removeWhere((cat) => cat['id']?.toString() == categoryId);
      _categoryModels.removeWhere((cat) => cat.id == categoryId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteCategoryTasks(String categoryId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _errorMessage =
          'Deleting all tasks from a category is not available in the current backend.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> removeCategoryLink(String categoryId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _errorMessage =
          'Unlinking categories from tasks is not available in the current backend.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> searchCategories(String query) async {
    try {
      final normalizedQuery = query.trim().toLowerCase();
      if (normalizedQuery.isEmpty) {
        return List<Map<String, dynamic>>.from(_categories);
      }
      return _categories.where((category) {
        final name = category['name']?.toString().toLowerCase() ?? '';
        return name.contains(normalizedQuery);
      }).toList();
    } catch (e) {
      _errorMessage = e.toString();
      return [];
    }
  }

  Future<Map<String, dynamic>?> getCategoryById(String categoryId) async {
    try {
      for (final category in _categories) {
        if (category['id']?.toString() == categoryId) {
          return Map<String, dynamic>.from(category);
        }
      }
      return await _service.getCategoryById(categoryId);
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
