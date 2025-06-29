import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/transaction_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/transaction_model.dart';
import '../../routes/app_routes.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all'; // all, income, expense
  String _selectedCategory = 'all';
  String _sortBy = 'date_desc'; // date_desc, date_asc, amount_desc, amount_asc
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    if (!mounted) return;
    try {
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      
      // Load categories first if needed
      if (categoryProvider.categories.isEmpty) {
        await categoryProvider.loadCategories();
      }
      
      if (mounted) {
        await transactionProvider.loadTransactions(refresh: true);
      }
    } catch (e) {
      print('Error loading transactions: $e');
    }
  }

  Future<void> _onRefresh() async {
    await _loadTransactions();
  }

  List<TransactionModel> _getFilteredAndSortedTransactions(List<TransactionModel> transactions) {
    List<TransactionModel> filtered = transactions;
    
    // Apply type filter
    if (_selectedFilter == 'income') {
      filtered = filtered.where((t) => t.isIncome).toList();
    } else if (_selectedFilter == 'expense') {
      filtered = filtered.where((t) => t.isExpense).toList();
    }
    
    // Apply category filter
    if (_selectedCategory != 'all') {
      filtered = filtered.where((t) => t.category == _selectedCategory).toList();
    }
    
    // Apply search filter
    final searchTerm = _searchController.text.toLowerCase();
    if (searchTerm.isNotEmpty) {
      filtered = filtered.where((t) => 
        t.title.toLowerCase().contains(searchTerm) ||
        t.description.toLowerCase().contains(searchTerm) ||
        t.category.toLowerCase().contains(searchTerm)
      ).toList();
    }
    
    // Apply sorting
    switch (_sortBy) {
      case 'date_desc':
        filtered.sort((a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));
        break;
      case 'date_asc':
        filtered.sort((a, b) => DateTime.parse(a.date).compareTo(DateTime.parse(b.date)));
        break;
      case 'amount_desc':
        filtered.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'amount_asc':
        filtered.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }
    
    return filtered;
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildFilterBottomSheet(),
    );
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildSortBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                }
              });
            },
            icon: Icon(_isSearching ? Icons.close : Icons.search),
          ),
          IconButton(
            onPressed: _showFilterBottomSheet,
            icon: const Icon(Icons.filter_list),
          ),
          IconButton(
            onPressed: _showSortBottomSheet,
            icon: const Icon(Icons.sort),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          if (_isSearching)
            Container(
              padding: const EdgeInsets.all(16),
              color: AppTheme.primaryColor,
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search transactions...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),

          // Filter chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'All'),
                  const SizedBox(width: 8),
                  _buildFilterChip('income', 'Income'),
                  const SizedBox(width: 8),
                  _buildFilterChip('expense', 'Expenses'),
                  if (_selectedCategory != 'all') ...[
                    const SizedBox(width: 8),
                    _buildCategoryChip(_selectedCategory),
                  ],
                ],
              ),
            ),
          ),

          // Summary stats
          Consumer<TransactionProvider>(
            builder: (context, transactionProvider, child) {
              final filteredTransactions = _getFilteredAndSortedTransactions(transactionProvider.transactions);
              final totalIncome = filteredTransactions.where((t) => t.isIncome).fold(0.0, (sum, t) => sum + t.amount);
              final totalExpenses = filteredTransactions.where((t) => t.isExpense).fold(0.0, (sum, t) => sum + t.amount);
              
              return Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Income',
                        totalIncome,
                        AppTheme.successColor,
                        Icons.arrow_upward,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        'Expenses',
                        totalExpenses,
                        AppTheme.errorColor,
                        Icons.arrow_downward,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Transaction list
          Expanded(
            child: Consumer<TransactionProvider>(
              builder: (context, transactionProvider, child) {
                if (transactionProvider.isLoading && transactionProvider.transactions.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                
                if (transactionProvider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading transactions',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          transactionProvider.error!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadTransactions,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                
                final filteredTransactions = _getFilteredAndSortedTransactions(transactionProvider.transactions);
                
                if (filteredTransactions.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchController.text.isNotEmpty || _selectedFilter != 'all' || _selectedCategory != 'all'
                                    ? 'No transactions found'
                                    : 'No transactions yet',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _searchController.text.isNotEmpty || _selectedFilter != 'all' || _selectedCategory != 'all'
                                    ? 'Try adjusting your search or filters'
                                    : 'Add your first transaction to get started',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }
                
                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = filteredTransactions[index];
                      return _buildTransactionCard(transaction);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await AppRoutes.navigateToAddTransaction(context);
          if (result == true && mounted) {
            _loadTransactions();
          }
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = 'all';
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primaryColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              category,
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.close,
              size: 16,
              color: AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return Text(
                      '${authProvider.currencySymbol}${amount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(TransactionModel transaction) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          AppRoutes.navigateToEditTransaction(context, transaction);
        },
        onLongPress: () {
          _showTransactionOptions(transaction);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Transaction type icon
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: transaction.isExpense 
                        ? AppTheme.errorColor.withOpacity(0.1)
                        : AppTheme.successColor.withOpacity(0.1),
                    child: Icon(
                      transaction.isExpense ? Icons.remove : Icons.add,
                      color: transaction.isExpense 
                          ? AppTheme.errorColor 
                          : AppTheme.successColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Transaction details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (transaction.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            transaction.description,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Amount
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      return Text(
                        '${transaction.isExpense ? '-' : '+'}${authProvider.currencySymbol}${transaction.amount.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: transaction.isExpense 
                              ? AppTheme.errorColor 
                              : AppTheme.successColor,
                        ),
                      );
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Category and date
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      transaction.category,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(transaction.date),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBottomSheet() {
    return StatefulBuilder(
      builder: (context, setSheetState) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter Transactions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              
              Text(
                'Type',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _selectedFilter == 'all',
                    onSelected: (selected) {
                      setSheetState(() {
                        _selectedFilter = 'all';
                      });
                    },
                  ),
                  FilterChip(
                    label: const Text('Income'),
                    selected: _selectedFilter == 'income',
                    onSelected: (selected) {
                      setSheetState(() {
                        _selectedFilter = 'income';
                      });
                    },
                  ),
                  FilterChip(
                    label: const Text('Expenses'),
                    selected: _selectedFilter == 'expense',
                    onSelected: (selected) {
                      setSheetState(() {
                        _selectedFilter = 'expense';
                      });
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              Text(
                'Category',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Consumer<TransactionProvider>(
                builder: (context, transactionProvider, child) {
                  final categories = transactionProvider.transactions
                      .map((t) => t.category)
                      .toSet()
                      .toList();
                  categories.sort();
                  
                  return Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('All Categories'),
                        selected: _selectedCategory == 'all',
                        onSelected: (selected) {
                          setSheetState(() {
                            _selectedCategory = 'all';
                          });
                        },
                      ),
                      ...categories.map((category) => FilterChip(
                        label: Text(category),
                        selected: _selectedCategory == category,
                        onSelected: (selected) {
                          setSheetState(() {
                            _selectedCategory = selected ? category : 'all';
                          });
                        },
                      )),
                    ],
                  );
                },
              ),
              
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setSheetState(() {
                          _selectedFilter = 'all';
                          _selectedCategory = 'all';
                        });
                      },
                      child: const Text('Clear Filters'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          // Apply filters
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortBottomSheet() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sort Transactions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          _buildSortOption('date_desc', 'Date (Newest First)', Icons.calendar_today),
          _buildSortOption('date_asc', 'Date (Oldest First)', Icons.calendar_today),
          _buildSortOption('amount_desc', 'Amount (Highest First)', Icons.attach_money),
          _buildSortOption('amount_asc', 'Amount (Lowest First)', Icons.attach_money),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSortOption(String value, String label, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: _sortBy == value ? Icon(Icons.check, color: AppTheme.primaryColor) : null,
      onTap: () {
        setState(() {
          _sortBy = value;
        });
        Navigator.pop(context);
      },
    );
  }

  void _showTransactionOptions(TransactionModel transaction) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Transaction'),
            onTap: () {
              Navigator.pop(context);
              AppRoutes.navigateToEditTransaction(context, transaction);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete Transaction', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmation(transaction);
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(TransactionModel transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text('Are you sure you want to delete "${transaction.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (transaction.id != null) {
                final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
                final success = await transactionProvider.deleteTransaction(transaction.id!);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Transaction deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to delete transaction'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }
} 