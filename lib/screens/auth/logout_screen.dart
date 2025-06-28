import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';

class LogoutScreen extends StatefulWidget {
  const LogoutScreen({super.key});

  @override
  State<LogoutScreen> createState() => _LogoutScreenState();
}

class _LogoutScreenState extends State<LogoutScreen> {
  bool _isLoggingOut = false;

  Future<void> _handleLogout() async {
    setState(() {
      _isLoggingOut = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      await authProvider.logout();
      
      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have been logged out successfully'),
            backgroundColor: AppTheme.successColor,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Navigate to login screen
        AppRoutes.navigateToLogin(context);
      }
    } catch (e) {
      if (mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.logout,
                color: AppTheme.warningColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text('Confirm Logout'),
            ],
          ),
          content: const Text(
            'Are you sure you want to logout? You will need to login again to access your account.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: _isLoggingOut ? null : () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: _isLoggingOut ? null : () {
                Navigator.of(context).pop();
                _handleLogout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                foregroundColor: Colors.white,
              ),
              child: _isLoggingOut
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Logout',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            children: [
              const SizedBox(height: 40),
              
              // Logout icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(60),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.logout,
                  size: 60,
                  color: AppTheme.primaryColor,
                ),
              ),
              
              const SizedBox(height: 32),
              
              Text(
                'Ready to Logout?',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'You can always log back in anytime to continue managing your expenses.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 48),
              
              // User information card
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  final user = authProvider.user;
                  
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // User avatar
                        CircleAvatar(
                          radius: 40,
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
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                )
                              : null,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // User name
                        Text(
                          user?.firstName?.isNotEmpty == true && user?.lastName?.isNotEmpty == true
                              ? '${user!.firstName} ${user!.lastName}'
                              : user?.username ?? 'User',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // User email
                        if (user?.email?.isNotEmpty == true)
                          Text(
                            user!.email!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        
                        const SizedBox(height: 24),
                        
                        // Logout button
                        CustomButton(
                          text: 'Logout',
                          icon: Icons.logout,
                          backgroundColor: AppTheme.errorColor,
                          onPressed: _showLogoutConfirmationDialog,
                          isLoading: _isLoggingOut,
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Cancel button
                        CustomButton(
                          text: 'Stay Logged In',
                          backgroundColor: Colors.grey[100],
                          textColor: AppTheme.primaryColor,
                          onPressed: _isLoggingOut ? null : () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 32),
              
              // App information
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      color: Colors.white.withOpacity(0.8),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${AppConstants.appName} v${AppConstants.appVersion}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 