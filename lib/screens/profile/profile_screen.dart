import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          );
        },
      ),
    );
  }
}

 