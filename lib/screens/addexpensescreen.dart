import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:pocket_watcher/helper/databasehelper.dart';
import '../model/transactionmodel.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _expandedCategory;
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Map<String, int> categoryIds = {};
  Map<String, int> subcategoryIds = {};
  Map<String, List<String>> categorySubcategoryMap = {};
  final Map<String, Map<String, TextEditingController>>
      _subCategoryControllers = {};

  @override
  void initState() {
    super.initState();
    _loadCategoryAndSubcategoryData();
  }

  Future<void> _loadCategoryAndSubcategoryData() async {
    try {
      // Load categories
      final categories = await _databaseHelper.getCategories();
      Map<String, int> tempCategoryIds = {};
      Map<String, List<String>> tempCategorySubcategoryMap = {};

      // Initialize the category maps
      for (var category in categories) {
        String categoryName = category['category_name'];
        tempCategoryIds[categoryName] = category['id'];
        tempCategorySubcategoryMap[categoryName] = [];
      }

      // Load subcategories
      final subcategories = await _databaseHelper.getSubcategories();
      Map<String, int> tempSubcategoryIds = {};

      // Organize subcategories under their parent categories
      for (var subcategory in subcategories) {
        String subcategoryName = subcategory['subcategory_name'];
        int categoryId = subcategory['category_id'];
        tempSubcategoryIds[subcategoryName] = subcategory['id'];

        // Find the category name for this category_id
        String? parentCategory = tempCategoryIds.entries
            .firstWhere((entry) => entry.value == categoryId)
            .key;

        if (parentCategory != null) {
          tempCategorySubcategoryMap[parentCategory]?.add(subcategoryName);
        }
      }

      // Update the state
      setState(() {
        categoryIds = tempCategoryIds;
        subcategoryIds = tempSubcategoryIds;
        categorySubcategoryMap = tempCategorySubcategoryMap;

        // Initialize controllers for each subcategory
        _subCategoryControllers.clear();
        categorySubcategoryMap.forEach((category, subcategories) {
          _subCategoryControllers[category] = {};
          for (var subcategory in subcategories) {
            _subCategoryControllers[category]![subcategory] =
                TextEditingController();
          }
        });
      });

      // After loading categories and subcategories, load existing expenses
      await _loadExistingExpenses();

      print('Loaded categories: ${categoryIds.keys}');
      print('Loaded subcategories: ${subcategoryIds.keys}');
      print('Category-Subcategory mapping: $categorySubcategoryMap');
    } catch (e, stackTrace) {
      print('Error loading data: $e');
      print('Stack trace: $stackTrace');
    }
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
      await _loadExistingExpenses();
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

  void _hideKeyboard() {
    FocusScope.of(context).unfocus();
  }

  Future<void> _saveExpenses() async {
    _hideKeyboard();

    try {
      print('Current categoryIds: $categoryIds');
      print('Current subcategoryIds: $subcategoryIds');

      if (categoryIds.isEmpty) {
        print('Categories not loaded, attempting to reload...');
        await _loadCategoryAndSubcategoryData();

        if (categoryIds.isEmpty) {
          throw Exception('Categories failed to load. Please try again.');
        }
      }

      bool hasValidData = false;

      for (var category in _subCategoryControllers.keys) {
        print('Processing category: $category');

        for (var subCategory in _subCategoryControllers[category]!.keys) {
          String amountText =
              _subCategoryControllers[category]![subCategory]!.text.trim();

          if (amountText.isNotEmpty) {
            double amount = double.tryParse(amountText) ?? 0.0;
            if (amount > 0) {
              hasValidData = true;

              final categoryId = categoryIds[category];
              print('Category: $category, ID: $categoryId');

              final subcategoryId = subcategoryIds[subCategory];
              print('Subcategory: $subCategory, ID: $subcategoryId');

              if (categoryId == null) {
                throw Exception('Category ID not found for: $category');
              }

              TransactionModel transaction = TransactionModel(
                date: _selectedDate.toString().split(' ')[0],
                amount: amount,
                categoryId: categoryId,
                subcategoryId: subcategoryId,
                description: '',
              );

              await _databaseHelper.insertTransaction(transaction);
            }
          }
        }
      }

      if (!hasValidData) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter at least one expense amount'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      if (hasValidData) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Expenses saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          // Check if we can pop the current route
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            // If we can't pop (came from bottom bar), just clear the form
            setState(() {
              _selectedDate = DateTime.now();
              // Clear all text controllers
              _subCategoryControllers.forEach((category, subcategoryMap) {
                subcategoryMap.forEach((subcategory, controller) {
                  controller.clear();
                });
              });
            });
            await _loadExistingExpenses();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving expenses: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadExistingExpenses() async {
    try {
      final expenses = await _databaseHelper
          .getTransactionsByDate(_selectedDate.toString().split(' ')[0]);

      // Clear all text fields first
      _subCategoryControllers.forEach((category, subcategoryMap) {
        subcategoryMap.forEach((subcategory, controller) {
          controller.clear();
        });
      });

      if (expenses.isEmpty) {
        return; // Return early as all fields are already cleared
      }

      // Populate fields with existing expenses
      for (var expense in expenses) {
        String? categoryName = categoryIds.entries
            .firstWhere((entry) => entry.value == expense['category_id'])
            .key;

        String? subcategoryName = subcategoryIds.entries
            .firstWhere((entry) => entry.value == expense['subcategory_id'])
            .key;

        if (categoryName != null && subcategoryName != null) {
          _subCategoryControllers[categoryName]?[subcategoryName]?.text =
              expense['amount'].toString();
        }
      }
    } catch (e) {
      print('Error loading existing expenses: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _hideKeyboard,
      child: Scaffold(
        appBar: const CupertinoNavigationBar(
          middle: Text("Expenses"),
          backgroundColor: Color.fromARGB(255, 246, 242, 247),
        ),
        body: Padding(
          padding:
              const EdgeInsets.only(left: 16.0, right: 16, top: 16, bottom: 32),
          child: Column(
            children: [
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
              Expanded(
                child: ListView.builder(
                  itemCount: categorySubcategoryMap.length,
                  itemBuilder: (context, index) {
                    String category =
                        categorySubcategoryMap.keys.elementAt(index);
                    List<String> subcategories =
                        categorySubcategoryMap[category] ?? [];

                    return Card(
                      child: ExpansionTile(
                        key: Key(category),
                        title: Text(category),
                        initiallyExpanded: _expandedCategory == category,
                        maintainState: false,
                        onExpansionChanged: (expanded) {
                          _hideKeyboard();
                          _handleExpansion(category, expanded);
                        },
                        children: subcategories
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
                                          controller:
                                              _subCategoryControllers[category]
                                                  ?[subCategory],
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveExpenses,
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
