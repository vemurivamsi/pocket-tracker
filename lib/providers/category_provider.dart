// import 'package:flutter/foundation.dart';
// import '../models/category_model.dart' as models;
// import '../models/subcategory_model.dart';
// import '../services/database_service.dart';
// import '../utils/constants.dart';

// class CategoryProvider extends ChangeNotifier {
//   final DatabaseService _databaseService;
//   List<models.Category> _categories = [];
//   bool _isLoading = false;
//   String? _error;

//   CategoryProvider(this._databaseService);

//   List<models.Category> get categories => _categories;
//   bool get isLoading => _isLoading;
//   String? get error => _error;

//   void _setLoading(bool value) {
//     _isLoading = value;
//     notifyListeners();
//   }

//   void _setError(String? value) {
//     _error = value;
//     notifyListeners();
//   }

//   Future<void> loadCategories() async {
//     _setLoading(true);
//     _setError(null);

//     try {
//       _categories = await _databaseService.getAllCategories();
//       await Future.wait(_categories.map((category) async {
//         category.subcategories =
//             await _databaseService.getSubcategoriesByCategoryId(category.id!);
//       }));
//     } catch (e) {
//       _setError(AppConstants.errorLoadingData);
//       debugPrint('Error loading categories: $e');
//     } finally {
//       _setLoading(false);
//     }
//   }

//   Future<void> addCategory(String name) async {
//     try {
//       if (await _databaseService.categoryExists(name)) {
//         throw Exception(AppConstants.categoryExists);
//       }
//       await _databaseService.insertCategory(models.Category(name: name));
//       await loadCategories();
//     } catch (e) {
//       debugPrint('Error adding category: $e');
//       rethrow;
//     }
//   }

//   Future<void> deleteCategory(int id) async {
//     try {
//       await _databaseService.deleteCategory(id);
//       _categories.removeWhere((category) => category.id == id);
//       notifyListeners();
//     } catch (e) {
//       debugPrint('Error deleting category: $e');
//       rethrow;
//     }
//   }

//   Future<void> addSubcategory(Subcategory subcategory) async {
//     try {
//       if (await _databaseService.subcategoryExists(
//           subcategory.categoryId, subcategory.name)) {
//         throw Exception(AppConstants.subcategoryExists);
//       }
//       await _databaseService.insertSubcategory(subcategory);
//       await loadCategories();
//     } catch (e) {
//       debugPrint('Error adding subcategory: $e');
//       rethrow;
//     }
//   }

//   Future<void> updateCategory(int id, String newName) async {
//     try {
//       await _databaseService.updateCategoryName(id, newName);
//       await loadCategories();
//     } catch (e) {
//       debugPrint('Error updating category: $e');
//       rethrow;
//     }
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_model.dart' as models;
import '../models/subcategory_model.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

final categoryProvider =
    StateNotifierProvider<CategoryNotifier, CategoryState>((ref) {
  final databaseService = ref.read(databaseServiceProvider);
  return CategoryNotifier(databaseService);
});

class CategoryState {
  final List<models.Category> categories;
  final bool isLoading;
  final String? error;

  CategoryState({
    required this.categories,
    required this.isLoading,
    this.error,
  });

  CategoryState copyWith({
    List<models.Category>? categories,
    bool? isLoading,
    String? error,
  }) {
    return CategoryState(
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class CategoryNotifier extends StateNotifier<CategoryState> {
  final DatabaseService _databaseService;

  CategoryNotifier(this._databaseService)
      : super(CategoryState(categories: [], isLoading: false));

  Future<void> loadCategories() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final categories = await _databaseService.getAllCategories();
      print('Length:${categories.length}');
      await Future.wait(categories.map((category) async {
        category.subcategories =
            await _databaseService.getSubcategoriesByCategoryId(category.id!);
      }));
      state = state.copyWith(categories: categories);
    } catch (e) {
      state = state.copyWith(error: AppConstants.errorLoadingData);
      debugPrint('Error loading categories: $e');
    } finally {
      state = state.copyWith(isLoading: false);
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
      state = state.copyWith(
        categories:
            state.categories.where((category) => category.id != id).toList(),
      );
    } catch (e) {
      debugPrint('Error deleting category: $e');
      rethrow;
    }
  }

  Future<void> addSubcategory(Subcategory subcategory) async {
    try {
      if (await _databaseService.subcategoryExists(
          subcategory.categoryId!, subcategory.name!)) {
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

  Future<void> updateSubcategory(Subcategory subcategory) async {
    try {
      await _databaseService.updateSubcategoryName(
          subcategory.categoryId!, subcategory.name!);
      await loadCategories();
    } catch (e) {
      debugPrint('Error updating subcategory: $e');
      rethrow;
    }
  }

  Future<void> deleteSubcategory(int id) async {
    try {
      await _databaseService.deleteSubcategory(id);
      await loadCategories();
    } catch (e) {
      debugPrint('Error deleting subcategory: $e');
      rethrow;
    }
  }
}
