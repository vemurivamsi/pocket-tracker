import 'package:flutter/material.dart';
import 'package:pocket_watcher/helper/databasehelper.dart';
import 'package:pocket_watcher/screens/expensetracker.dart';

// void main() {
//   runApp(const Expensetracker());
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final dbHelper = DatabaseHelper.instance;

    await dbHelper.printDatabasePath();

    // Initialize database and check for data
    // final db = await dbHelper.database;
    final hasData = await dbHelper.hasAnyTransactions();

    if (!hasData) {
      print('Inserting static data...');
      await dbHelper.insertStaticData();
      print('Static data inserted');
    }

    runApp(const Expensetracker());
  } catch (e, stackTrace) {
    print('Error initializing database: $e');
    print('Stack trace: $stackTrace');
  }
}
