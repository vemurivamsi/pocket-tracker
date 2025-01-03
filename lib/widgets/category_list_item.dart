import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../widgets/subcategory_list.dart';

class CategoryListItem extends StatelessWidget {
  final Category category;
  final VoidCallback onDelete;
  final VoidCallback onAddSubcategory;
  final bool isExpanded;
  final VoidCallback onToggleExpand;

  const CategoryListItem({
    Key? key,
    required this.category,
    required this.onDelete,
    required this.onAddSubcategory,
    required this.isExpanded,
    required this.onToggleExpand,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                  onPressed: onAddSubcategory,
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: onDelete,
                ),
                IconButton(
                  icon: Icon(
                    isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  ),
                  onPressed: onToggleExpand,
                ),
              ],
            ),
          ),
          if (isExpanded && category.subcategories.isNotEmpty)
            SubcategoryList(
              subcategories: category.subcategories,
              categoryId: category.id!,
            ),
        ],
      ),
    );
  }
}
