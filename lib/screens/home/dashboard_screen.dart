import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/currency_provider.dart';
import '../../models/transaction_model.dart';
import '../../routes/app_routes.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';
import '../profile/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Use a longer delay to be absolutely sure we're out of the build phase
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _loadData();
      }
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    try {
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      
      // Load categories first, then transactions
      await categoryProvider.loadCategories(refresh: true);
      
      // Add a small delay between operations
      await Future.delayed(const Duration(milliseconds: 50));
      
      if (mounted) {
        await transactionProvider.loadTransactions(refresh: true);
      }
    } catch (e) {
      // Silently handle any errors during initial load
      print('Dashboard load error: $e');
    }
  }

  static String formatAmount(double amount) {
    final formatter = NumberFormat('#,###');
    return formatter.format(amount.round());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          _DashboardTab(),
          _TransactionsTab(),
          _CategoriesTab(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: Colors.grey[500],
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt_outlined),
              activeIcon: Icon(Icons.list_alt),
              label: 'Transactions',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.category_outlined),
              activeIcon: Icon(Icons.category),
              label: 'Categories',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
      floatingActionButton: _selectedIndex == 0 || _selectedIndex == 1
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: () async {
                  final result = await AppRoutes.navigateToAddTransaction(context);
                  if (result == true && mounted) {
                    // Refresh transaction data after successful creation
                    try {
                      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
                      await Future.delayed(const Duration(milliseconds: 100));
                      if (mounted) {
                        transactionProvider.loadTransactions();
                      }
                    } catch (e) {
                      // Provider might be disposed, ignore error
                    }
                  }
                },
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.add, size: 28),
              ),
            )
          : null,
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.center,
          colors: [
            AppTheme.primaryColor.withOpacity(0.05),
            Colors.white,
          ],
        ),
      ),
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
            final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
            await Future.wait([
              categoryProvider.loadCategories(refresh: true),
              transactionProvider.loadTransactions(refresh: true),
            ]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      final user = authProvider.user;
                      final greeting = _getGreeting();
                      
                      return Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  greeting,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user?.displayName ?? 'User',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 28,
                              backgroundColor: AppTheme.primaryColor,
                              child: Text(
                                (user?.displayName ?? 'U').substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                
                // Balance Card Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Consumer<TransactionProvider>(
                    builder: (context, transactionProvider, child) {
                      final balance = transactionProvider.balance;
                      final totalIncome = transactionProvider.totalIncome;
                      final totalExpenses = transactionProvider.totalExpenses;
                      
                      return Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF4CAF50),
                              Color(0xFF66BB6A),
                              Color(0xFF81C784),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Background pattern
                            Positioned(
                              right: -50,
                              top: -50,
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.1),
                                ),
                              ),
                            ),
                            Positioned(
                              right: -20,
                              bottom: -20,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.05),
                                ),
                              ),
                            ),
                            
                            // Content
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.account_balance_wallet,
                                        color: Colors.white.withOpacity(0.9),
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Total Balance',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: Colors.white.withOpacity(0.9),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Consumer2<AuthProvider, CurrencyProvider>(
                                    builder: (context, authProvider, currencyProvider, child) {
                                      return Text(
                                        '${authProvider.getCurrencySymbol(currencyProvider)}${_DashboardScreenState.formatAmount(balance)}',
                                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 36,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                                                     Row(
                                     children: [
                                       Expanded(
                                         child: _buildBalanceItem(
                                           context,
                                           'Income',
                                           totalIncome,
                                           Icons.arrow_upward,
                                           Colors.white,
                                           true, // isIncome
                                         ),
                                       ),
                                       const SizedBox(width: 16),
                                       Expanded(
                                         child: _buildBalanceItem(
                                           context,
                                           'Expenses',
                                           totalExpenses,
                                           Icons.arrow_downward,
                                           Colors.white,
                                           false, // isIncome
                                         ),
                                       ),
                                     ],
                                   ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Quick Actions Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Actions',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickAction(
                              context,
                              'Add Income',
                              Icons.add_circle_outline,
                              const Color(0xFF4CAF50),
                              const Color(0xFFE8F5E8),
                              () async {
                                final result = await AppRoutes.navigateToAddTransaction(context, type: 'income');
                                if (result == true && context.mounted) {
                                  try {
                                    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
                                    await Future.delayed(const Duration(milliseconds: 100));
                                    if (context.mounted) {
                                      transactionProvider.loadTransactions();
                                    }
                                  } catch (e) {
                                    // Provider might be disposed, ignore error
                                  }
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildQuickAction(
                              context,
                              'Add Expense',
                              Icons.remove_circle_outline,
                              const Color(0xFFF44336),
                              const Color(0xFFFFEBEE),
                              () async {
                                final result = await AppRoutes.navigateToAddTransaction(context, type: 'expense');
                                if (result == true && context.mounted) {
                                  try {
                                    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
                                    await Future.delayed(const Duration(milliseconds: 100));
                                    if (context.mounted) {
                                      transactionProvider.loadTransactions();
                                    }
                                  } catch (e) {
                                    // Provider might be disposed, ignore error
                                  }
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Recent Transactions Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Transactions',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {}, // Will navigate to transactions tab
                            icon: const Icon(Icons.arrow_forward, size: 16),
                            label: const Text('See All'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                              textStyle: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Consumer<TransactionProvider>(
                        builder: (context, transactionProvider, child) {
                          final recentTransactions = transactionProvider.recentTransactions;
                          
                          if (transactionProvider.isLoading && recentTransactions.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          
                          if (recentTransactions.isEmpty) {
                            return _buildEmptyState(context);
                          }
                          
                          return Column(
                            children: recentTransactions.take(5).map((transaction) {
                              return _buildTransactionCard(context, transaction);
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 100), // Bottom padding for FAB
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  Widget _buildBalanceItem(
    BuildContext context,
    String title,
    double amount,
    IconData icon,
    Color color,
    bool isIncome,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isIncome 
                      ? const Color(0xFF4CAF50).withOpacity(0.1)
                      : const Color(0xFFF44336).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon, 
                  color: isIncome 
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFF44336),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Consumer2<AuthProvider, CurrencyProvider>(
            builder: (context, authProvider, currencyProvider, child) {
              return Text(
                '${authProvider.getCurrencySymbol(currencyProvider)}${_DashboardScreenState.formatAmount(amount)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[800],
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context,
    String title,
    IconData icon,
    Color primaryColor,
    Color backgroundColor,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: primaryColor.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: primaryColor, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start tracking your expenses by adding your first transaction',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, TransactionModel transaction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Navigate to transaction details
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
                             children: [
                 // Transaction type indicator
                 Container(
                   width: 52,
                   height: 52,
                   decoration: BoxDecoration(
                     color: transaction.isExpense 
                         ? const Color(0xFFFFEBEE)
                         : const Color(0xFFE8F5E8),
                     borderRadius: BorderRadius.circular(16),
                     border: Border.all(
                       color: transaction.isExpense 
                           ? const Color(0xFFF44336).withOpacity(0.2)
                           : const Color(0xFF4CAF50).withOpacity(0.2),
                       width: 1,
                     ),
                   ),
                   child: Icon(
                     transaction.isExpense 
                         ? Icons.trending_down
                         : Icons.trending_up,
                     color: transaction.isExpense 
                         ? const Color(0xFFF44336)
                         : const Color(0xFF4CAF50),
                     size: 26,
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
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        transaction.category,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Amount
                Consumer2<AuthProvider, CurrencyProvider>(
                  builder: (context, authProvider, currencyProvider, child) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${transaction.isExpense ? '-' : '+'}${authProvider.getCurrencySymbol(currencyProvider)}${_DashboardScreenState.formatAmount(transaction.amount)}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: transaction.isExpense 
                                ? const Color(0xFFF44336)
                                : const Color(0xFF4CAF50),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDate(transaction.date),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date).inDays;
      
      if (difference == 0) {
        return 'Today';
      } else if (difference == 1) {
        return 'Yesterday';
      } else if (difference < 7) {
        return '${difference}d ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateString;
    }
  }
}

class _TransactionsTab extends StatefulWidget {
  const _TransactionsTab();

  @override
  State<_TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends State<_TransactionsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all'; // all, income, expense
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

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
      }
    });
  }

  List<TransactionModel> _getFilteredTransactions(List<TransactionModel> transactions) {
    List<TransactionModel> filtered = transactions;
    
    // Apply type filter
    if (_selectedFilter == 'income') {
      filtered = filtered.where((t) => t.isIncome).toList();
    } else if (_selectedFilter == 'expense') {
      filtered = filtered.where((t) => t.isExpense).toList();
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
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header with filters and search
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Title and search toggle
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Transactions',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _toggleSearch,
                      icon: Icon(
                        _isSearching ? Icons.close : Icons.search,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                
                // Search field
                if (_isSearching) ...[
                  const SizedBox(height: 16),
                  TextField(
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
                ],
                
                const SizedBox(height: 16),
                
                // Filter chips
                Row(
                  children: [
                    _buildFilterChip('all', 'All'),
                    const SizedBox(width: 8),
                    _buildFilterChip('income', 'Income'),
                    const SizedBox(width: 8),
                    _buildFilterChip('expense', 'Expenses'),
                  ],
                ),
              ],
            ),
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
                
                final filteredTransactions = _getFilteredTransactions(transactionProvider.transactions);
                
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
                                _searchController.text.isNotEmpty
                                    ? 'No transactions found'
                                    : 'No transactions yet',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _searchController.text.isNotEmpty
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
          color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
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
          // Navigate to transaction details or edit
          AppRoutes.navigateToEditTransaction(context, transaction);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Transaction type icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: transaction.isExpense 
                          ? AppTheme.errorColor.withOpacity(0.1)
                          : AppTheme.successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: transaction.isExpense 
                            ? AppTheme.errorColor.withOpacity(0.2)
                            : AppTheme.successColor.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      transaction.isExpense 
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      color: transaction.isExpense 
                          ? AppTheme.errorColor 
                          : AppTheme.successColor,
                      size: 22,
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
                  Consumer2<AuthProvider, CurrencyProvider>(
                    builder: (context, authProvider, currencyProvider, child) {
                      return Text(
                        '${transaction.isExpense ? '-' : '+'}${authProvider.getCurrencySymbol(currencyProvider)}${_DashboardScreenState.formatAmount(transaction.amount)}',
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

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date).inDays;
      
      if (difference == 0) {
        return 'Today';
      } else if (difference == 1) {
        return 'Yesterday';
      } else if (difference < 7) {
        return '${difference}d ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateString;
    }
  }
}

class _CategoriesTab extends StatefulWidget {
  const _CategoriesTab();

  @override
  State<_CategoriesTab> createState() => _CategoriesTabState();
}

class _CategoriesTabState extends State<_CategoriesTab> {
  String _selectedType = 'all'; // all, income, expense

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    if (!mounted) return;
    try {
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      if (mounted) {
        await categoryProvider.loadCategories(refresh: true);
      }
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  Future<void> _onRefresh() async {
    await _loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.center,
          colors: [
            AppTheme.primaryColor.withOpacity(0.05),
            Colors.white,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Categories',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () {
                            // TODO: Navigate to add category
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Add Category - Coming Soon')),
                            );
                          },
                          icon: const Icon(Icons.add, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Filter chips
                  Row(
                    children: [
                      _buildFilterChip('all', 'All'),
                      const SizedBox(width: 8),
                      _buildFilterChip('income', 'Income'),
                      const SizedBox(width: 8),
                      _buildFilterChip('expense', 'Expense'),
                    ],
                  ),
                ],
              ),
            ),
            
            // Categories list
            Expanded(
              child: Consumer<CategoryProvider>(
                builder: (context, categoryProvider, child) {
                  if (categoryProvider.isLoading && categoryProvider.categories.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  
                  if (categoryProvider.error != null) {
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
                            'Error loading categories',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            categoryProvider.error!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadCategories,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  final filteredCategories = _getFilteredCategories(categoryProvider.categories);
                  
                  if (filteredCategories.isEmpty) {
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
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.category_outlined,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No categories found',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Categories help organize your transactions',
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
                      itemCount: filteredCategories.length,
                      itemBuilder: (context, index) {
                        final category = filteredCategories[index];
                        return _buildCategoryCard(category);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedType == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  List<dynamic> _getFilteredCategories(List<dynamic> categories) {
    if (_selectedType == 'all') {
      return categories;
    }
    
    return categories.where((category) {
      // Assuming categories have a type field or can be determined
      // You might need to adjust this based on your category model
      if (_selectedType == 'income') {
        return category.type == 'income' || category.name?.toLowerCase().contains('salary') == true || 
               category.name?.toLowerCase().contains('income') == true;
      } else if (_selectedType == 'expense') {
        return category.type == 'expense' || category.name?.toLowerCase().contains('expense') == true ||
               !category.name?.toLowerCase().contains('salary') == true;
      }
      return true;
    }).toList();
  }

  Widget _buildCategoryCard(dynamic category) {
    // Extract category info - adjust based on your category model
    final categoryName = category.name ?? category.toString();
    final categoryIcon = _getCategoryIcon(categoryName);
    final categoryColor = _getCategoryColor(categoryName);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // TODO: Navigate to category details or edit
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Selected: $categoryName')),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Category icon
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: categoryColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    categoryIcon,
                    color: categoryColor,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Category details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap to view transactions',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Arrow icon
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('food') || name.contains('restaurant')) return Icons.restaurant;
    if (name.contains('transport') || name.contains('car')) return Icons.directions_car;
    if (name.contains('health') || name.contains('medical')) return Icons.local_hospital;
    if (name.contains('shopping') || name.contains('clothes')) return Icons.shopping_bag;
    if (name.contains('entertainment') || name.contains('movie')) return Icons.movie;
    if (name.contains('salary') || name.contains('income')) return Icons.attach_money;
    if (name.contains('bills') || name.contains('utility')) return Icons.receipt_long;
    if (name.contains('education') || name.contains('school')) return Icons.school;
    if (name.contains('travel') || name.contains('vacation')) return Icons.flight;
    if (name.contains('home') || name.contains('house')) return Icons.home;
    return Icons.category; // default icon
  }

  Color _getCategoryColor(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('food')) return const Color(0xFFFF9800); // Orange
    if (name.contains('transport')) return const Color(0xFF2196F3); // Blue
    if (name.contains('health')) return const Color(0xFFE91E63); // Pink
    if (name.contains('shopping')) return const Color(0xFF9C27B0); // Purple
    if (name.contains('entertainment')) return const Color(0xFFFF5722); // Deep Orange
    if (name.contains('salary') || name.contains('income')) return const Color(0xFF4CAF50); // Green
    if (name.contains('bills')) return const Color(0xFFF44336); // Red
    if (name.contains('education')) return const Color(0xFF3F51B5); // Indigo
    if (name.contains('travel')) return const Color(0xFF00BCD4); // Cyan
    if (name.contains('home')) return const Color(0xFF795548); // Brown
    return AppTheme.primaryColor; // default color
  }
}