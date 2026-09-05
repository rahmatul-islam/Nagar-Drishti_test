class ActivityLogModel {
  final String id;
  final String reportId;
  final String action;
  final String performedBy;
  final String userRole;
  final DateTime timestamp;
  final String? details;

  ActivityLogModel({
    required this.id,
    required this.reportId,
    required this.action,
    required this.performedBy,
    required this.userRole,
    required this.timestamp,
    this.details,
  });

  factory ActivityLogModel.fromJson(Map<String, dynamic> json) {
    return ActivityLogModel(
      id: json['id'] as String? ?? 'act_${DateTime.now().millisecondsSinceEpoch}',
      reportId: json['reportId'] as String? ?? '',
      action: json['action'] as String? ?? '',
      performedBy: json['performedBy'] as String? ?? 'System',
      userRole: json['userRole'] as String? ?? 'system',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      details: json['details'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reportId': reportId,
      'action': action,
      'performedBy': performedBy,
      'userRole': userRole,
      'timestamp': timestamp.toIso8601String(),
      'details': details,
    };
  }

  ActivityLogModel copyWith({
    String? id,
    String? reportId,
    String? action,
    String? performedBy,
    String? userRole,
    DateTime? timestamp,
    String? details,
  }) {
    return ActivityLogModel(
      id: id ?? this.id,
      reportId: reportId ?? this.reportId,
      action: action ?? this.action,
      performedBy: performedBy ?? this.performedBy,
      userRole: userRole ?? this.userRole,
      timestamp: timestamp ?? this.timestamp,
      details: details ?? this.details,
    );
  }
}
