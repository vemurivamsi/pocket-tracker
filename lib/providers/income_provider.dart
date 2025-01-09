// import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_watcher/providers/category_provider.dart';

import '../helper/databasehelper.dart';
import '../models/income_model.dart';

final databaseServiceProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});

final incomeProvider =
    StateNotifierProvider<IncomeNotifier, IncomeState>((ref) {
  final databaseService = ref.read(databaseServiceProvider);
  return IncomeNotifier(databaseService);
});

class IncomeState {
  final List<IncomeModel> incomeEntries;
  final bool isLoading;
  final String? error;

  IncomeState({
    required this.incomeEntries,
    required this.isLoading,
    this.error,
  });

  IncomeState copyWith({
    List<IncomeModel>? incomeEntries,
    bool? isLoading,
    String? error,
  }) {
    return IncomeState(
      incomeEntries: incomeEntries ?? this.incomeEntries,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class IncomeNotifier extends StateNotifier<IncomeState> {
  final DatabaseHelper _databaseService;

  IncomeNotifier(this._databaseService)
      : super(IncomeState(incomeEntries: [], isLoading: false));

  Future<void> loadIncomeByMonth(int year, int month) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final entries = await _databaseService.getIncomeByMonth(year, month);

      if (!mounted) return; // Check if we're still mounted/loading

      state = state.copyWith(incomeEntries: entries);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      debugPrint('Error loading income: $e');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> addIncome(IncomeModel income) async {
    try {
      await _databaseService.insertIncome(income);
      final now = DateTime.now();
      await loadIncomeByMonth(now.year, now.month);
      return true;
    } catch (e) {
      debugPrint('Error adding income: $e');
      rethrow;
    }
  }
}
