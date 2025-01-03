import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/category_provider.dart';
import '../widgets/category_list_item.dart';
import '../utils/constants.dart';
import '../widgets/dialogs.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final Map<int, bool> _expandedCategories = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadCategories();
    });
  }

  void _toggleCategory(int categoryId) {
    setState(() {
      _expandedCategories[categoryId] =
          !(_expandedCategories[categoryId] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Category Management"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => DialogHelper.showAddCategoryDialog(context),
          ),
        ],
      ),
      body: Consumer<CategoryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemCount: provider.categories.length,
            itemBuilder: (context, index) {
              final category = provider.categories[index];
              final isExpanded = _expandedCategories[category.id!] ?? false;

              return CategoryListItem(
                category: category,
                isExpanded: isExpanded,
                onDelete: () => DialogHelper.showDeleteConfirmation(
                  context,
                  () => provider.deleteCategory(category.id!),
                ),
                onAddSubcategory: () => DialogHelper.showSubcategoryDialog(
                  context,
                  categoryId: category.id!,
                ),
                onToggleExpand: () => _toggleCategory(category.id!),
              );
            },
          );
        },
      ),
    );
  }
}
