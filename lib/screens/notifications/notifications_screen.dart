import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/notification_provider.dart';
import '../../models/notification_model.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSelectionMode = false;
  final Set<int> _selectedNotifications = {};

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    if (!mounted) return;
    
    try {
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      await notificationProvider.initialize();
    } catch (e) {
      print('📱 ERROR: Failed to initialize notifications: $e');
    }
  }

  Future<void> _onRefresh() async {
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    await notificationProvider.loadNotifications(refresh: true);
    await notificationProvider.loadStats();
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedNotifications.clear();
      }
    });
  }

  void _toggleNotificationSelection(int notificationId) {
    setState(() {
      if (_selectedNotifications.contains(notificationId)) {
        _selectedNotifications.remove(notificationId);
      } else {
        _selectedNotifications.add(notificationId);
      }
    });
  }

  void _selectAllNotifications() {
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    setState(() {
      _selectedNotifications.clear();
      _selectedNotifications.addAll(notificationProvider.notifications.map((n) => n.id));
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedNotifications.clear();
    });
  }

  Future<void> _performBulkAction(String action) async {
    if (_selectedNotifications.isEmpty) return;

    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    
    final success = await notificationProvider.bulkAction(
      notificationIds: _selectedNotifications.toList(),
      action: action,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully performed $action on ${_selectedNotifications.length} notifications'),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
      _toggleSelectionMode();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to perform bulk action'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showBulkActionBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildBulkActionBottomSheet(),
    );
  }

  Widget _buildBulkActionBottomSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
            child: Text(
              'Actions for ${_selectedNotifications.length} notifications',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Actions
          ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                leading: const Icon(Icons.mark_email_read, color: Colors.green),
                title: const Text('Mark as Read'),
                onTap: () {
                  Navigator.pop(context);
                  _performBulkAction('mark_read');
                },
              ),
              ListTile(
                leading: const Icon(Icons.mark_email_unread, color: Colors.orange),
                title: const Text('Mark as Unread'),
                onTap: () {
                  Navigator.pop(context);
                  _performBulkAction('mark_unread');
                },
              ),
              ListTile(
                leading: const Icon(Icons.archive, color: Colors.blue),
                title: const Text('Archive'),
                onTap: () {
                  Navigator.pop(context);
                  _performBulkAction('archive');
                },
              ),
              ListTile(
                leading: const Icon(Icons.unarchive, color: Colors.purple),
                title: const Text('Unarchive'),
                onTap: () {
                  Navigator.pop(context);
                  _performBulkAction('unarchive');
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation();
                },
              ),
            ],
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete ${_selectedNotifications.length} notifications? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performBulkAction('delete');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Consumer<NotificationProvider>(
        builder: (context, notificationProvider, child) {
          if (notificationProvider.isLoading && notificationProvider.notifications.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (notificationProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading notifications',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    notificationProvider.error!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _onRefresh,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: Column(
              children: [
                _buildStatsCard(notificationProvider),
                _buildFilterBar(notificationProvider),
                _buildSearchBar(notificationProvider),
                Expanded(
                  child: _buildNotificationsList(notificationProvider),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(_isSelectionMode ? '${_selectedNotifications.length} selected' : 'Notifications'),
      actions: [
        if (_isSelectionMode) ...[
          IconButton(
            icon: const Icon(Icons.select_all),
            onPressed: _selectAllNotifications,
            tooltip: 'Select All',
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearSelection,
            tooltip: 'Clear Selection',
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _selectedNotifications.isNotEmpty ? _showBulkActionBottomSheet : null,
            tooltip: 'Actions',
          ),
        ] else ...[
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              final unreadCount = notificationProvider.unreadCount;
              return IconButton(
                icon: Stack(
                  children: [
                    const Icon(Icons.mark_email_read),
                    if (unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 12,
                            minHeight: 12,
                          ),
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () {
                  notificationProvider.markAllAsRead();
                },
                tooltip: 'Mark All Read',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.checklist),
            onPressed: _toggleSelectionMode,
            tooltip: 'Select Mode',
          ),
        ],
      ],
    );
  }

  Widget _buildStatsCard(NotificationProvider provider) {
    final stats = provider.stats;
    if (stats == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem('Total', stats.totalCount.toString(), Icons.notifications),
          ),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
          Expanded(
            child: _buildStatItem('Unread', stats.unreadCount.toString(), Icons.mark_email_unread),
          ),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
          Expanded(
            child: _buildStatItem('Archived', stats.archivedCount.toString(), Icons.archive),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar(NotificationProvider provider) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip('All', 'all', provider),
          const SizedBox(width: 8),
          _buildFilterChip('Unread', 'unread', provider),
          const SizedBox(width: 8),
          _buildFilterChip('Read', 'read', provider),
          const SizedBox(width: 8),
          _buildFilterChip('Archived', 'archived', provider),
          const SizedBox(width: 16),
          _buildTypeFilterChip('Transaction', 'transaction', provider),
          const SizedBox(width: 8),
          _buildTypeFilterChip('Budget', 'budget', provider),
          const SizedBox(width: 8),
          _buildTypeFilterChip('System', 'system', provider),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, NotificationProvider provider) {
    final isSelected = provider.selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => provider.setFilter(value),
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryColor,
    );
  }

  Widget _buildTypeFilterChip(String label, String value, NotificationProvider provider) {
    final isSelected = provider.selectedType == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => provider.setTypeFilter(isSelected ? 'all' : value),
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryColor,
    );
  }

  Widget _buildSearchBar(NotificationProvider provider) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          hintText: 'Search notifications...',
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: provider.setSearchQuery,
      ),
    );
  }

  Widget _buildNotificationsList(NotificationProvider provider) {
    final notifications = provider.notifications;

    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No notifications found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'re all caught up!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _buildNotificationCard(notification, provider);
      },
    );
  }

  Widget _buildNotificationCard(NotificationModel notification, NotificationProvider provider) {
    final isSelected = _selectedNotifications.contains(notification.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.white : Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: _buildNotificationIcon(notification),
        title: Row(
          children: [
            Expanded(
              child: Text(
                notification.title,
                style: TextStyle(
                  fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.message,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildPriorityChip(notification.priority),
                const SizedBox(width: 8),
                _buildTypeChip(notification.type),
                const Spacer(),
                Text(
                  notification.timeSinceCreated,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: _isSelectionMode
            ? Checkbox(
                value: isSelected,
                onChanged: (_) => _toggleNotificationSelection(notification.id),
                activeColor: AppTheme.primaryColor,
              )
            : PopupMenuButton<String>(
                onSelected: (action) => _handleNotificationAction(action, notification, provider),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'mark_read',
                    child: Row(
                      children: [
                        Icon(notification.isRead ? Icons.mark_email_unread : Icons.mark_email_read),
                        const SizedBox(width: 8),
                        Text(notification.isRead ? 'Mark Unread' : 'Mark Read'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'archive',
                    child: Row(
                      children: [
                        Icon(notification.isArchived ? Icons.unarchive : Icons.archive),
                        const SizedBox(width: 8),
                        Text(notification.isArchived ? 'Unarchive' : 'Archive'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
        onTap: () {
          if (_isSelectionMode) {
            _toggleNotificationSelection(notification.id);
          } else {
            _handleNotificationTap(notification, provider);
          }
        },
      ),
    );
  }

  Widget _buildNotificationIcon(NotificationModel notification) {
    IconData iconData;
    Color iconColor;

    switch (notification.type) {
      case 'transaction':
        iconData = Icons.account_balance_wallet;
        iconColor = Colors.green;
        break;
      case 'budget':
        iconData = Icons.savings;
        iconColor = Colors.orange;
        break;
      case 'reminder':
        iconData = Icons.alarm;
        iconColor = Colors.blue;
        break;
      case 'system':
        iconData = Icons.settings;
        iconColor = Colors.grey;
        break;
      case 'achievement':
        iconData = Icons.emoji_events;
        iconColor = Colors.amber;
        break;
      case 'security':
        iconData = Icons.security;
        iconColor = Colors.red;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = Colors.grey;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, color: iconColor, size: 20),
    );
  }

  Widget _buildPriorityChip(String priority) {
    Color color;
    switch (priority) {
      case 'urgent':
        color = Colors.red;
        break;
      case 'high':
        color = Colors.orange;
        break;
      case 'medium':
        color = Colors.blue;
        break;
      case 'low':
        color = Colors.grey;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTypeChip(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Text(
        type.toUpperCase(),
        style: TextStyle(
          color: AppTheme.primaryColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _handleNotificationTap(NotificationModel notification, NotificationProvider provider) {
    if (!notification.isRead) {
      provider.markAsRead(notification.id);
    }
    
    // Handle action URL if available
    if (notification.actionUrl != null) {
      // Navigate to the specified URL/route
      // This could be enhanced to handle deep linking
      print('Navigate to: ${notification.actionUrl}');
    }
  }

  void _handleNotificationAction(String action, NotificationModel notification, NotificationProvider provider) {
    switch (action) {
      case 'mark_read':
        if (notification.isRead) {
          // Mark as unread - would need additional API endpoint
          print('Mark as unread not implemented');
        } else {
          provider.markAsRead(notification.id);
        }
        break;
      case 'archive':
        provider.archiveNotification(notification.id);
        break;
      case 'delete':
        _showDeleteSingleConfirmation(notification, provider);
        break;
    }
  }

  void _showDeleteSingleConfirmation(NotificationModel notification, NotificationProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification'),
        content: Text('Are you sure you want to delete "${notification.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              provider.deleteNotification(notification.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
} 