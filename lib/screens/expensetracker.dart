import 'package:flutter/material.dart';
import 'package:pocket_watcher/screens/expensetrackerhome.dart';

class Expensetracker extends StatefulWidget {
  const Expensetracker({super.key});

  @override
  State<Expensetracker> createState() => _ExpensetrackerState();
}

class _ExpensetrackerState extends State<Expensetracker> {
  bool isDarkMode = false;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: ExpenseTrackerHome(
        toggleTheme: () {
          setState(() {
            isDarkMode = !isDarkMode;
          });
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
