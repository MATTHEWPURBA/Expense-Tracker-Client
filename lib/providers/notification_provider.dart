import 'dart:io';
import 'package:flutter/material.dart';

import '../models/notification_model.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

class NotificationProvider extends ChangeNotifier {
  final ApiService _apiService;
  
  List<NotificationModel> _notifications = [];
  NotificationStats? _stats;
  NotificationPreference? _preferences;
  bool _isLoading = false;
  String? _error;
  AuthProvider? _authProvider;
  bool _disposed = false;

  // Filter states
  String _selectedFilter = 'all'; // all, read, unread, archived
  String _selectedType = 'all';
  String _selectedPriority = 'all';
  String _searchQuery = '';

  NotificationProvider() : _apiService = ApiService();

  // Getters
  List<NotificationModel> get notifications => _getFilteredNotifications();
  List<NotificationModel> get allNotifications => _notifications;
  NotificationStats? get stats => _stats;
  NotificationPreference? get preferences => _preferences;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _stats?.unreadCount ?? 0;
  
  // Filter getters
  String get selectedFilter => _selectedFilter;
  String get selectedType => _selectedType;
  String get selectedPriority => _selectedPriority;
  String get searchQuery => _searchQuery;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // Update auth provider reference
  void updateAuth(AuthProvider authProvider) {
    _authProvider = authProvider;
  }

  // Load notifications with optional filters
  Future<void> loadNotifications({
    int page = 1,
    bool refresh = false,
  }) async {
    if (_disposed) return;
    
    if (refresh) {
      _notifications.clear();
    }
    
    _setLoading(true);
    _clearError();

    try {
      // Convert filter states to API parameters
      bool? isRead;
      bool? isArchived;
      
      if (_selectedFilter == 'read') isRead = true;
      if (_selectedFilter == 'unread') isRead = false;
      if (_selectedFilter == 'archived') isArchived = true;
      
      final newNotifications = await _apiService.getNotifications(
        page: page,
        isRead: isRead,
        isArchived: isArchived,
        type: _selectedType != 'all' ? _selectedType : null,
        priority: _selectedPriority != 'all' ? _selectedPriority : null,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      if (page == 1 || refresh) {
        _notifications = newNotifications;
      } else {
        _notifications.addAll(newNotifications);
      }

      _safeNotifyListeners();
    } on HttpException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('Failed to load notifications');
    } finally {
      _setLoading(false);
    }
  }

  // Load notification statistics
  Future<void> loadStats() async {
    if (_disposed) return;

    try {
      _stats = await _apiService.getNotificationStats();
      _safeNotifyListeners();
    } catch (e) {
      print('📱 Failed to load notification stats: $e');
    }
  }

  // Load notification preferences
  Future<void> loadPreferences() async {
    if (_disposed) return;

    try {
      _preferences = await _apiService.getNotificationPreferences();
      _safeNotifyListeners();
    } catch (e) {
      print('📱 Failed to load notification preferences: $e');
    }
  }

  // Update notification preferences
  Future<bool> updatePreferences(Map<String, dynamic> preferences) async {
    if (_disposed) return false;

    _setLoading(true);
    _clearError();

    try {
      _preferences = await _apiService.updateNotificationPreferences(preferences);
      _safeNotifyListeners();
      return true;
    } on HttpException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Failed to update preferences');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Mark notification as read
  Future<bool> markAsRead(int notificationId) async {
    if (_disposed) return false;

    try {
      final updatedNotification = await _apiService.markNotificationRead(notificationId);
      
      // Update local notification
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = updatedNotification;
        _safeNotifyListeners();
      }
      
      // Reload stats to update unread count
      loadStats();
      
      return true;
    } catch (e) {
      print('📱 Failed to mark notification as read: $e');
      return false;
    }
  }

  // Mark all notifications as read
  Future<bool> markAllAsRead() async {
    if (_disposed) return false;

    _setLoading(true);
    _clearError();

    try {
      await _apiService.markAllNotificationsRead();
      
      // Update local notifications
      for (int i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].isRead) {
          _notifications[i] = _notifications[i].copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
        }
      }
      
      _safeNotifyListeners();
      
      // Reload stats
      loadStats();
      
