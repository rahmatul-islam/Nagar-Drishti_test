class NotificationType {
  static const String reportSubmitted = 'REPORT_SUBMITTED';
  static const String reportApproved = 'REPORT_APPROVED';
  static const String reportRejected = 'REPORT_REJECTED';
  static const String reportInProgress = 'REPORT_IN_PROGRESS';
  static const String reportResolved = 'REPORT_RESOLVED';
}

class NotificationModel {
  final String id;
  final String userId;
  final String reportId;
  final String type;
  final String message;
  final bool read;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.reportId,
    required this.type,
    required this.message,
    this.read = false,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final rawDate = json['createdAt'] as String? ?? json['\$createdAt'] as String? ?? DateTime.now().toIso8601String();
    return NotificationModel(
      id: json['id'] as String? ?? json['\$id'] as String? ?? 'notif_${DateTime.now().millisecondsSinceEpoch}',
      userId: json['userId'] as String? ?? '',
      reportId: json['reportId'] as String? ?? '',
      type: json['type'] as String? ?? NotificationType.reportSubmitted,
      message: json['message'] as String? ?? '',
      read: json['read'] as bool? ?? false,
      createdAt: DateTime.tryParse(rawDate) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'reportId': reportId,
      'type': type,
      'message': message,
      'read': read,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? reportId,
    String? type,
    String? message,
    bool? read,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      reportId: reportId ?? this.reportId,
      type: type ?? this.type,
      message: message ?? this.message,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
