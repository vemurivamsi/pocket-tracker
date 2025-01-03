import 'package:pocket_watcher/models/income_model.dart';
import 'package:pocket_watcher/models/transaction_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:math';
import 'dart:io';

import '../models/category_model.dart';
import '../models/subcategory_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = join(docsDir.path, 'categories_subcategories.db');

    return await openDatabase(dbPath, version: 1, onCreate: _onCreate);
  }

  // Create both Categories and Subcategories tables
  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_name TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE subcategories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER,
        subcategory_name TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE
        UNIQUE (category_id, subcategory_name) -- Enforce unique subcategories under a category
      )
    ''');

    // Create transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        amount REAL NOT NULL,
        category_id INTEGER,
        subcategory_id INTEGER,
        description TEXT,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL,
        FOREIGN KEY (subcategory_id) REFERENCES subcategories(id) ON DELETE SET NULL
      )
    ''');

    // Create income table
    await db.execute('''
      CREATE TABLE income (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        description TEXT
      )
    ''');

    // Insert static data
    await _insertStaticData(db);
  }

  Future<void> _insertStaticData(Database db) async {
    // Static data
    final Map<String, List<String>> staticData = {
      'Housing': [
        'Rent/Mortgage',
        'Utilities (electricity, water, gas)',
        'Internet and cable',
        'Home maintenance or repairs',
        'Property taxes/insurance'
      ],
      'Transportation': [
        'Fuel/gas',
        'Public transportation (bus, train, etc.)',
        'Vehicle maintenance (oil changes, tires)',
        'Car insurance',
        'Parking fees',
        'Loan/lease payments'
      ],
      'Food': [
        'Groceries',
        'Dining out or takeout',
        'Coffee/snacks',
      ],
      'Health and Wellness': [
        'Health insurance',
        'Medications or supplements',
        'Gym memberships or fitness classes',
        'Doctor/dentist visits'
      ],
      'Pet Expenses': [
        'Pet food and treats',
        'Veterinary care (checkups, vaccinations)',
        'Medications or treatments',
        'Pet insurance',
        'Grooming (bathing, nail trims, haircuts)',
        'Supplies (toys, bedding, litter, leashes)',
        'Pet sitting or boarding services'
      ],
      'Debt Payments': [
        'Credit card payments',
        'Student loans',
        'Other personal loans',
      ],
      'Savings and Investments': [
        'Emergency fund contributions',
        'Retirement savings (401(k), IRA, etc.)',
        'Other investments'
      ],
      'Family and Childcare': [
        'Childcare/babysitting',
        'School tuition and supplies',
        'Activities or lessons (e.g., sports, music)',
        'Child support',
      ],
      'Personal and Lifestyle': [
        'Clothing and accessories',
        'Haircuts/personal grooming',
        'Subscriptions (streaming, apps, magazines)',
        'Hobbies and leisure activities',
      ],
      'Insurance': [
        'Life insurance',
        'Home/renter’s insurance',
        'Pet insurance',
      ],
      'Entertainment': [
        'Movies, concerts, events',
        'Vacations/travel',
        'Sports or recreational activities',
      ],
      'Miscellaneous': [
        'Gifts (birthdays, holidays)',
        'Donations or charity',
        'Unexpected expenses',
      ],
    };

    // Insert categories and subcategories
    for (var entry in staticData.entries) {
      int categoryId = await db.insert('categories', {
        'category_name': entry.key,
      });

      for (var subcategory in entry.value) {
        await db.insert('subcategories', {
          'subcategory_name': subcategory,
          'category_id': categoryId,
        });
      }
    }

    // Static monthly income data
    final incomeData = [
      {
        'amount': 50000.0,
        'date': '2024-01-01',
        'description': 'January Salary'
      },
      {
        'amount': 50000.0,
        'date': '2024-02-01',
        'description': 'February Salary'
      },
      {
        'amount': 52000.0, // Bonus month
        'date': '2024-03-01',
        'description': 'March Salary with Performance Bonus'
      },
      {'amount': 50000.0, 'date': '2024-04-01', 'description': 'April Salary'},
      {'amount': 50000.0, 'date': '2024-05-01', 'description': 'May Salary'}
    ];

    // Insert income data
    for (var income in incomeData) {
      await db.insert('income', {
        'amount': income['amount'],
        'date': income['date'],
        'description': income['description'],
      });
    }
  }

  // Insert a category
  Future<int> insertCategory(Category category) async {
    Database db = await instance.database;
    // Check if the category already exists
    bool exists = await categoryExists(category.name);
    if (exists) {
      throw Exception('Category "${category.name}" already exists');
    }
    return await db.insert('categories', category.toMap());
  }

  //Insert a Subcategory
  Future<int> insertSubcategory(Subcategory subcategory) async {
    Database db = await instance.database;
    // Check if the subcategory already exists under the category
    bool exists =
        await subcategoryExists(subcategory.categoryId, subcategory.name);
    if (exists) {
      throw Exception(
          'Subcategory "${subcategory.name}" already exists under category ID ${subcategory.categoryId}');
    }
    return await db.insert('subcategories', subcategory.toMap());
  }

