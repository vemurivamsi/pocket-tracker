import '../helper/databasehelper.dart';
import '../models/category_model.dart';
import '../models/subcategory_model.dart';

class DatabaseService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Category Operations
  Future<List<Category>> getAllCategories() async {
    return await _dbHelper.getAllCategories();
  }

  Future<List<Subcategory>> getSubcategoriesByCategoryId(int categoryId) async {
    return await _dbHelper.getSubcategoriesByCategoryId(categoryId);
  }

  Future<int> insertCategory(Category category) async {
    return await _dbHelper.insertCategory(category);
  }

  Future<void> deleteCategory(int id) async {
    await _dbHelper.deleteCategory(id);
  }

  Future<void> updateCategoryName(int categoryId, String newName) async {
    await _dbHelper.updateCategoryName(categoryId, newName);
  }

  // Subcategory Operations
  Future<int> insertSubcategory(Subcategory subcategory) async {
    return await _dbHelper.insertSubcategory(subcategory);
  }

  Future<void> deleteSubcategory(int id) async {
    await _dbHelper.deleteSubcategory(id);
  }

  Future<void> updateSubcategoryName(int subcategoryId, String newName) async {
    await _dbHelper.updateSubcategoryName(subcategoryId, newName);
  }

  // Utility Methods
  Future<bool> categoryExists(String name) async {
    return await _dbHelper.categoryExists(name);
  }

  Future<bool> subcategoryExists(int categoryId, String name) async {
    return await _dbHelper.subcategoryExists(categoryId, name);
  }
}
