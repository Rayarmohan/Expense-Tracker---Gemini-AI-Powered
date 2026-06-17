import 'dart:io';
import 'package:equatable/equatable.dart';

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