//Fetch All Categories with Subcategories
  Future<List<Category>> getAllCategoriesWithSubcategories() async {
    final db = await database;

    // Query to fetch categories along with their subcategories
    const String query = '''
    SELECT 
      c.id AS category_id,
      c.category_name AS category_name,
      s.id AS subcategory_id,
      s.subcategory_name AS subcategory_name
    FROM categories c
    LEFT JOIN subcategories s ON c.id = s.category_id
    ORDER BY c.id, s.id
  ''';

    final List<Map<String, dynamic>> result = await db.rawQuery(query);

    // Map the query result into Category and Subcategory objects
    Map<int, Category> categoryMap = {};

    for (var row in result) {
      int categoryId = row['category_id'] as int;
      String categoryName = row['category_name'] as String;

      // Create or update the category object
      if (!categoryMap.containsKey(categoryId)) {
        categoryMap[categoryId] = Category(
          id: categoryId,
          name: categoryName,
          subcategories: [],
        );
      }

      // Add subcategory to the corresponding category if it exists
      if (row['subcategory_id'] != null) {
        categoryMap[categoryId]?.subcategories.add(
              Subcategory(
                id: row['subcategory_id'] as int,
                name: row['subcategory_name'] as String,
                categoryId: categoryId,
              ),
            );
      }
    }

    return categoryMap.values.toList();
  }

  // Fetch all categories
  Future<List<Category>> getAllCategories() async {
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query('categories');
    return maps.map((map) => Category.fromMap(map)).toList();
  }

  // Fetch subcategories for a given category
  Future<List<Subcategory>> getSubcategoriesByCategoryId(int categoryId) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query(
      'subcategories',
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
    return maps.map((map) => Subcategory.fromMap(map)).toList();
  }

  // Delete category and its subcategories
  Future<void> deleteCategory(int categoryId) async {
    Database db = await instance.database;
    await db.delete(
      'subcategories',
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
    await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [categoryId],
    );
  }

  // Delete a subcategory
  Future<void> deleteSubcategory(int subcategoryId) async {
    Database db = await instance.database;
    await db.delete(
      'subcategories',
      where: 'id = ?',
      whereArgs: [subcategoryId],
    );
  }

  // Get Category ID by Category Name
  Future<int?> getCategoryIdByName(String categoryName) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> result = await db.query(
      'categories',
      columns: ['id'],
      where: 'category_name = ?',
      whereArgs: [categoryName],
      limit: 1,
    );
    return result.isNotEmpty ? result.first['id'] as int : null;
  }

// Get Category Details Using Subcategory
  Future<Category?> getCategoryBySubcategory(String subcategoryName) async {
    Database db = await instance.database;
    String query = '''
    SELECT c.id, c.category_name
    FROM categories c
    INNER JOIN subcategories s ON c.id = s.category_id
    WHERE s.subcategory_name = ?
  ''';
    List<Map<String, dynamic>> result =
        await db.rawQuery(query, [subcategoryName]);
    return result.isNotEmpty ? Category.fromMap(result.first) : null;
  }

