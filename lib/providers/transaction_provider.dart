// import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/transaction_model.dart';
import '../helper/databasehelper.dart';

final databaseServiceProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});

final transactionProvider =
    StateNotifierProvider<TransactionNotifier, TransactionState>((ref) {
  final databaseService = ref.read(databaseServiceProvider);
  return TransactionNotifier(databaseService);
});

class TransactionState {
  final List<TransactionModel> transactions;
  final bool isLoading;
  final String? error;
  final DateTime startDate;
  final DateTime endDate;

  TransactionState({
    required this.transactions,
    required this.isLoading,
    this.error,
    required this.startDate,
    required this.endDate,
  });

  TransactionState copyWith({
    List<TransactionModel>? transactions,
    bool? isLoading,
    String? error,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

class TransactionNotifier extends StateNotifier<TransactionState> {
  final DatabaseHelper _databaseService;

  TransactionNotifier(this._databaseService)
      : super(TransactionState(
          transactions: [],
          isLoading: false,
          startDate: DateTime.now().subtract(const Duration(days: 30)),
          endDate: DateTime.now(),
        ));

  Future<void> loadTransactionsByDateRange(DateTime start, DateTime end) async {
    if (state.isLoading) return;

    state = state.copyWith(
        isLoading: true, error: null, startDate: start, endDate: end);

    try {
      final loadedTransactions =
          await _databaseService.getTransactionsByDateRange(start, end);

      if (!mounted) return; // Check if we're still mounted/loading

      state = state.copyWith(transactions: loadedTransactions);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      debugPrint('Error loading transactions: $e');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}
