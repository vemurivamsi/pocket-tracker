import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _expandedCategory;

  final Map<String, List<String>> _categories = {
    'Food': ['Groceries', 'Dining Out'],
    'Transportation': ['Fuel', 'Public Transport'],
    'Entertainment': ['Movies', 'Games'],
    'Food1': ['Groceries', 'Dining Out'],
    'Transportation1': ['Fuel', 'Public Transport'],
    'Entertainment1': ['Movies', 'Games'],
    'Food2': ['Groceries', 'Dining Out'],
    'Transportation2': ['Fuel', 'Public Transport'],
    'Entertainment2': ['Movies', 'Games'],
    'Food3': ['Groceries', 'Dining Out'],
    'Transportation3': ['Fuel', 'Public Transport'],
    'Entertainment3': ['Movies', 'Games'],
  };

  final Map<String, Map<String, TextEditingController>>
      _subCategoryControllers = {};

  @override
  void initState() {
    super.initState();
    _categories.forEach((category, subCategories) {
      _subCategoryControllers[category] = {};
      for (var subCategory in subCategories) {
        _subCategoryControllers[category]![subCategory] =
            TextEditingController();
      }
    });
  }

  void _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _handleExpansion(String category, bool expanded) {
    setState(() {
      if (expanded) {
        if (_expandedCategory != category) {
          _expandedCategory = category;
        }
      } else if (_expandedCategory == category) {
        _expandedCategory = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CupertinoNavigationBar(
        middle: Text("Expenses"),
        backgroundColor: Color.fromARGB(255, 246, 242, 247),
      ),
      body: Padding(
        padding:
            const EdgeInsets.only(left: 16.0, right: 16, top: 16, bottom: 32),
        child: Column(
          children: [
            // Date Selection Card
            Card(
              child: ListTile(
                title: Text(
                  'Date: ${_selectedDate.toLocal().toString().split(' ')[0]}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
            ),
            const SizedBox(height: 10),
            // Categories with Subcategories
            Expanded(
              child: ListView.builder(
                itemCount: _categories.keys.length,
                itemBuilder: (context, index) {
                  String category = _categories.keys.elementAt(index);
                  return Card(
                    child: ExpansionTile(
                      key: Key(category),
                      title: Text(category),
                      initiallyExpanded: _expandedCategory == category,
                      maintainState: false,
                      onExpansionChanged: (expanded) =>
                          _handleExpansion(category, expanded),
                      children: _categories[category]!
                          .map((subCategory) => Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 4.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(subCategory),
                                    SizedBox(
                                      width: 100,
                                      child: TextField(
                                        controller: _subCategoryControllers[
                                            category]![subCategory],
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'Amount',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Handle Save Logic
                  Map<String, Map<String, double>> savedData = {};
                  _subCategoryControllers.forEach((category, subCategories) {
                    savedData[category] = {};
                    subCategories.forEach((subCategory, controller) {
                      double? value = double.tryParse(controller.text.trim());
                      if (value != null) {
                        savedData[category]![subCategory] = value;
                      }
                    });
                  });
                  if (kDebugMode) {
                    print(savedData);
                  } // For demonstration
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
