import 'package:flutter/foundation.dart';
import '../models/category_model.dart' as models;
import '../models/subcategory_model.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';

class CategoryProvider extends ChangeNotifier {
  final DatabaseService _databaseService;
  List<models.Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  CategoryProvider(this._databaseService);

  List<models.Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  Future<void> loadCategories() async {
    _setLoading(true);
    _setError(null);

    try {
      _categories = await _databaseService.getAllCategories();
      await Future.wait(_categories.map((category) async {
        category.subcategories =
            await _databaseService.getSubcategoriesByCategoryId(category.id!);
      }));
    } catch (e) {
      _setError(AppConstants.errorLoadingData);
      debugPrint('Error loading categories: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addCategory(String name) async {
    try {
      if (await _databaseService.categoryExists(name)) {
        throw Exception(AppConstants.categoryExists);
      }
      await _databaseService.insertCategory(models.Category(name: name));
      await loadCategories();
    } catch (e) {
      debugPrint('Error adding category: $e');
      rethrow;
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      await _databaseService.deleteCategory(id);
      _categories.removeWhere((category) => category.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting category: $e');
      rethrow;
    }
  }

  Future<void> addSubcategory(Subcategory subcategory) async {
    try {
      if (await _databaseService.subcategoryExists(
          subcategory.categoryId, subcategory.name)) {
        throw Exception(AppConstants.subcategoryExists);
      }
      await _databaseService.insertSubcategory(subcategory);
      await loadCategories();
    } catch (e) {
      debugPrint('Error adding subcategory: $e');
      rethrow;
    }
  }

  Future<void> updateCategory(int id, String newName) async {
    try {
      await _databaseService.updateCategoryName(id, newName);
      await loadCategories();
    } catch (e) {
      debugPrint('Error updating category: $e');
      rethrow;
    }
  }
}
