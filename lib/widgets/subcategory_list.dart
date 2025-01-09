import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subcategory_model.dart';
import '../providers/category_provider.dart';

class SubcategoryList extends ConsumerWidget {
  final List<Subcategory> subcategories;
  final int categoryId;

  const SubcategoryList({
    Key? key,
    required this.subcategories,
    required this.categoryId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  onPressed: (_) => _editSubcategory(context, ref, subcategory),
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
                      _deleteSubcategory(context, ref, subcategory),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  icon: Icons.delete,
                  label: 'Delete',
                ),
              ],
            ),
            child: ListTile(
              title: Text(subcategory.name ?? ""),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _editSubcategory(
      BuildContext context, WidgetRef ref, Subcategory subcategory) {
    final controller = TextEditingController(text: subcategory.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Subcategory"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter Subcategory Name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                try {
                  final updatedSubcategory = subcategory.copyWith(name: name);
                  await ref
                      .read(categoryProvider.notifier)
                      .updateSubcategory(updatedSubcategory);
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _deleteSubcategory(
      BuildContext context, WidgetRef ref, Subcategory subcategory) async {
    try {
      await ref
          .read(categoryProvider.notifier)
          .deleteSubcategory(subcategory.id!);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }
}
