import 'package:flutter/material.dart';
import 'package:pocket_watcher/helper/databasehelper.dart';
import 'package:pocket_watcher/screens/addexpensescreen.dart';
import 'package:provider/provider.dart';
import 'package:pocket_watcher/providers/transaction_provider.dart';
import 'package:pocket_watcher/providers/income_provider.dart';
import 'package:pocket_watcher/services/database_service.dart';
import 'package:pocket_watcher/screens/bottombar_screen.dart';
import 'package:pocket_watcher/providers/dashboard_provider.dart';

import 'package:pocket_watcher/widgets/dialogs.dart';

// void main() {
//   runApp(const Expensetracker());
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final dbHelper = DatabaseHelper.instance;
    await dbHelper.printDatabasePath();
    final db = await dbHelper.database;

    runApp(const MyApp());
  } catch (e, stackTrace) {
    print('Error initializing database: $e');
    print('Stack trace: $stackTrace');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => TransactionProvider(DatabaseHelper.instance),
        ),
        ChangeNotifierProvider(
          create: (context) => IncomeProvider(DatabaseHelper.instance),
        ),
        ChangeNotifierProvider(
          create: (context) => DashboardProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Pocket Watcher',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const HomeWrapper(),
        routes: {
          '/add-expense': (context) => const AddExpenseScreen(),
        },
      ),
    );
  }
}

// New wrapper widget to handle income check
class HomeWrapper extends StatefulWidget {
  const HomeWrapper({super.key});

  @override
  State<HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<HomeWrapper> {
  @override
  void initState() {
    super.initState();
    _checkMonthlyIncome();
  }

  Future<void> _checkMonthlyIncome() async {
    // Wait for the widget to be properly initialized
    await Future.delayed(Duration.zero);

    if (!mounted) return;

    final hasIncome = await DatabaseHelper.instance.hasCurrentMonthIncome();
    if (!hasIncome && mounted) {
      DialogHelper.showAddIncomeDialog(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const MainScreen();
  }
}
