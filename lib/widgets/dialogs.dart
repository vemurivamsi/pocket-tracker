// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../models/income_model.dart';
// import '../models/subcategory_model.dart';
// import '../providers/category_provider.dart';
// import '../providers/income_provider.dart';
// import '../utils/constants.dart';
// import 'package:intl/intl.dart';

// class DialogHelper {
//   static void showAddCategoryDialog(BuildContext context) {
//     final controller = TextEditingController();
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("Add Category"),
//         content: TextField(
//           controller: controller,
//           decoration: const InputDecoration(hintText: "Enter Category Name"),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("Cancel"),
//           ),
//           TextButton(
//             onPressed: () async {
//               final name = controller.text.trim();
//               if (name.isNotEmpty) {
//                 try {
//                   await context.read<CategoryProvider>().addCategory(name);
//                   Navigator.pop(context);
//                 } catch (e) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text(e.toString())),
//                   );
//                 }
//               }
//             },
//             child: const Text("Save"),
//           ),
//         ],
//       ),
//     );
//   }

//   static void showDeleteConfirmation(
//     BuildContext context,
//     VoidCallback onConfirm,
//   ) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("Delete Category"),
//         content: const Text(AppConstants.deleteConfirmation),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("Cancel"),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               onConfirm();
//             },
//             child: const Text("Delete"),
//           ),
//         ],
//       ),
//     );
//   }

//   static void showSubcategoryDialog(BuildContext context,
//       {required int categoryId}) {
//     final controller = TextEditingController();
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("Add Subcategory"),
//         content: TextField(
//           controller: controller,
//           decoration: const InputDecoration(hintText: "Enter Subcategory Name"),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("Cancel"),
//           ),
//           TextButton(
//             onPressed: () async {
//               final name = controller.text.trim();
//               if (name.isNotEmpty) {
//                 try {
//                   final subcategory = Subcategory(
//                     categoryId: categoryId,
//                     name: name,
//                   );
//                   await context
//                       .read<CategoryProvider>()
//                       .addSubcategory(subcategory);
//                   Navigator.pop(context);
//                 } catch (e) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text(e.toString())),
//                   );
//                 }
//               }
//             },
//             child: const Text("Save"),
//           ),
//         ],
//       ),
//     );
//   }

//   static void showAddIncomeDialog(BuildContext context) {
//     final _formKey = GlobalKey<FormState>();
//     final _amountController = TextEditingController();
//     final _descriptionController = TextEditingController();

//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         title: const Text('Add Monthly Income'),
//         content: Form(
//           key: _formKey,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextFormField(
//                 controller: _amountController,
//                 keyboardType: TextInputType.number,
//                 decoration: const InputDecoration(
//                   labelText: 'Amount',
//                   prefixText: '₹',
//                 ),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter an amount';
//                   }
//                   if (double.tryParse(value) == null) {
//                     return 'Please enter a valid number';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 16),
//               TextFormField(
//                 controller: _descriptionController,
//                 decoration: const InputDecoration(
//                   labelText: 'Description (Optional)',
//                 ),
//               ),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(false),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               if (_formKey.currentState!.validate()) {
//                 final amount = double.parse(_amountController.text);
//                 final now = DateTime.now();

//                 final income = IncomeModel(
//                   amount: amount,
//                   date: DateFormat('yyyy-MM-dd').format(now),
//                   description: _descriptionController.text.isNotEmpty
//                       ? _descriptionController.text
//                       : 'Monthly Income for ${DateFormat('MMMM yyyy').format(now)}',
//                 );

//                 try {
//                   await context.read<IncomeProvider>().addIncome(income);
//                   if (context.mounted) {
//                     Navigator.of(context).pop(true);
//                   }
//                 } catch (e) {
//                   if (context.mounted) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(content: Text('Error adding income: $e')),
//                     );
//                   }
//                 }
//               }
//             },
//             child: const Text('Add'),
//           ),
//         ],
//       ),
//     );
//   }

//   // Add other dialog methods as needed
// }
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/income_model.dart';
import '../models/subcategory_model.dart';
import '../providers/category_provider.dart';
import '../providers/income_provider.dart';
import '../utils/constants.dart';
import 'package:intl/intl.dart';

class DialogHelper {
  static void showAddCategoryDialog(BuildContext context, WidgetRef ref) {
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
                  await ref.read(categoryProvider.notifier).addCategory(name);
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

  static void showAddIncomeDialog(BuildContext context, WidgetRef ref) {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    final dateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Income"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: "Enter Amount"),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(hintText: "Enter Description"),
            ),
            TextField(
              controller: dateController,
              decoration: const InputDecoration(hintText: "Enter Date"),
              onTap: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
                if (pickedDate != null) {
                  dateController.text =
                      DateFormat('yyyy-MM-dd').format(pickedDate);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text.trim());
              final description = descriptionController.text.trim();
              final date = dateController.text.trim();

              if (amount != null && date.isNotEmpty) //&& description.isNotEmpty
              {
                try {
                  final income = IncomeModel(
                    amount: amount,
                    description: description,
                    date: date,
                  );
                  bool isIncomeAdded =
                      await ref.read(incomeProvider.notifier).addIncome(income);
                  if (isIncomeAdded) {
                    Navigator.pop(context);
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please fill in all fields")),
                );
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  static void showSubcategoryDialog(BuildContext context, WidgetRef ref,
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
                  await ref
                      .read(categoryProvider.notifier)
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

  static void showDeleteConfirmation(
      BuildContext context, VoidCallback onDelete) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Confirmation"),
        content: const Text("Are you sure you want to delete this item?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              onDelete();
              Navigator.pop(context);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}
