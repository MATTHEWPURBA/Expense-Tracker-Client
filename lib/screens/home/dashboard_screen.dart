import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          _DashboardTab(),
          _TransactionsTab(),
          _CategoriesTab(),
          _ProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Categories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0 || _selectedIndex == 1
          ? FloatingActionButton(
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
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final user = authProvider.user;
                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, ${user?.displayName ?? 'User'}!',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Welcome back',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppTheme.primaryColor,
                      child: Text(
                        (user?.displayName ?? 'U').substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Balance Card
            Consumer<TransactionProvider>(
              builder: (context, transactionProvider, child) {
                final balance = transactionProvider.balance;
                final totalIncome = transactionProvider.totalIncome;
                final totalExpenses = transactionProvider.totalExpenses;
                
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.primaryLightColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Balance',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          return Text(
                            '${authProvider.currencySymbol}${balance.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildBalanceItem(
                              context,
                              'Income',
                              totalIncome,
                              Icons.arrow_upward,
                              AppTheme.successColor,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildBalanceItem(
                              context,
                              'Expenses',
                              totalExpenses,
                              Icons.arrow_downward,
                              AppTheme.errorColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Quick Actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickAction(
                    context,
                    'Add Income',
                    Icons.add_circle,
                    AppTheme.successColor,
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
                    Icons.remove_circle,
                    AppTheme.errorColor,
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
            
            const SizedBox(height: 24),
            
            // Recent Transactions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => AppRoutes.navigateToTransactions(context),
                  child: const Text('See All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Consumer<TransactionProvider>(
              builder: (context, transactionProvider, child) {
                final recentTransactions = transactionProvider.recentTransactions;
                
                if (recentTransactions.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No transactions yet',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add your first transaction to get started',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                return Column(
                  children: recentTransactions.take(5).map((transaction) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: transaction.isExpense 
                              ? AppTheme.errorColor.withOpacity(0.1)
                              : AppTheme.successColor.withOpacity(0.1),
                          child: Icon(
                            transaction.isExpense ? Icons.remove : Icons.add,
                            color: transaction.isExpense 
                                ? AppTheme.errorColor 
                                : AppTheme.successColor,
                          ),
                        ),
                        title: Text(transaction.title),
                        subtitle: Text(transaction.category),
                        trailing: Consumer<AuthProvider>(
                          builder: (context, authProvider, child) {
                            return Text(
                              '${transaction.isExpense ? '-' : '+'}${authProvider.currencySymbol}${transaction.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: transaction.isExpense 
                                    ? AppTheme.errorColor 
                                    : AppTheme.successColor,
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceItem(
    BuildContext context,
    String title,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return Text(
                      '${authProvider.currencySymbol}${amount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
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

  Widget _buildQuickAction(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder tabs - these will be implemented in separate files
class _TransactionsTab extends StatelessWidget {
  const _TransactionsTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Transactions Tab - Coming Soon'),
    );
  }
}

class _CategoriesTab extends StatelessWidget {
  const _CategoriesTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Categories Tab - Coming Soon'),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                
                // User avatar and info
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        backgroundImage: user?.profile?.avatar != null
                            ? NetworkImage(user!.profile!.avatar!)
                            : null,
                        child: user?.profile?.avatar == null
                            ? Text(
                                user?.firstName?.isNotEmpty == true
                                    ? user!.firstName![0].toUpperCase()
                                    : user?.username?.isNotEmpty == true
                                        ? user!.username![0].toUpperCase()
                                        : 'U',
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              )
                            : null,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Text(
                        user?.firstName?.isNotEmpty == true && user?.lastName?.isNotEmpty == true
                            ? '${user!.firstName} ${user!.lastName}'
                            : user?.username ?? 'User',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      if (user?.email?.isNotEmpty == true)
                        Text(
                          user!.email!,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Profile options
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.edit),
                        title: const Text('Edit Profile'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () => AppRoutes.navigateToEditProfile(context),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.currency_exchange),
                        title: const Text('Currency'),
                        subtitle: Text(user?.profile?.currency ?? 'USD'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          // Navigate to currency settings
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.account_balance_wallet),
                        title: const Text('Monthly Budget'),
                        subtitle: Text(user?.profile?.monthlyBudget != null 
                            ? '${authProvider.currencySymbol}${user!.profile!.monthlyBudget}'
                            : 'Not set'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          // Navigate to budget settings
                        },
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Settings options
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.notifications),
                        title: const Text('Notifications'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          // Navigate to notification settings
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.security),
                        title: const Text('Security'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          // Navigate to security settings
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.help),
                        title: const Text('Help & Support'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          // Navigate to help
                        },
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Logout button
                CustomButton(
                  text: 'Logout',
                  icon: Icons.logout,
                  backgroundColor: AppTheme.errorColor,
                  onPressed: () => AppRoutes.navigateToLogout(context),
                ),
                
                const SizedBox(height: 20),
                
                // App version
                Text(
                  '${AppConstants.appName} v${AppConstants.appVersion}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
} 