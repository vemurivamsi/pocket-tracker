// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../providers/category_provider.dart';
// import '../widgets/category_list_item.dart';
// import '../utils/constants.dart';
// import '../widgets/dialogs.dart';

// class CategoryManagementScreen extends StatefulWidget {
//   const CategoryManagementScreen({super.key});

//   @override
//   State<CategoryManagementScreen> createState() =>
//       _CategoryManagementScreenState();
// }

// class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
//   final Map<int, bool> _expandedCategories = {};

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       context.read<CategoryProvider>().loadCategories();
//     });
//   }

//   void _toggleCategory(int categoryId) {
//     setState(() {
//       _expandedCategories[categoryId] =
//           !(_expandedCategories[categoryId] ?? false);
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Category Management"),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.add),
//             onPressed: () => DialogHelper.showAddCategoryDialog(context),
//           ),
//         ],
//       ),
//       body: Consumer<CategoryProvider>(
//         builder: (context, provider, child) {
//           if (provider.isLoading) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           return ListView.builder(
//             itemCount: provider.categories.length,
//             itemBuilder: (context, index) {
//               final category = provider.categories[index];
//               final isExpanded = _expandedCategories[category.id!] ?? false;

//               return CategoryListItem(
//                 category: category,
//                 isExpanded: isExpanded,
//                 onDelete: () => DialogHelper.showDeleteConfirmation(
//                   context,
//                   () => provider.deleteCategory(category.id!),
//                 ),
//                 onAddSubcategory: () => DialogHelper.showSubcategoryDialog(
//                   context,
//                   categoryId: category.id!,
//                 ),
//                 onToggleExpand: () => _toggleCategory(category.id!),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/category_provider.dart';
import '../widgets/category_list_item.dart';
import '../utils/constants.dart';
import '../widgets/dialogs.dart';

class CategoryManagementScreen extends ConsumerStatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  ConsumerState<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState
    extends ConsumerState<CategoryManagementScreen> {
  final Map<int, bool> _expandedCategories = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoryProvider.notifier).loadCategories();
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
            onPressed: () => DialogHelper.showAddCategoryDialog(context, ref),
          ),
        ],
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final provider = ref.watch(categoryProvider);
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemCount: provider.categories.length,
            itemBuilder: (context, index) {
              final category = provider.categories[index];
              final isExpanded = _expandedCategories[category.id!] ?? false;

              return Column(
                children: [
                  CategoryListItem(
                    category: category,
                    isExpanded: isExpanded,
                    onDelete: () => DialogHelper.showDeleteConfirmation(
                      context,
                      () => ref
                          .read(categoryProvider.notifier)
                          .deleteCategory(category.id!),
                    ),
                    onAddSubcategory: () => DialogHelper.showSubcategoryDialog(
                      context,
                      ref,
                      categoryId: category.id!,
                    ),
                    onToggleExpand: () => _toggleCategory(category.id!),
                  ),
                  // Check if subcategories are empty
                  if (category.subcategories!.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('No subcategories available',
                          style: TextStyle(color: Colors.grey)),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
