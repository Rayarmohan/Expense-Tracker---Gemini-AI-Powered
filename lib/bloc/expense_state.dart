import 'package:equatable/equatable.dart';
import 'package:expense_tracker/models/expense.dart';

abstract class ExpenseState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ExpenseInitial extends ExpenseState {}

class ExpenseLoading extends ExpenseState {}

class ExpenseLoaded extends ExpenseState {
  final List<Expense> expenses;
  final Map<String, dynamic>? scanResult;
  final bool isScanning;

  ExpenseLoaded({
    required this.expenses,
    this.scanResult,
    this.isScanning = false,
  });

  @override
  List<Object?> get props => [expenses, scanResult, isScanning];

  ExpenseLoaded copyWith({
    List<Expense>? expenses,
    Map<String, dynamic>? scanResult,
    bool? isScanning,
  }) {
    return ExpenseLoaded(
      expenses: expenses ?? this.expenses,
      scanResult: scanResult ?? this.scanResult,
      isScanning: isScanning ?? this.isScanning,
    );
  }
}

class InsightsLoading extends ExpenseState {}

class InsightsLoaded extends ExpenseState {
  final String insights;

  InsightsLoaded({required this.insights});

  @override
  List<Object?> get props => [insights];
}

class ExpenseError extends ExpenseState {
  final String message;

  ExpenseError({required this.message});

  @override
  List<Object?> get props => [message];
}
