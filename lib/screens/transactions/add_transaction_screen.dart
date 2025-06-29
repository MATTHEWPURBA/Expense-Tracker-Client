import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/transaction_model.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/currency_provider.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../services/api_service.dart';

class AddTransactionScreen extends StatefulWidget {
  final String? initialType;

  const AddTransactionScreen({super.key, this.initialType});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();

  String _selectedType = AppConstants.expenseType;
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.initialType != null) {
      _selectedType = widget.initialType!;
    }
    _dateController.text = DateFormat(AppConstants.displayDateFormat).format(_selectedDate);
    
    // Ensure categories are loaded when screen opens - use delay to be safe
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
        if (categoryProvider.categories.isEmpty) {
          categoryProvider.loadCategories();
        }
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat(AppConstants.displayDateFormat).format(picked);
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Store transaction details
    final transactionTitle = _titleController.text.trim();
    final transactionAmount = double.parse(_amountController.text);
    
    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Creating transaction...'),
              ],
            ),
          );
        },
      );
    }
    
    bool success = false;
    String? errorMessage;
    
    try {
      // Call API directly instead of using provider to avoid disposal issues
      final apiService = ApiService();
      
      final transactionData = {
        'title': transactionTitle,
        'description': _descriptionController.text.trim(),
        'amount': transactionAmount,
        'type': _selectedType,
        'category': _selectedCategory!,
        'date': DateFormat(AppConstants.apiDateFormat).format(_selectedDate),
      };

      // Direct API call - this will throw HttpException if it fails
      await apiService.createTransaction(transactionData);
      success = true;
      
    } catch (e) {
      success = false;
      errorMessage = e.toString();
      if (e.toString().contains('HttpException')) {
        errorMessage = e.toString().replaceAll('HttpException: ', '');
      }
    }

    // Close loading dialog
    if (mounted) {
      Navigator.of(context).pop();
    }

    if (mounted) {
      if (success) {
        // Show celebratory success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.successColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Success!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.successColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Transaction "$transactionTitle" has been added successfully!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Consumer2<AuthProvider, CurrencyProvider>(
                    builder: (context, authProvider, currencyProvider, child) {
                      return Text(
                        'Amount: ${authProvider.getCurrencySymbol(currencyProvider)}${transactionAmount.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.pop(context, true); // Go back to dashboard
                  },
                  child: const Text('Continue'),
                ),
              ],
            );
          },
        );
        
        // Show success notification as well
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Transaction "$transactionTitle" (${context.read<AuthProvider>().getCurrencySymbol(context.read<CurrencyProvider>())}${transactionAmount.toStringAsFixed(2)}) added successfully!'),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'VIEW',
              textColor: Colors.white,
              onPressed: () {
                // Navigate to transactions list or dashboard
                Navigator.pop(context);
              },
            ),
          ),
        );
        
        // Wait a bit for user to see the notification
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Note: Navigation is now handled by the dialog
      } else {
        // Show error notification
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to create transaction: ${errorMessage ?? "Unknown error"}'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: () => _handleSubmit(),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppTheme.primaryColor,
                        child: const Icon(
                          Icons.add_circle_outline,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Create New Transaction',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add your income or expense details',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Transaction Type Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transaction Type',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedType = AppConstants.incomeType;
                                  _selectedCategory = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: _selectedType == AppConstants.incomeType
                                      ? AppTheme.successColor.withOpacity(0.1)
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _selectedType == AppConstants.incomeType
                                        ? AppTheme.successColor
                                        : Colors.grey[300]!,
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.trending_up,
                                      color: _selectedType == AppConstants.incomeType
                                          ? AppTheme.successColor
                                          : Colors.grey[600],
                                      size: 30,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Income',
                                      style: TextStyle(
                                        color: _selectedType == AppConstants.incomeType
                                            ? AppTheme.successColor
                                            : Colors.grey[600],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedType = AppConstants.expenseType;
                                  _selectedCategory = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: _selectedType == AppConstants.expenseType
                                      ? AppTheme.errorColor.withOpacity(0.1)
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _selectedType == AppConstants.expenseType
                                        ? AppTheme.errorColor
                                        : Colors.grey[300]!,
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.trending_down,
                                      color: _selectedType == AppConstants.expenseType
                                          ? AppTheme.errorColor
                                          : Colors.grey[600],
                                      size: 30,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Expense',
                                      style: TextStyle(
                                        color: _selectedType == AppConstants.expenseType
                                            ? AppTheme.errorColor
                                            : Colors.grey[600],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Title Field
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Title',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          hintText: 'Enter transaction title',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Description Field
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Description',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Enter description (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Amount Field
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Amount',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _selectedType == AppConstants.incomeType 
                              ? AppTheme.successColor 
                              : AppTheme.errorColor,
                        ),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          border: const OutlineInputBorder(),
                          prefixText: '${context.watch<AuthProvider>().getCurrencySymbol(context.watch<CurrencyProvider>())} ',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an amount';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          if (double.parse(value) <= 0) {
                            return 'Amount must be greater than 0';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Date Field
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _dateController,
                        readOnly: true,
                        onTap: _selectDate,
                        decoration: const InputDecoration(
                          hintText: 'Select date',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Category Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Category',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Consumer<CategoryProvider>(
                        builder: (context, categoryProvider, child) {
                          final categories = categoryProvider.getCategoriesByType(_selectedType);
                          
                          return DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: const InputDecoration(
                              hintText: 'Select a category',
                              border: OutlineInputBorder(),
                            ),
                            items: categories.map((category) {
                              return DropdownMenuItem<String>(
                                value: category.name,
                                child: Row(
                                  children: [
                                    Text(category.icon ?? '📋', style: const TextStyle(fontSize: 20)),
                                    const SizedBox(width: 12),
                                    Text(category.name),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value;
                              });
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Submit Button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedType == AppConstants.incomeType 
                        ? AppTheme.successColor
                        : AppTheme.errorColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _selectedType == AppConstants.incomeType 
                            ? Icons.add_circle 
                            : Icons.remove_circle,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Add ${_selectedType == AppConstants.incomeType ? 'Income' : 'Expense'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Color _parseColor(String? colorString) {
    if (colorString == null || colorString.isEmpty) {
      return AppTheme.primaryColor;
    }
    try {
      final cleanColor = colorString.replaceAll('#', '');
      return Color(int.parse('0xFF$cleanColor'));
    } catch (e) {
      return AppTheme.primaryColor;
    }
  }
}

 