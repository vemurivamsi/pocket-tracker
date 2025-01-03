import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/subcategory_model.dart';
import '../providers/category_provider.dart';
import 'package:provider/provider.dart';

class SubcategoryList extends StatelessWidget {
  final List<Subcategory> subcategories;
  final int categoryId;

  const SubcategoryList({
    Key? key,
    required this.subcategories,
    required this.categoryId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: subcategories.map((subcategory) {
          return Slidable(
            key: Key(subcategory.id.toString()),
            startActionPane: ActionPane(
              motion: const ScrollMotion(),
              children: [
                SlidableAction(
                  onPressed: (_) => _editSubcategory(context, subcategory),
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
                      _deleteSubcategory(context, subcategory.id!),
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
    );
  }

  void _editSubcategory(BuildContext context, Subcategory subcategory) {
    // Implement edit functionality
  }

  void _deleteSubcategory(BuildContext context, int subcategoryId) {
    // Implement delete functionality
  }
}
