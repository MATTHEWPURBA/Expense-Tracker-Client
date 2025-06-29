import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/notification_provider.dart';
import '../../routes/app_routes.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';
import '../notifications/notifications_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    _initializeCurrencies();
  }

  Future<void> _initializeCurrencies() async {
    if (!mounted) return;
    
    try {
      final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);
      
      // Initialize with fallback currencies immediately
      currencyProvider.initializeWithFallback();
      
      // Then try to load from API
      await currencyProvider.loadCurrencies(refresh: false);
    } catch (e) {
      print('💱 ERROR: Failed to initialize currencies: $e');
    }
  }

  void _showCurrencyDialog(BuildContext context) async {
    print('🔵 DEBUG: _showCurrencyDialog called!');
    print('🔵 DEBUG: Context is valid: ${context.mounted}');
    
    try {
      // Always refresh currency data from API before showing dialog
      final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);
      print('🔵 DEBUG: Refreshing currencies from API...');
      await currencyProvider.loadCurrencies(refresh: true);
      print('🔵 DEBUG: Currency refresh completed. Total currencies: ${currencyProvider.currencies.length}');
      
      if (context.mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (BuildContext context) {
            print('🔵 DEBUG: Modal bottom sheet builder called');
            return _buildCurrencyBottomSheet(context);
          },
        );
        print('🔵 DEBUG: showModalBottomSheet completed successfully');
      }
    } catch (e) {
      print('🔴 ERROR: Failed to show currency dialog: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load currencies: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildCurrencyBottomSheet(BuildContext context) {
    print('🔵 DEBUG: Building currency bottom sheet widget');
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Select Currency',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    print('🔵 DEBUG: Close button pressed');
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // Currency list
          Expanded(
            child: Consumer2<AuthProvider, CurrencyProvider>(
              builder: (context, authProvider, currencyProvider, child) {
                final currentCurrency = authProvider.user?.profile?.currency ?? 'USD';
                print('🔵 DEBUG: Current currency: $currentCurrency');
                
                // Show loading indicator if currencies are loading
                if (currencyProvider.isLoading && currencyProvider.currencies.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading currencies...'),
                      ],
                    ),
                  );
                }
                
                // Show error message if currencies failed to load
                if (currencyProvider.currencies.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No currencies available',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        if (currencyProvider.error != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            currencyProvider.error!,
                            style: TextStyle(color: Colors.orange[700], fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            currencyProvider.loadCurrencies(refresh: true);
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                
                return Column(
                  children: [
                    // Show error banner if there's an error (but currencies are available)
                    if (currencyProvider.error != null) ...[
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          border: Border.all(color: Colors.orange.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber, color: Colors.orange[700], size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                currencyProvider.error!,
                                style: TextStyle(
                                  color: Colors.orange[700],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Currency list
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: currencyProvider.currencies.length,
                        itemBuilder: (context, index) {
                          final currency = currencyProvider.currencies[index];
                          final isSelected = currency.code == currentCurrency;
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
                                width: 1.5,
                              ),
                            ),
                            child: ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isSelected ? AppTheme.primaryColor : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    currency.symbol,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.white : Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                currency.name,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? AppTheme.primaryColor : null,
                                ),
                              ),
                              subtitle: Text(currency.code),
                              trailing: isSelected
                                  ? Icon(
                                      Icons.check_circle,
                                      color: AppTheme.primaryColor,
                                    )
                                  : null,
                              onTap: () async {
                                print('🔵 DEBUG: Currency selected: ${currency.name} (${currency.code})');
                                
                                try {
                                  await authProvider.updateCurrency(currency.code);
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Currency changed to ${currency.name}'),
                                        backgroundColor: AppTheme.primaryColor,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  print('🔴 ERROR: Failed to update currency: $e');
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Failed to update currency'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showBudgetDialog(BuildContext context) {
    print('🟢 DEBUG: _showBudgetDialog called!');
    print('🟢 DEBUG: Context is valid: ${context.mounted}');
    
    if (context.mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          print('🟢 DEBUG: Budget modal bottom sheet builder called');
          return _buildBudgetBottomSheet(context);
        },
      );
      print('🟢 DEBUG: showModalBottomSheet completed successfully');
    }
  }

  Widget _buildBudgetBottomSheet(BuildContext context) {
    print('🟢 DEBUG: Building budget bottom sheet widget');
    
    return Consumer2<AuthProvider, CurrencyProvider>(
      builder: (context, authProvider, currencyProvider, child) {
        final currentBudget = authProvider.user?.profile?.monthlyBudget?.toString() ?? '';
        final currencySymbol = authProvider.getCurrencySymbol(currencyProvider);
        final TextEditingController budgetController = TextEditingController(text: currentBudget);
        
        return Container(
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Set Monthly Budget',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Track your spending with a monthly limit',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        print('🟢 DEBUG: Close button pressed');
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              
              // Budget form
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Current budget info
                      if (currentBudget.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, 
                                   color: AppTheme.primaryColor, 
                                   size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Current budget: $currencySymbol$currentBudget',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      
                      // Budget input field
                      Text(
                        'Monthly Budget Amount',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: TextField(
                          controller: budgetController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            prefixIcon: Container(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                currencySymbol,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                            hintText: '0.00',
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 18,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Helper text
                      Text(
                        'Set a realistic budget to help you track and control your monthly expenses',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      
                      const Spacer(),
                      
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () async {
                                print('🟢 DEBUG: Budget save button pressed');
                                final budgetText = budgetController.text.trim();
                                
                                if (budgetText.isEmpty) {
                                  // Clear budget
                                  try {
                                    await authProvider.updateMonthlyBudget(null);
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Monthly budget cleared'),
                                          backgroundColor: AppTheme.primaryColor,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    print('🔴 ERROR: Failed to clear budget: $e');
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Failed to clear budget'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                  return;
                                }
                                
                                final budget = double.tryParse(budgetText);
                                if (budget == null || budget <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please enter a valid budget amount'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }
                                
                                try {
                                  await authProvider.updateMonthlyBudget(budget);
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Budget set to $currencySymbol${budget.toStringAsFixed(2)}'),
                                        backgroundColor: AppTheme.primaryColor,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  print('🔴 ERROR: Failed to update budget: $e');
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Failed to update budget'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Save Budget',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    print('📱 DEBUG: ProfileScreen build called');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AppRoutes.navigateToLogout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.user;
          
          return SingleChildScrollView(
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
                          print('🟡 DEBUG: Currency ListTile tapped!');
                          print('🟡 DEBUG: Current context mounted: ${context.mounted}');
                          print('🟡 DEBUG: Calling _showCurrencyDialog...');
                          _showCurrencyDialog(context);
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
                          print('🟢 DEBUG: Budget ListTile tapped!');
                          print('🟢 DEBUG: Current context mounted: ${context.mounted}');
                          print('🟢 DEBUG: Calling _showBudgetDialog...');
                          _showBudgetDialog(context);
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
                          // Navigate to notifications screen
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const NotificationsScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.security),
                        title: const Text('Security'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          // Navigate to security settings
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Security Settings - Coming Soon')),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.help),
                        title: const Text('Help & Support'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          // Navigate to help
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Help & Support - Coming Soon')),
                          );
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
          );
        },
      ),
    );
  }
}

 