import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:expense_tracker/bloc/expense_bloc.dart';
import 'package:expense_tracker/bloc/expense_event.dart';
import 'package:expense_tracker/config/constants.dart';

Future<File?> pickImageFromSource(ImageSource source) async {
  final picker = ImagePicker();
  final image = await picker.pickImage(source: source, maxWidth: 1024);
  if (image != null) {
    return File(image.path);
  }
  return null;
}

void showImageSourceDialog(
  BuildContext context, {
  required VoidCallback onCameraTap,
  required VoidCallback onGalleryTap,
}) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Scan Receipt',
              style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ImageSourceButton(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () {
                    Navigator.pop(ctx);
                    onCameraTap();
                  },
                ),
                ImageSourceButton(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () {
                    Navigator.pop(ctx);
                    onGalleryTap();
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    ),
  );
}

Future<DateTime?> pickDate(BuildContext context, DateTime initialDate) async {
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: DateTime(2020),
    lastDate: DateTime.now(),
    builder: (context, child) => Theme(
      data: Theme.of(context).copyWith(
        datePickerTheme: DatePickerThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      child: child!,
    ),
  );
}

void submitExpense(
  BuildContext context, {
  required String title,
  required double amount,
  required DateTime date,
  required String category,
  String? notes,
  String? receiptImagePath,
  String? existingId,
}) {
  final bloc = context.read<ExpenseBloc>();

  if (existingId != null) {
    bloc.add(UpdateExpense(
      id: existingId,
      title: title,
      amount: amount,
      category: category,
      date: date,
      notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
      receiptImagePath: receiptImagePath,
    ));
  } else {
    bloc.add(AddExpense(
      title: title,
      amount: amount,
      category: category,
      date: date,
      notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
      receiptImagePath: receiptImagePath,
    ));
  }

  Navigator.pop(context);
}

class ScanResultData {
  final String? title;
  final String? amount;
  final DateTime? date;
  final String? category;

  ScanResultData({
    this.title,
    this.amount,
    this.date,
    this.category,
  });
}

ScanResultData processScanResult(Map<String, dynamic> result) {
  String? title;
  if (result['merchant_name'] != null) {
    title = result['merchant_name'] as String;
  }

  String? amount;
  if (result['amount'] != null) {
    amount = (result['amount'] as num).toStringAsFixed(0);
  }

  DateTime? date;
  if (result['date'] != null) {
    date = DateTime.tryParse(result['date'] as String);
  }

  String? category;
  if (result['category'] != null &&
      AppConstants.categories.contains(result['category'])) {
    category = result['category'] as String;
  }

  return ScanResultData(
    title: title,
    amount: amount,
    date: date,
    category: category,
  );
}

class ImageSourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const ImageSourceButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 36, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
