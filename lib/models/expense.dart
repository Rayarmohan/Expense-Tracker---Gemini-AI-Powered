import 'package:hive_flutter/hive_flutter.dart';

class Expense extends HiveObject {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final String? notes;
  final String? receiptImagePath;
  final DateTime createdAt;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.notes,
    this.receiptImagePath,
    required this.createdAt,
  });

  Expense copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    DateTime? date,
    String? notes,
    String? receiptImagePath,
    DateTime? createdAt,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ExpenseAdapter extends TypeAdapter<Expense> {
  @override
  final int typeId = 0;

  @override
  Expense read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numFields; i++) reader.readByte(): reader.read(),
    };
    return Expense(
      id: fields[0] as String,
      title: fields[1] as String,
      amount: fields[2] as double,
      category: fields[3] as String,
      date: fields[4] as DateTime,
      notes: fields[5] as String?,
      receiptImagePath: fields[6] as String?,
      createdAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Expense obj) {
    writer.writeByte(8);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.title);
    writer.writeByte(2);
    writer.write(obj.amount);
    writer.writeByte(3);
    writer.write(obj.category);
    writer.writeByte(4);
    writer.write(obj.date);
    writer.writeByte(5);
    writer.write(obj.notes);
    writer.writeByte(6);
    writer.write(obj.receiptImagePath);
    writer.writeByte(7);
    writer.write(obj.createdAt);
  }
}
