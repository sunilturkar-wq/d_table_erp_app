import 'package:dio/dio.dart';
import '../config/api_constants.dart';
import 'dio_client.dart';

class CategoryService {
  final Dio _dio = DioClient().dio;
  static const String _unsupportedMessage =
      'This category action is not supported by the current backend.';

  // Get all categories with task count
  Future<List<Map<String, dynamic>>> getAllCategories() async {
    try {
      final response = await _dio.get('${ApiConstants.categories}/list');
      final categories = List<Map<String, dynamic>>.from(response.data ?? []);
      return categories;
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  // Get single category by ID
  Future<Map<String, dynamic>> getCategoryById(String categoryId) async {
    final categories = await getAllCategories();
    try {
      return categories.firstWhere(
        (category) => category['id']?.toString() == categoryId,
      );
    } catch (_) {
      throw Exception('Category not found');
    }
  }

  // Create new category
  Future<Map<String, dynamic>> createCategory({
    required String name,
    required String color,
    String? createdBy,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.categories}/create',
        data: {
          'name': name.trim(),
          'color': color.trim(),
          if (createdBy != null && createdBy.trim().isNotEmpty)
            'createdBy': createdBy.trim(),
        },
      );
      return Map<String, dynamic>.from(response.data ?? {});
    } catch (e) {
      throw Exception('Failed to create category: $e');
    }
  }

  // Update category
  Future<Map<String, dynamic>> updateCategory({
    required String categoryId,
    required String name,
    required String color,
  }) async {
    throw UnsupportedError(_unsupportedMessage);
  }

  // Delete category
  Future<void> deleteCategory(String categoryId) async {
    try {
      await _dio.delete('${ApiConstants.categories}/$categoryId', data: {});
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }

  // Delete all tasks in category
  Future<Map<String, dynamic>> deleteCategoryTasks(String categoryId) async {
    throw UnsupportedError(_unsupportedMessage);
  }

  // Remove category link from tasks (keep tasks, remove category)
  Future<Map<String, dynamic>> removeCategoryLink(String categoryId) async {
    throw UnsupportedError(_unsupportedMessage);
  }

  // Search categories
  Future<List<Map<String, dynamic>>> searchCategories(String query) async {
    final categories = await getAllCategories();
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return categories;
    }
    return categories.where((category) {
      final name = category['name']?.toString().toLowerCase() ?? '';
      return name.contains(normalizedQuery);
    }).toList();
  }

  // Legacy method for backward compatibility
  Future<List<dynamic>> getCategories() async {
    try {
      final response = await _dio.get('${ApiConstants.categories}/list');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}
