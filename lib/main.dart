import 'package:flutter/material.dart';
import 'package:pocket_watcher/helper/databasehelper.dart';
import 'package:pocket_watcher/screens/addexpensescreen.dart';
import 'package:pocket_watcher/screens/homescreen.dart';
import 'package:provider/provider.dart';
import 'package:pocket_watcher/providers/category_provider.dart';
import 'package:pocket_watcher/services/database_service.dart';
import 'package:pocket_watcher/screens/bottombar_screen.dart';

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

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => CategoryProvider(DatabaseService()),
          ),
          // Add other providers as needed
        ],
        child: const MyApp(),
      ),
    );
  } catch (e, stackTrace) {
    print('Error initializing database: $e');
    print('Stack trace: $stackTrace');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pocket Watcher',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Define your routes
      home: const MainScreen(), // Set initial route
      routes: {
        '/add-expense': (context) => const AddExpenseScreen(), // Add this route
      },
    );
  }
}
