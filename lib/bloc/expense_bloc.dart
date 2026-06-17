import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:expense_tracker/bloc/expense_event.dart';
import 'package:expense_tracker/bloc/expense_state.dart';
import 'package:expense_tracker/data/expense_repository.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/services/gemini_service.dart';

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
