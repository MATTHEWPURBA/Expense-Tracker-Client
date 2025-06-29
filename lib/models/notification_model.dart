class NotificationModel {
  final int id;
  final String title;
  final String message;
  final String type;
  final String priority;
  final bool isRead;
  final bool isArchived;
  final String? actionUrl;
  final Map<String, dynamic>? metadata;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? readAt;
  final String timeSinceCreated;
  final bool isExpired;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.priority,
    required this.isRead,
    required this.isArchived,
    this.actionUrl,
    this.metadata,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
    this.readAt,
    required this.timeSinceCreated,
    required this.isExpired,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      type: json['type'],
      priority: json['priority'],
      isRead: json['is_read'],
      isArchived: json['is_archived'],
      actionUrl: json['action_url'],
      metadata: json['metadata'],
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      timeSinceCreated: json['time_since_created'],
      isExpired: json['is_expired'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'priority': priority,
      'is_read': isRead,
      'is_archived': isArchived,
      'action_url': actionUrl,
      'metadata': metadata,
      'expires_at': expiresAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'time_since_created': timeSinceCreated,
      'is_expired': isExpired,
    };
  }

  NotificationModel copyWith({
    int? id,
    String? title,
    String? message,
    String? type,
    String? priority,
    bool? isRead,
    bool? isArchived,
    String? actionUrl,
    Map<String, dynamic>? metadata,
    DateTime? expiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? readAt,
    String? timeSinceCreated,
    bool? isExpired,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      isRead: isRead ?? this.isRead,
      isArchived: isArchived ?? this.isArchived,
      actionUrl: actionUrl ?? this.actionUrl,
      metadata: metadata ?? this.metadata,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      readAt: readAt ?? this.readAt,
      timeSinceCreated: timeSinceCreated ?? this.timeSinceCreated,
      isExpired: isExpired ?? this.isExpired,
    );
  }

  // Helper getters
  bool get isTransaction => type == 'transaction';
  bool get isBudget => type == 'budget';
  bool get isReminder => type == 'reminder';
  bool get isSystem => type == 'system';
  bool get isAchievement => type == 'achievement';
  bool get isSecurity => type == 'security';

  bool get isUrgent => priority == 'urgent';
  bool get isHigh => priority == 'high';
  bool get isMedium => priority == 'medium';
  bool get isLow => priority == 'low';

  @override
  String toString() {
    return 'NotificationModel(id: $id, title: $title, type: $type, priority: $priority, isRead: $isRead)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class NotificationPreference {
  final int id;
  final bool emailEnabled;
  final bool emailTransaction;
  final bool emailBudget;
  final bool emailReminder;
  final bool emailSystem;
  final bool emailAchievement;
  final bool emailSecurity;
  final bool pushEnabled;
  final bool pushTransaction;
  final bool pushBudget;
  final bool pushReminder;
  final bool pushSystem;
  final bool pushAchievement;
  final bool pushSecurity;
  final bool inAppEnabled;
  final bool inAppTransaction;
  final bool inAppBudget;
  final bool inAppReminder;
  final bool inAppSystem;
  final bool inAppAchievement;
  final bool inAppSecurity;
  final bool quietHoursEnabled;
  final String quietHoursStart;
  final String quietHoursEnd;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationPreference({
    required this.id,
    required this.emailEnabled,
    required this.emailTransaction,
    required this.emailBudget,
    required this.emailReminder,
    required this.emailSystem,
    required this.emailAchievement,
    required this.emailSecurity,
    required this.pushEnabled,
    required this.pushTransaction,
    required this.pushBudget,
    required this.pushReminder,
    required this.pushSystem,
    required this.pushAchievement,
    required this.pushSecurity,
    required this.inAppEnabled,
    required this.inAppTransaction,
    required this.inAppBudget,
    required this.inAppReminder,
    required this.inAppSystem,
    required this.inAppAchievement,
    required this.inAppSecurity,
    required this.quietHoursEnabled,
    required this.quietHoursStart,
    required this.quietHoursEnd,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationPreference.fromJson(Map<String, dynamic> json) {
    return NotificationPreference(
      id: json['id'],
      emailEnabled: json['email_enabled'],
      emailTransaction: json['email_transaction'],
      emailBudget: json['email_budget'],
      emailReminder: json['email_reminder'],
      emailSystem: json['email_system'],
      emailAchievement: json['email_achievement'],
      emailSecurity: json['email_security'],
      pushEnabled: json['push_enabled'],
      pushTransaction: json['push_transaction'],
      pushBudget: json['push_budget'],
      pushReminder: json['push_reminder'],
      pushSystem: json['push_system'],
      pushAchievement: json['push_achievement'],
      pushSecurity: json['push_security'],
      inAppEnabled: json['in_app_enabled'],
      inAppTransaction: json['in_app_transaction'],
      inAppBudget: json['in_app_budget'],
      inAppReminder: json['in_app_reminder'],
      inAppSystem: json['in_app_system'],
      inAppAchievement: json['in_app_achievement'],
      inAppSecurity: json['in_app_security'],
      quietHoursEnabled: json['quiet_hours_enabled'],
      quietHoursStart: json['quiet_hours_start'],
      quietHoursEnd: json['quiet_hours_end'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email_enabled': emailEnabled,
      'email_transaction': emailTransaction,
      'email_budget': emailBudget,
      'email_reminder': emailReminder,
      'email_system': emailSystem,
      'email_achievement': emailAchievement,
      'email_security': emailSecurity,
      'push_enabled': pushEnabled,
      'push_transaction': pushTransaction,
      'push_budget': pushBudget,
      'push_reminder': pushReminder,
      'push_system': pushSystem,
      'push_achievement': pushAchievement,
      'push_security': pushSecurity,
      'in_app_enabled': inAppEnabled,
      'in_app_transaction': inAppTransaction,
      'in_app_budget': inAppBudget,
      'in_app_reminder': inAppReminder,
      'in_app_system': inAppSystem,
      'in_app_achievement': inAppAchievement,
      'in_app_security': inAppSecurity,
      'quiet_hours_enabled': quietHoursEnabled,
      'quiet_hours_start': quietHoursStart,
      'quiet_hours_end': quietHoursEnd,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class NotificationStats {
  final int totalCount;
  final int unreadCount;
  final int readCount;
  final int archivedCount;
  final Map<String, int> byType;
  final Map<String, int> byPriority;
  final List<NotificationModel> recentNotifications;

  NotificationStats({
    required this.totalCount,
    required this.unreadCount,
    required this.readCount,
    required this.archivedCount,
    required this.byType,
    required this.byPriority,
    required this.recentNotifications,
  });

  factory NotificationStats.fromJson(Map<String, dynamic> json) {
    return NotificationStats(
      totalCount: json['total_count'],
      unreadCount: json['unread_count'],
      readCount: json['read_count'],
      archivedCount: json['archived_count'],
      byType: Map<String, int>.from(json['by_type'] ?? {}),
      byPriority: Map<String, int>.from(json['by_priority'] ?? {}),
      recentNotifications: (json['recent_notifications'] as List?)
          ?.map((item) => NotificationModel.fromJson(item))
          .toList() ?? [],
    );
  }
} 