      return true;
    } on HttpException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Failed to mark all as read');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete notification
  Future<bool> deleteNotification(int notificationId) async {
    if (_disposed) return false;

    try {
      await _apiService.deleteNotification(notificationId);
      
      // Remove from local list
      _notifications.removeWhere((n) => n.id == notificationId);
      _safeNotifyListeners();
      
      // Reload stats
      loadStats();
      
      return true;
    } catch (e) {
      print('📱 Failed to delete notification: $e');
      return false;
    }
  }

  // Archive notification
  Future<bool> archiveNotification(int notificationId) async {
    if (_disposed) return false;

    try {
      final updatedNotification = await _apiService.updateNotification(
        notificationId, 
        {'is_archived': true}
      );
      
      // Update local notification
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = updatedNotification;
        _safeNotifyListeners();
      }
      
      return true;
    } catch (e) {
      print('📱 Failed to archive notification: $e');
      return false;
    }
  }

  // Bulk actions
  Future<bool> bulkAction({
    required List<int> notificationIds,
    required String action,
  }) async {
    if (_disposed) return false;

    _setLoading(true);
    _clearError();

    try {
      await _apiService.bulkNotificationAction(
        notificationIds: notificationIds,
        action: action,
      );
      
      // Reload notifications and stats
      await loadNotifications(refresh: true);
      await loadStats();
      
      return true;
    } on HttpException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Failed to perform bulk action');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Filter methods
  void setFilter(String filter) {
    if (_selectedFilter != filter) {
      _selectedFilter = filter;
      _safeNotifyListeners();
      loadNotifications(refresh: true);
    }
  }

  void setTypeFilter(String type) {
    if (_selectedType != type) {
      _selectedType = type;
      _safeNotifyListeners();
      loadNotifications(refresh: true);
    }
  }

  void setPriorityFilter(String priority) {
    if (_selectedPriority != priority) {
      _selectedPriority = priority;
      _safeNotifyListeners();
      loadNotifications(refresh: true);
    }
  }

  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      _safeNotifyListeners();
      // Debounce search to avoid too many API calls
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_searchQuery == query && !_disposed) {
          loadNotifications(refresh: true);
        }
      });
    }
  }

  void clearFilters() {
    _selectedFilter = 'all';
    _selectedType = 'all';
    _selectedPriority = 'all';
    _searchQuery = '';
    _safeNotifyListeners();
    loadNotifications(refresh: true);
  }

  // Get filtered notifications (client-side filtering for immediate response)
  List<NotificationModel> _getFilteredNotifications() {
    List<NotificationModel> filtered = List.from(_notifications);
    
    // Note: Most filtering is done server-side, but we can do some client-side
    // filtering for better UX
    
    return filtered;
  }

  // Get notifications by type
  List<NotificationModel> getNotificationsByType(String type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  // Get unread notifications
  List<NotificationModel> get unreadNotifications {
    return _notifications.where((n) => !n.isRead).toList();
  }

  // Get recent notifications (last 5)
  List<NotificationModel> get recentNotifications {
    final sorted = List<NotificationModel>.from(_notifications);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(5).toList();
  }

  // Helper methods
  void _setLoading(bool loading) {
    if (_disposed) return;
    _isLoading = loading;
    _safeNotifyListeners();
  }

  void _setError(String error) {
    if (_disposed) return;
    _error = error;
    _safeNotifyListeners();
  }

  void _clearError() {
    if (_disposed) return;
    _error = null;
    _safeNotifyListeners();
  }

  void _safeNotifyListeners() {
    if (_disposed || !hasListeners) return;
    
    Future.microtask(() {
      if (!_disposed && hasListeners) {
        try {
          notifyListeners();
        } catch (e) {
          print('📱 WARNING: Error notifying listeners: $e');
        }
      }
    });
  }

  // Clear all data (useful for logout)
  void clear() {
    if (_disposed) return;
    _notifications.clear();
    _stats = null;
    _preferences = null;
    _selectedFilter = 'all';
    _selectedType = 'all';
    _selectedPriority = 'all';
    _searchQuery = '';
    _clearError();
  }

  // Initialize with basic data load
  Future<void> initialize() async {
    if (_disposed) return;
    
    await Future.wait([
      loadNotifications(refresh: true),
      loadStats(),
      loadPreferences(),
    ]);
  }
} 