import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'package:expense_tracker/data/expense_repository.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/services/gemini_service.dart';

// Events
abstract class ExpenseEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadExpenses extends ExpenseEvent {}

class AddExpense extends ExpenseEvent {
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final String? notes;
  final String? receiptImagePath;

  AddExpense({
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.notes,
    this.receiptImagePath,
  });

  @override
  List<Object?> get props => [title, amount, category, date, notes, receiptImagePath];
}

class UpdateExpense extends ExpenseEvent {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final String? notes;
  final String? receiptImagePath;

  UpdateExpense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.notes,
    this.receiptImagePath,
  });

  @override
  List<Object?> get props => [id, title, amount, category, date, notes, receiptImagePath];
}

class DeleteExpense extends ExpenseEvent {
  final String id;

  DeleteExpense({required this.id});

  @override
  List<Object?> get props => [id];
}

class ScanReceipt extends ExpenseEvent {
  final File imageFile;

  ScanReceipt({required this.imageFile});

  @override
  List<Object?> get props => [imageFile];
}

class ClearScanResult extends ExpenseEvent {}

class ClearAllData extends ExpenseEvent {}

class GenerateInsights extends ExpenseEvent {}

// States
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

// Bloc
class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  final ExpenseRepository _repository;
  final GeminiService _geminiService;
  final _uuid = const Uuid();

  ExpenseBloc({
    required ExpenseRepository repository,
    required GeminiService geminiService,
  })  : _repository = repository,
        _geminiService = geminiService,
        super(ExpenseInitial()) {
    on<LoadExpenses>(_onLoadExpenses);
    on<AddExpense>(_onAddExpense);
    on<UpdateExpense>(_onUpdateExpense);
    on<DeleteExpense>(_onDeleteExpense);
    on<ScanReceipt>(_onScanReceipt);
    on<ClearScanResult>(_onClearScanResult);
    on<ClearAllData>(_onClearAllData);
    on<GenerateInsights>(_onGenerateInsights);
  }

  void _onLoadExpenses(LoadExpenses event, Emitter<ExpenseState> emit) {
    final expenses = _repository.getAll();
    emit(ExpenseLoaded(expenses: expenses));
  }

  Future<void> _onAddExpense(AddExpense event, Emitter<ExpenseState> emit) async {
    try {
      final expense = Expense(
        id: _uuid.v4(),
        title: event.title,
        amount: event.amount,
        category: event.category,
        date: event.date,
        notes: event.notes,
        receiptImagePath: event.receiptImagePath,
        createdAt: DateTime.now(),
      );
      await _repository.add(expense);
      final updated = _repository.getAll();
      emit(ExpenseLoaded(expenses: updated));
    } catch (e) {
      emit(ExpenseError(message: 'Failed to add expense: $e'));
    }
  }

  Future<void> _onUpdateExpense(UpdateExpense event, Emitter<ExpenseState> emit) async {
    try {
      final expense = Expense(
        id: event.id,
        title: event.title,
        amount: event.amount,
        category: event.category,
        date: event.date,
        notes: event.notes,
        receiptImagePath: event.receiptImagePath,
        createdAt: DateTime.now(),
      );
      await _repository.update(expense);
      final updated = _repository.getAll();
      emit(ExpenseLoaded(expenses: updated));
    } catch (e) {
      emit(ExpenseError(message: 'Failed to update expense: $e'));
    }
  }

  Future<void> _onDeleteExpense(DeleteExpense event, Emitter<ExpenseState> emit) async {
    try {
      await _repository.delete(event.id);
      final updated = _repository.getAll();
      emit(ExpenseLoaded(expenses: updated));
    } catch (e) {
      emit(ExpenseError(message: 'Failed to delete expense: $e'));
    }
  }

  Future<void> _onScanReceipt(ScanReceipt event, Emitter<ExpenseState> emit) async {
    debugPrint('========== BLOC SCAN START ==========');
    if (state is ExpenseLoaded) {
      emit((state as ExpenseLoaded).copyWith(isScanning: true));
      debugPrint('Set isScanning = true');
    }

    try {
      debugPrint('Calling GeminiService.scanReceipt...');
      final result = await _geminiService.scanReceipt(event.imageFile);
      debugPrint('GeminiService returned: $result');
      if (state is ExpenseLoaded) {
        debugPrint('Emitting scanResult with data');
        emit((state as ExpenseLoaded).copyWith(
          scanResult: result,
          isScanning: false,
        ));
      }
    } catch (e) {
      debugPrint('Scan error: $e');
      if (state is ExpenseLoaded) {
        emit((state as ExpenseLoaded).copyWith(
          scanResult: {'error': 'Scan failed: $e'},
          isScanning: false,
        ));
      }
    }
    debugPrint('========== BLOC SCAN END ==========');
  }

  void _onClearScanResult(ClearScanResult event, Emitter<ExpenseState> emit) {
    if (state is ExpenseLoaded) {
      emit((state as ExpenseLoaded).copyWith(scanResult: null));
    }
  }

  Future<void> _onClearAllData(ClearAllData event, Emitter<ExpenseState> emit) async {
    try {
      await _repository.clearAll();
      emit(ExpenseLoaded(expenses: []));
    } catch (e) {
      emit(ExpenseError(message: 'Failed to clear data: $e'));
    }
  }

  Future<void> _onGenerateInsights(GenerateInsights event, Emitter<ExpenseState> emit) async {
    emit(InsightsLoading());
    try {
      final expenses = _repository.getAll();
      final insights = await _geminiService.generateInsights(expenses);
      emit(InsightsLoaded(insights: insights));
    } catch (e) {
      emit(ExpenseError(message: 'Failed to generate insights: $e'));
    }
  }
}
