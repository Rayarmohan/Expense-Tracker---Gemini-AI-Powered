import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/bloc/expense_bloc.dart';
import 'package:expense_tracker/config/constants.dart';
import 'package:expense_tracker/models/expense.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? expense;
  final bool autoScan;

  const AddExpenseScreen({super.key, this.expense, this.autoScan = false});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = AppConstants.categories.first;
  String? _receiptImagePath;
  File? _pendingImageFile;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  bool get isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _slideController.forward();

    if (isEditing) {
      final e = widget.expense!;
      _titleController.text = e.title;
      _amountController.text = e.amount.toStringAsFixed(0);
      _selectedDate = e.date;
      _selectedCategory = e.category;
      _notesController.text = e.notes ?? '';
      _receiptImagePath = e.receiptImagePath;
    } else {
      final state = context.read<ExpenseBloc>().state;
      if (state is ExpenseLoaded && state.scanResult != null) {
        _applyScanResult(state.scanResult!);
      }
      if (widget.autoScan) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _pickImage(ImageSource.camera));
      }
    }
  }

  void _applyScanResult(Map<String, dynamic> result) {
    debugPrint('========== APPLYING SCAN RESULT ==========');
    debugPrint('Result: $result');
    if (result['merchant_name'] != null) {
      _titleController.text = result['merchant_name'] as String;
      debugPrint('Set title: ${result['merchant_name']}');
    }
    if (result['amount'] != null) {
      _amountController.text = (result['amount'] as num).toStringAsFixed(0);
      debugPrint('Set amount: ${result['amount']}');
    }
    if (result['date'] != null) {
      _selectedDate = DateTime.tryParse(result['date'] as String) ?? DateTime.now();
      debugPrint('Set date: $_selectedDate (from ${result['date']})');
    }
    if (result['category'] != null &&
        AppConstants.categories.contains(result['category'])) {
      _selectedCategory = result['category'] as String;
      debugPrint('Set category: ${result['category']}');
    }
    if (mounted) setState(() {});
    debugPrint('=========================================');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source, maxWidth: 1024);
    if (image != null) {
      setState(() {
        _pendingImageFile = File(image.path);
        _receiptImagePath = image.path;
      });
      if (!isEditing && mounted) {
        context.read<ExpenseBloc>().add(ScanReceipt(imageFile: File(image.path)));
      }
    }
  }

  void _showImageSourceDialog() {
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
                  _ImageSourceButton(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  _ImageSourceButton(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.gallery);
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

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
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
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final bloc = context.read<ExpenseBloc>();
    final title = _titleController.text.trim();
    final amount = double.parse(_amountController.text.trim());

    if (isEditing) {
      bloc.add(UpdateExpense(
        id: widget.expense!.id,
        title: title,
        amount: amount,
        category: _selectedCategory,
        date: _selectedDate,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        receiptImagePath: _receiptImagePath,
      ));
    } else {
      bloc.add(AddExpense(
        title: title,
        amount: amount,
        category: _selectedCategory,
        date: _selectedDate,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        receiptImagePath: _receiptImagePath,
      ));
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Expense' : 'Add Expense'),
        actions: [
          TextButton(
            onPressed: _submit,
            child: const Text('Save'),
          ),
        ],
      ),
      body: BlocListener<ExpenseBloc, ExpenseState>(
        listenWhen: (previous, current) =>
            current is ExpenseLoaded &&
            current.scanResult != null &&
            !current.isScanning,
        listener: (context, state) {
          if (state is ExpenseLoaded && !isEditing) {
            debugPrint('BlocListener: new scan result received');
            _applyScanResult(state.scanResult!);
          }
        },
        child: BlocBuilder<ExpenseBloc, ExpenseState>(
        builder: (context, state) {
          final isScanning = state is ExpenseLoaded && state.isScanning;
          final scanResult = state is ExpenseLoaded ? state.scanResult : null;
          final scanError = scanResult != null && scanResult['error'] != null;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SlideTransition(
                position: _slideAnimation,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!isEditing) ...[
                        GestureDetector(
                          onTap: _showImageSourceDialog,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 160,
                            decoration: BoxDecoration(
                              color: _pendingImageFile != null
                                  ? null
                                  : theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant,
                                width: 1.5,
                                strokeAlign: BorderSide.strokeAlignInside,
                              ),
                              image: _pendingImageFile != null
                                  ? DecorationImage(
                                      image: FileImage(_pendingImageFile!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _pendingImageFile == null
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.document_scanner_outlined,
                                        size: 40,
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Tap to scan receipt',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  )
                                : isScanning
                                    ? Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(16),
                                          color: Colors.black38,
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 28,
                                              height: 28,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: theme.colorScheme.onPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Scanning receipt...',
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : null,
                          ),
                        ),
                        if (scanError) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber, size: 18, color: theme.colorScheme.error),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    scanResult['error'] as String,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onErrorContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                      ],
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Merchant / Title',
                          prefixIcon: Icon(Icons.store),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _amountController,
                        decoration: const InputDecoration(
                          labelText: 'Amount (₹)',
                          prefixIcon: Icon(Icons.currency_rupee),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          final amount = double.tryParse(v.trim());
                          if (amount == null || amount <= 0) {
                            return 'Enter a valid amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _selectDate,
                        child: AbsorbPointer(
                          child: TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Date',
                              prefixIcon: const Icon(Icons.calendar_today),
                              hintText: DateFormat('MMM dd, yyyy')
                                  .format(_selectedDate),
                            ),
                            controller: TextEditingController(
                              text: DateFormat('MMM dd, yyyy').format(_selectedDate),
                            ),
                            validator: (_) => null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: AppConstants.categories.map((cat) {
                          return DropdownMenuItem(
                            value: cat,
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Color(
                                      AppConstants.categoryColors[cat]!,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(cat),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedCategory = v);
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes (optional)',
                          prefixIcon: Icon(Icons.notes),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _submit,
                        child: Text(isEditing ? 'Update Expense' : 'Add Expense'),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      ),
    );
  }
}

class _ImageSourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ImageSourceButton({
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
