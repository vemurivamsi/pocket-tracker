import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:pocket_watcher/helper/databasehelper.dart';
import 'package:pocket_watcher/model/categorymodel.dart';
import 'package:pocket_watcher/model/subcategorymodel.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  List<Category> _categories = [];
  final Map<int, bool> _expandedCategories =
      {}; // Track expanded state by category ID

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  // Load categories and their subcategories from the database
  Future<void> _loadCategories() async {
    List<Category> categories = await _databaseHelper.getAllCategories();
    for (var category in categories) {
      category.subcategories =
          await _databaseHelper.getSubcategoriesByCategoryId(category.id!);
    }
    setState(() {
      _categories = categories;
    });
  }

  // Show dialog to add or edit a subcategory
  void _showSubcategoryDialog({
    required int categoryId,
    Subcategory? subcategory,
  }) {
    TextEditingController subcategoryController =
        TextEditingController(text: subcategory?.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text(subcategory == null ? 'Add Subcategory' : 'Edit Subcategory'),
        content: TextField(
          controller: subcategoryController,
          decoration: const InputDecoration(hintText: "Enter Subcategory"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              String subcategoryName = subcategoryController.text.trim();
              if (subcategoryName.isNotEmpty) {
                if (subcategory == null) {
                  try {
                    await _databaseHelper.insertSubcategory(
                      Subcategory(
                        categoryId: categoryId,
                        name: subcategoryName,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text("Failed to add Subcategory $e")));
                  }
                } else {
                  await _databaseHelper.updateSubcategoryName(
                      subcategory.id!, subcategoryName);
                }
                _loadCategories(); // Refresh list
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please enter a subcategory")),
                );
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // Delete a category and its subcategories
  void _deleteCategory(int categoryId) {
    _showDeleteConfirmation(
      title: "Delete Category",
      message:
          "Are you sure you want to delete this category? All associated subcategories will also be deleted.",
      onConfirm: () async {
        await _databaseHelper.deleteCategory(categoryId);
        _loadCategories();
      },
    );
  }

  // Delete a specific subcategory
  void _deleteSubcategory(int subcategoryId) {
    _showDeleteConfirmation(
      title: "Delete Subcategory",
      message: "Are you sure you want to delete this subcategory?",
      onConfirm: () async {
        await _databaseHelper.deleteSubcategory(subcategoryId);
        _loadCategories();
      },
    );
  }

  // Toggle expanded/collapsed state of a category
  void _toggleCategory(int categoryId) {
    setState(() {
      _expandedCategories[categoryId] =
          !(_expandedCategories[categoryId] ?? false);
    });
  }

  // Show dialog to add a new category
  void _showAddCategoryDialog() {
    TextEditingController categoryController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Category"),
        content: TextField(
          controller: categoryController,
          decoration: const InputDecoration(hintText: "Enter Category Name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              String categoryName = categoryController.text.trim();
              if (categoryName.isNotEmpty) {
                try {
                  await _databaseHelper
                      .insertCategory(Category(name: categoryName));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to add Category $e")),
                  );
                }
                _loadCategories(); // Refresh list
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please enter a category")));
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // Show a confirmation dialog
  void _showDeleteConfirmation({
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Category Management"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddCategoryDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCategories,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          Category category = _categories[index];
          bool isExpanded = _expandedCategories[category.id!] ?? false;

          return Card(
            elevation: 4.0,
            margin: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                ListTile(
                  title: Text(category.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => _showSubcategoryDialog(
                          categoryId: category.id!,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteCategory(category.id!),
                      ),
                      IconButton(
                        icon: Icon(isExpanded
                            ? Icons.arrow_drop_up
                            : Icons.arrow_drop_down),
                        onPressed: () => _toggleCategory(category.id!),
                      ),
                    ],
                  ),
                ),
                if (isExpanded && category.subcategories.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: category.subcategories.map((subcategory) {
                        return Slidable(
                          key: Key(subcategory.id.toString()), // Unique Key
                          startActionPane: ActionPane(
                            motion: const ScrollMotion(),
                            children: [
                              SlidableAction(
                                onPressed: (_) => _showSubcategoryDialog(
                                    categoryId: category.id!,
                                    subcategory: subcategory),
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                icon: Icons.edit,
                                label: 'Edit',
                              ),
                            ],
                          ),
                          endActionPane: ActionPane(
                            motion: const ScrollMotion(),
                            children: [
                              SlidableAction(
                                onPressed: (_) =>
                                    _deleteSubcategory(subcategory.id!),
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                icon: Icons.delete,
                                label: 'Delete',
                              ),
                            ],
                          ),
                          child: ListTile(
                            title: Text(subcategory.name),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
