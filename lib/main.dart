import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Updated import
import 'package:pocket_watcher/helper/databasehelper.dart';
import 'package:pocket_watcher/screens/addexpensescreen.dart';
import 'package:pocket_watcher/widgets/dialogs.dart';
import 'screens/bottombar_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pocket Watcher',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeWrapper(),
      routes: {
        '/add-expense': (context) => const AddExpenseScreen(),
      },
    );
  }
}

class HomeWrapper extends ConsumerStatefulWidget {
  const HomeWrapper({super.key});

  @override
  ConsumerState<HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends ConsumerState<HomeWrapper> {
  @override
  void initState() {
    super.initState();
    _checkMonthlyIncome();
  }

  Future<void> _checkMonthlyIncome() async {
    await Future.delayed(Duration.zero);

    if (!mounted) return;

    final hasIncome = await DatabaseHelper.instance.hasCurrentMonthIncome();
    if (!hasIncome && mounted) {
      DialogHelper.showAddIncomeDialog(context, ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const MainScreen();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final dbHelper = DatabaseHelper.instance;
    await dbHelper.printDatabasePath();
    final db = await dbHelper.database;

    runApp(
      const ProviderScope(
        // Updated to use ProviderScope
        child: MyApp(),
      ),
    );
  } catch (e, stackTrace) {
    print('Error initializing database: $e');
    print('Stack trace: $stackTrace');
  }
}
