import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/bloc/expense_bloc.dart';
import 'package:expense_tracker/bloc/expense_event.dart';

void confirmClearData(BuildContext context) {
  final theme = Theme.of(context);

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: theme.colorScheme.error, size: 24),
          const SizedBox(width: 8),
          const Text('Clear All Data'),
        ],
      ),
      content: Text(
        'This will permanently delete all your expenses across all months. '
        'This action cannot be undone. Are you sure you want to continue?',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(ctx);
            context.read<ExpenseBloc>().add(ClearAllData());
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Delete Everything'),
        ),
      ],
    ),
  );
}