// Get All Subcategories by Category Name
  Future<List<Subcategory>> getSubcategoriesByCategoryName(
      String categoryName) async {
    Database db = await instance.database;

    String query = '''
    SELECT s.id, s.subcategory_name, s.category_id
    FROM subcategories s
    INNER JOIN categories c ON s.category_id = c.id
    WHERE c.category_name = ?
  ''';

    List<Map<String, dynamic>> result =
        await db.rawQuery(query, [categoryName]);
    return result.map((map) => Subcategory.fromMap(map)).toList();
  }

// Update Category Name
  Future<int> updateCategoryName(int categoryId, String newCategoryName) async {
    Database db = await instance.database;
    return await db.update(
      'categories',
      {'category_name': newCategoryName},
      where: 'id = ?',
      whereArgs: [categoryId],
    );
  }

// Update Subcategory Name
  Future<int> updateSubcategoryName(
      int subcategoryId, String newSubcategoryName) async {
    Database db = await instance.database;
    return await db.update(
      'subcategories',
      {'subcategory_name': newSubcategoryName},
      where: 'id = ?',
      whereArgs: [subcategoryId],
    );
  }

// Check if Category Exists
  Future<bool> categoryExists(String categoryName) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> result = await db.query(
      'categories',
      where: 'category_name = ?',
      whereArgs: [categoryName],
      limit: 1,
    );
    return result.isNotEmpty;
  }

