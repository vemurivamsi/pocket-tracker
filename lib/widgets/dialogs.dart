import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/income_model.dart';
import '../models/subcategory_model.dart';
import '../providers/category_provider.dart';
import '../providers/income_provider.dart';
import '../utils/constants.dart';
import 'package:intl/intl.dart';

class DialogHelper {
  static void showAddCategoryDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Category"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter Category Name"),
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
                  await context.read<CategoryProvider>().addCategory(name);
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

  static void showDeleteConfirmation(
    BuildContext context,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Category"),
        content: const Text(AppConstants.deleteConfirmation),
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

  static void showSubcategoryDialog(BuildContext context,
      {required int categoryId}) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Subcategory"),
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
                  final subcategory = Subcategory(
                    categoryId: categoryId,
                    name: name,
                  );
                  await context
                      .read<CategoryProvider>()
                      .addSubcategory(subcategory);
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

  static void showAddIncomeDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final _amountController = TextEditingController();
    final _descriptionController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Add Monthly Income'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₹',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final amount = double.parse(_amountController.text);
                final now = DateTime.now();

                final income = IncomeModel(
                  amount: amount,
                  date: DateFormat('yyyy-MM-dd').format(now),
                  description: _descriptionController.text.isNotEmpty
                      ? _descriptionController.text
                      : 'Monthly Income for ${DateFormat('MMMM yyyy').format(now)}',
                );

                try {
                  await context.read<IncomeProvider>().addIncome(income);
                  if (context.mounted) {
                    Navigator.of(context).pop(true);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error adding income: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // Add other dialog methods as needed
}