// Check if Subcategory Exists Under a Category
  Future<bool> subcategoryExists(int categoryId, String subcategoryName) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> result = await db.query(
      'subcategories',
      where: 'category_id = ? AND subcategory_name = ?',
      whereArgs: [categoryId, subcategoryName],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  // // Insert a transaction
  // Future<int> insertTransaction(TransactionModel transaction) async {
  //   Database db = await instance.database;
  //   return await db.insert('transactions', transaction.toMap());
  // }

  // Get all transactions
  Future<List<TransactionModel>> getAllTransactions() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('transactions');
    return List.generate(maps.length, (i) => TransactionModel.fromMap(maps[i]));
  }

  // Get transactions by date range
  Future<List<TransactionModel>> getTransactionsByDateRange(
      DateTime startDate, DateTime endDate) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [
        startDate.toIso8601String().split('T')[0],
        endDate.toIso8601String().split('T')[0]
      ],
    );
    return List.generate(maps.length, (i) => TransactionModel.fromMap(maps[i]));
  }

  // Get transactions by category
  Future<List<TransactionModel>> getTransactionsByCategory(
      int categoryId) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
    return List.generate(maps.length, (i) => TransactionModel.fromMap(maps[i]));
  }

  // Update a transaction
  Future<int> updateTransaction(TransactionModel transaction) async {
    Database db = await instance.database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  // Delete a transaction
  Future<int> deleteTransaction(int id) async {
    Database db = await instance.database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get total amount spent
  Future<double> getTotalAmount() async {
    Database db = await instance.database;
    final result =
        await db.rawQuery('SELECT SUM(amount) as total FROM transactions');
    return result.first['total'] as double? ?? 0.0;
  }

  // Get total amount by category
  Future<double> getTotalAmountByCategory(int categoryId) async {
    Database db = await instance.database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE category_id = ?',
      [categoryId],
    );
    return result.first['total'] as double? ?? 0.0;
  }

  // Get total amount for a specific day
  Future<double> getTotalByDate(DateTime date) async {
    Database db = await instance.database;
    final String dateStr = date.toIso8601String().split('T')[0];
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE date = ?',
      [dateStr],
    );
    return result.first['total'] as double? ?? 0.0;
  }

  // Get total amount for a specific month
  Future<double> getTotalByMonth(int year, int month) async {
    Database db = await instance.database;
    // Create date strings for the first and last day of the month
    final String startDate =
        DateTime(year, month, 1).toIso8601String().split('T')[0];
    final String endDate =
        DateTime(year, month + 1, 0).toIso8601String().split('T')[0];

    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE date BETWEEN ? AND ?',
      [startDate, endDate],
    );
    return result.first['total'] as double? ?? 0.0;
  }

  // Get total amount for a specific year
  Future<double> getTotalByYear(int year) async {
    Database db = await instance.database;
    final String startDate =
        DateTime(year, 1, 1).toIso8601String().split('T')[0];
    final String endDate =
        DateTime(year, 12, 31).toIso8601String().split('T')[0];

    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE date BETWEEN ? AND ?',
      [startDate, endDate],
    );
    return result.first['total'] as double? ?? 0.0;
  }

  // Get monthly breakdown for a specific year
  Future<Map<int, double>> getMonthlyTotals(int year) async {
    Database db = await instance.database;
    final Map<int, double> monthlyTotals = {};

    for (int month = 1; month <= 12; month++) {
      final String startDate =
          DateTime(year, month, 1).toIso8601String().split('T')[0];
      final String endDate =
          DateTime(year, month + 1, 0).toIso8601String().split('T')[0];

      final result = await db.rawQuery(
        'SELECT SUM(amount) as total FROM transactions WHERE date BETWEEN ? AND ?',
        [startDate, endDate],
      );
      monthlyTotals[month] = result.first['total'] as double? ?? 0.0;
    }

    return monthlyTotals;
  }

  // Get daily breakdown for a specific month
  Future<Map<int, double>> getDailyTotals(int year, int month) async {
    Database db = await instance.database;
    final Map<int, double> dailyTotals = {};

    final int daysInMonth = DateTime(year, month + 1, 0).day;

    for (int day = 1; day <= daysInMonth; day++) {
      final String dateStr =
          DateTime(year, month, day).toIso8601String().split('T')[0];

      final result = await db.rawQuery(
        'SELECT SUM(amount) as total FROM transactions WHERE date = ?',
        [dateStr],
      );
      dailyTotals[day] = result.first['total'] as double? ?? 0.0;
    }

    return dailyTotals;
  }

  // Get transactions summary by date range with category breakdown
  Future<List<Map<String, dynamic>>> getTransactionsSummary(
      DateTime startDate, DateTime endDate) async {
    Database db = await instance.database;
    final String startDateStr = startDate.toIso8601String().split('T')[0];
    final String endDateStr = endDate.toIso8601String().split('T')[0];

    return await db.rawQuery('''
      SELECT 
        t.date,
        c.category_name,
        SUM(t.amount) as total_amount,
        COUNT(*) as transaction_count
      FROM transactions t
      LEFT JOIN categories c ON t.category_id = c.id
      WHERE t.date BETWEEN ? AND ?
      GROUP BY t.date, c.category_name
      ORDER BY t.date DESC, total_amount DESC
    ''', [startDateStr, endDateStr]);
  }

  Future<Map<String, dynamic>?> getIncomeForMonth(int month, int year) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'income',
      where: 'month = ? AND year = ?',
      whereArgs: [month, year],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updateIncome(Map<String, dynamic> income) async {
    final db = await database;
    return await db.update(
      'income',
      income,
      where: 'month = ? AND year = ?',
      whereArgs: [income['month'], income['year']],
    );
  }

  Future<int> deleteIncome(int month, int year) async {
    final db = await database;
    return await db.delete(
      'income',
      where: 'month = ? AND year = ?',
      whereArgs: [month, year],
    );
  }

  // Add methods for income management
  Future<double> getMonthlyIncome(int year, int month) async {
    Database db = await instance.database;
    final String startDate =
        DateTime(year, month, 1).toIso8601String().split('T')[0];
    final String endDate =
        DateTime(year, month + 1, 0).toIso8601String().split('T')[0];

    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM income WHERE date BETWEEN ? AND ?',
      [startDate, endDate],
    );
    return result.first['total'] as double? ?? 0.0;
  }

  Future<int> insertIncome(IncomeModel income) async {
    Database db = await instance.database;
    return await db.insert('income', income.toMap());
  }

  Future<List<IncomeModel>> getIncomeByMonth(int year, int month) async {
    Database db = await instance.database;
    final String startDate =
        DateTime(year, month, 1).toIso8601String().split('T')[0];
    final String endDate =
        DateTime(year, month + 1, 0).toIso8601String().split('T')[0];

    final List<Map<String, dynamic>> maps = await db.query(
      'income',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDate, endDate],
    );
    return List.generate(maps.length, (i) => IncomeModel.fromMap(maps[i]));
  }

  Future<double> getTotalByDateRange(
      DateTime startDate, DateTime endDate) async {
    Database db = await instance.database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE date BETWEEN ? AND ?',
      [
        startDate.toIso8601String().split('T')[0],
        endDate.toIso8601String().split('T')[0],
      ],
    );
    return result.first['total'] as double? ?? 0.0;
  }

  Future<List<int>> getUniqueTransactionYears() async {
    Database db = await instance.database;
    List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT DISTINCT substr(date, 1, 4) as year 
      FROM transactions 
      ORDER BY year DESC
    ''');

    return result.map((row) => int.parse(row['year'].toString())).toList();
  }

  Future<List<int>> getUniqueMonthsForYear(int year) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT DISTINCT substr(date, 6, 2) as month 
      FROM transactions 
      WHERE substr(date, 1, 4) = ?
      ORDER BY month DESC
    ''', [year.toString()]);

    return result.map((row) => int.parse(row['month'].toString())).toList();
  }

  Future<void> insertStaticData() async {
    final db = await database;

    // First, clear existing data if any
    await db.delete('transactions');
    await db.delete('subcategories');
    await db.delete('categories');
    await db.delete('income');

    // Reset auto-increment counters
    await db.execute('DELETE FROM sqlite_sequence WHERE name=\'categories\'');
    await db
        .execute('DELETE FROM sqlite_sequence WHERE name=\'subcategories\'');
    await db.execute('DELETE FROM sqlite_sequence WHERE name=\'transactions\'');
    await db.execute('DELETE FROM sqlite_sequence WHERE name=\'income\'');

    // Categories with subcategories
    final categories = [
      {
        'category_name': 'Food & Dining',
        'subcategories': [
          'Restaurants',
          'Groceries',
          'Coffee Shops',
          'Food Delivery'
        ]
      },
      {
        'category_name': 'Transportation',
        'subcategories': [
          'Fuel',
          'Public Transit',
          'Car Maintenance',
          'Parking'
        ]
      },
      {
        'category_name': 'Shopping',
        'subcategories': [
          'Clothing',
          'Electronics',
          'Home Goods',
          'Personal Care'
        ]
      },
      {
        'category_name': 'Bills & Utilities',
        'subcategories': ['Electricity', 'Water', 'Internet', 'Phone']
      },
      {
        'category_name': 'Entertainment',
        'subcategories': ['Movies', 'Games', 'Sports', 'Hobbies']
      }
    ];

    // Insert categories and get their IDs
    Map<String, int> categoryIds = {};
    Map<String, int> subcategoryIds = {};

    for (var category in categories) {
      final categoryId = await db
          .insert('categories', {'category_name': category['category_name']});
      categoryIds[category['category_name'] as String] = categoryId;

      // Insert subcategories
      for (var subcategory in (category['subcategories'] as List)) {
        final subcategoryId = await db.insert('subcategories', {
          'subcategory_name': subcategory,
          'category_id': categoryId,
        });
        subcategoryIds[subcategory] = subcategoryId;
      }
    }

    // Insert monthly income data
    final incomeData = [
      {
        'amount': 50000.0,
        'date': '2024-01-01',
        'description': 'January Salary'
      },
      {
        'amount': 50000.0,
        'date': '2024-02-01',
        'description': 'February Salary'
      },
      {
        'amount': 52000.0,
        'date': '2024-03-01',
        'description': 'March Salary with Performance Bonus'
      },
      {'amount': 50000.0, 'date': '2024-04-01', 'description': 'April Salary'},
      {'amount': 50000.0, 'date': '2024-05-01', 'description': 'May Salary'}
    ];

    // Insert income data
    for (var income in incomeData) {
      await db.insert('income', income);
    }

    // Generate expense transactions for first 5 months of 2024
    final random = Random();
    for (int month = 1; month <= 5; month++) {
      // Generate 15-20 expense transactions per month
      int transactionsCount = 15 + random.nextInt(6);

      for (int i = 0; i < transactionsCount; i++) {
        // Random date within the month
        final day = 1 + random.nextInt(DateTime(2024, month + 1, 0).day);
        final date =
            '2024-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

        // Random category and subcategory
        final category = categories[random.nextInt(categories.length)];
        final categoryName = category['category_name'] as String;
        final subcategories = category['subcategories'] as List;
        final subcategoryName =
            subcategories[random.nextInt(subcategories.length)];

        // Random expense amount between 100 and 5000
        final amount = 100 + random.nextInt(4901) + random.nextDouble();

        await db.insert('transactions', {
          'amount': amount.roundToDouble(),
          'date': date,
          'description': 'Expense for $subcategoryName',
          'category_id': categoryIds[categoryName],
          'subcategory_id': subcategoryIds[subcategoryName],
        });
      }
    }
  }

  // / Add this method to DatabaseHelper
  Future<bool> hasAnyTransactions() async {
    final db = await database;
    final result = await db.query('transactions', limit: 1);
    return result.isNotEmpty;
  }

  // Add this method to print the database path
  Future<void> printDatabasePath() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = join(docsDir.path, 'categories_subcategories.db');
    print('Database path: $dbPath');

    // Also print the directory contents
    try {
      final dir = Directory(docsDir.path);
      final List<FileSystemEntity> entities = await dir.list().toList();
      print('\nDirectory contents:');
      for (var entity in entities) {
        print(entity.path);
      }
    } catch (e) {
      print('Error listing directory: $e');
    }
  }

  // Get total expenses for a specific month
  Future<double> getTotalExpensesByMonth(int year, int month) async {
    final db = await database;
    final startDate = DateTime(year, month, 1).toIso8601String();
    final endDate = DateTime(year, month + 1, 0).toIso8601String();

    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0.0) as total 
      FROM transactions 
      WHERE date BETWEEN ? AND ?
    ''', [startDate, endDate]);

    return (result.first['total'] as num).toDouble();
  }

  // Get total income for a specific month
  Future<double> getTotalIncomeByMonth(int year, int month) async {
    final db = await database;

    // Format date to match exactly with income table format
    final monthStr = month.toString().padLeft(2, '0');
    final datePattern = '$year-$monthStr-%';

    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0.0) as total 
      FROM income 
      WHERE date LIKE ?
    ''', [datePattern]);

    print('Income query for: $datePattern'); // Debug print
    print('Query result: ${result.first}'); // Debug print

    return (result.first['total'] as num).toDouble();
  }

  // Get total income for a year
  Future<double> getTotalIncomeByYear(int year) async {
    final db = await database;
    final startDate = DateTime(year, 1, 1).toIso8601String();
    final endDate = DateTime(year, 12, 31).toIso8601String();

    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0.0) as total 
      FROM income 
      WHERE date BETWEEN ? AND ?
    ''', [startDate, endDate]);

    return (result.first['total'] as num).toDouble();
  }

  // Get total income for a date range
  Future<double> getTotalIncomeByDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final startDate = start.toIso8601String();
    final endDate = end.toIso8601String();

    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0.0) as total 
      FROM income 
      WHERE date BETWEEN ? AND ?
    ''', [startDate, endDate]);

    return (result.first['total'] as num).toDouble();
  }

  Future<String?> getCategoryNameById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'categories',
      columns: ['category_name'],
      where: 'id = ?',
      whereArgs: [id],
    );

    return result.isNotEmpty ? result.first['category_name'] as String : null;
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await database;
    return await db.query('categories');
  }

  Future<List<Map<String, dynamic>>> getTransactionsByDate(String date) async {
    final db = await database;
    return await db.query(
      'transactions',
      where: 'date = ?',
      whereArgs: [date],
    );
  }

  Future<List<Map<String, dynamic>>> getSubcategories() async {
    final db = await database;
    return await db.query('subcategories');
  }

  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await database;
    return await db.insert(
      'transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
