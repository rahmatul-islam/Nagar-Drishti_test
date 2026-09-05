import '../features/report/services/ai_service.dart';
import 'activity_log_model.dart';

enum VerificationStatus {
  needsReview,
  verified,
  fake,
}

extension VerificationStatusExtension on VerificationStatus {
  String get labelBangla {
    switch (this) {
      case VerificationStatus.needsReview:
        return 'যাচাইাধীন (Needs Review)';
      case VerificationStatus.verified:
        return 'সত্যতা যাচাইকৃত (Verified)';
      case VerificationStatus.fake:
        return 'ভুয়া / ফেক (Fake)';
    }
  }

  String get code {
    switch (this) {
      case VerificationStatus.needsReview:
        return 'NEEDS_REVIEW';
      case VerificationStatus.verified:
        return 'VERIFIED';
      case VerificationStatus.fake:
        return 'FAKE';
    }
  }

  static VerificationStatus fromCode(String code) {
    switch (code.toUpperCase()) {
      case 'VERIFIED':
        return VerificationStatus.verified;
      case 'FAKE':
        return VerificationStatus.fake;
      case 'NEEDS_REVIEW':
      default:
        return VerificationStatus.needsReview;
    }
  }
}

enum ReportStatus {
  pending,
  newReport,
  adminReview,
  assigned,
  accepted,
  inProgress,
  onHold,
  resolved,
  rejected,
  finalVerification,
  pendingSync,
}

extension ReportStatusExtension on ReportStatus {
  String get labelBangla {
    switch (this) {
      case ReportStatus.pending:
        return 'অপেক্ষমাণ';
      case ReportStatus.newReport:
        return 'নতুন রিপোর্ট (New)';
      case ReportStatus.adminReview:
        return 'এডমিন রিভিওয়াধীন (Admin Review)';
      case ReportStatus.assigned:
        return 'বরাদ্দকৃত (Assigned)';
      case ReportStatus.accepted:
        return 'গৃহীত (Accepted)';
      case ReportStatus.inProgress:
        return 'চলমান (In Progress)';
      case ReportStatus.onHold:
        return 'স্থগিত (On Hold)';
      case ReportStatus.resolved:
        return 'সম্পন্ন (Completed)';
      case ReportStatus.rejected:
        return 'বাতিল (Rejected)';
      case ReportStatus.finalVerification:
        return 'চূড়ান্ত যাচাইকৃত (Final Verification)';
      case ReportStatus.pendingSync:
        return 'অফলাইন - সিঙ্ক বাকি';
    }
  }

  String get code {
    switch (this) {
      case ReportStatus.pending:
        return 'PENDING';
      case ReportStatus.newReport:
        return 'NEW_REPORT';
      case ReportStatus.adminReview:
        return 'ADMIN_REVIEW';
      case ReportStatus.assigned:
        return 'ASSIGNED';
      case ReportStatus.accepted:
        return 'ACCEPTED';
      case ReportStatus.inProgress:
        return 'IN_PROGRESS';
      case ReportStatus.onHold:
        return 'ON_HOLD';
      case ReportStatus.resolved:
        return 'RESOLVED';
      case ReportStatus.rejected:
        return 'REJECTED';
      case ReportStatus.finalVerification:
        return 'FINAL_VERIFICATION';
      case ReportStatus.pendingSync:
        return 'PENDING_SYNC';
    }
  }

  static ReportStatus fromCode(String code) {
    switch (code.toUpperCase()) {
      case 'PENDING':
        return ReportStatus.pending;
      case 'NEW_REPORT':
        return ReportStatus.newReport;
      case 'ADMIN_REVIEW':
        return ReportStatus.adminReview;
      case 'ASSIGNED':
        return ReportStatus.assigned;
      case 'ACCEPTED':
        return ReportStatus.accepted;
      case 'IN_PROGRESS':
        return ReportStatus.inProgress;
      case 'ON_HOLD':
        return ReportStatus.onHold;
      case 'RESOLVED':
        return ReportStatus.resolved;
      case 'REJECTED':
        return ReportStatus.rejected;
      case 'FINAL_VERIFICATION':
        return ReportStatus.finalVerification;
      case 'PENDING_SYNC':
        return ReportStatus.pendingSync;
      default:
        return ReportStatus.pending;
    }
  }
}

enum ReportSeverity {
  low,
  medium,
  high,
  critical,
}

extension ReportSeverityExtension on ReportSeverity {
  String get labelBangla {
    switch (this) {
      case ReportSeverity.low:
        return 'Low Risk (কম ঝুঁকি)';
      case ReportSeverity.medium:
        return 'Medium Risk (মাঝারি ঝুঁকি)';
      case ReportSeverity.high:
        return 'High Risk (উচ্চ ঝুঁকি)';
      case ReportSeverity.critical:
        return 'High Risk - Critical (জরুরি)';
    }
  }

  String get code {
    switch (this) {
      case ReportSeverity.low:
        return 'LOW';
      case ReportSeverity.medium:
        return 'MEDIUM';
      case ReportSeverity.high:
        return 'HIGH';
      case ReportSeverity.critical:
        return 'CRITICAL';
    }
  }

  static ReportSeverity fromCode(String code) {
    switch (code.toUpperCase()) {
      case 'CRITICAL':
        return ReportSeverity.critical;
      case 'HIGH':
        return ReportSeverity.high;
      case 'MEDIUM':
        return ReportSeverity.medium;
      case 'LOW':
      default:
        return ReportSeverity.low;
    }
  }
}

class RiskEngine {
  static const Map<String, int> baseCategoryScores = {
    'Open electrical wire/current danger': 4,
    'electrical_wire': 4,
    'খোলা বিদ্যুতের তার': 4,

    'Large pothole': 3,
    'large_pothole': 3,
    'সড়কের বড় গর্ত': 3,

    'Severe waterlogging': 3,
    'severe_waterlogging': 3,
    'তীব্র জলাবদ্ধতা': 3,

    'Drainage problem': 2,
    'drainage': 2,
    'ড্রেনেজ সমস্যা': 2,

    'Broken street light': 2,
    'broken_light': 2,
    'নষ্ট স্ট্রিট লাইট': 2,

    'Small pothole': 1,
    'small_pothole': 1,
    'সড়কের ছোট গর্ত': 1,

    'Garbage/illegal dumping': 1,
    'garbage': 1,
    'ময়লা-আবর্জনা': 1,

    'Footpath problem': 1,
    'footpath': 1,
    'ফুটপাতের সমস্যা': 1,

    'Other': 0,
    'other': 0,
  };

  static const List<String> allRiskFactors = [
    'দুর্ঘটনার আশঙ্কা',
    'জীবনহানির সম্ভাবনা',
    'ব্যস্ত সড়ক',
    'স্কুল/হাসপাতালের কাছে',
    'রাতের অন্ধকার',
    'জরুরি সমাধান প্রয়োজন',
  ];

  static const Map<String, int> riskFactorWeights = {
    'দুর্ঘটনার আশঙ্কা': 2,
    'জীবনহানির সম্ভাবনা': 3,
    'ব্যস্ত সড়ক': 2,
    'স্কুল/হাসপাতালের কাছে': 2,
    'রাতের অন্ধকার': 1,
    'জরুরি সমাধান প্রয়োজন': 2,
  };

  static int calculateBaseScore(String category) {
    final catLower = category.toLowerCase();
    for (final entry in baseCategoryScores.entries) {
      if (catLower.contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    return 0;
  }

  static int calculateTotalScore(String category, List<String> selectedFactors) {
    int base = calculateBaseScore(category);
    int factorSum = 0;
    for (final factor in selectedFactors) {
      factorSum += riskFactorWeights[factor] ?? 0;
    }
    int total = base + factorSum;
    return total.clamp(0, 14);
  }

  static ReportSeverity determineSeverity(int score) {
    if (score >= 10) return ReportSeverity.critical;
    if (score >= 7) return ReportSeverity.high;
    if (score >= 4) return ReportSeverity.medium;
    return ReportSeverity.low;
  }
}

class ReportModel {
  final String id;
  final String title;
  final String userId;
  final String imagePath;
  final String? videoUrl;
  final String category;
  final double confidence;
  final double latitude;
  final double longitude;
  final String address;
  final String description;
  final VerificationStatus verificationStatus;
  final ReportStatus status;
  final ReportSeverity severity;
  final int riskScore;
  final List<String> riskFactors;
  final String priority;
  final String? assignedDepartment;
  final String? assignedArea;
  final String? assignedTeam;
  final String? adminComment;
  final String? officerComment;
  final String? delayReason;
  final String? proofBeforeUrl;
  final String? proofAfterUrl;
  final List<ActivityLogModel> activityLogs;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReportModel({
    required this.id,
    this.title = '',
    required this.userId,
    required this.imagePath,
    this.videoUrl,
    required this.category,
    required this.confidence,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.description,
    this.verificationStatus = VerificationStatus.needsReview,
    required this.status,
    this.severity = ReportSeverity.low,
    this.riskScore = 0,
    this.riskFactors = const [],
    this.priority = 'LOW',
    this.assignedDepartment,
    this.assignedArea,
    this.assignedTeam,
    this.adminComment,
    this.officerComment,
    this.delayReason,
    this.proofBeforeUrl,
    this.proofAfterUrl,
    this.activityLogs = const [],
    required this.createdAt,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? createdAt;

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    final docId = json['id'] as String? ?? json['\$id'] as String? ?? 'rep_${DateTime.now().millisecondsSinceEpoch}';
    String imgUrl = json['imageUrl'] as String? ?? json['imagePath'] as String? ?? json['image'] as String? ?? '';
    final imageId = json['imageId'] as String? ?? json['fileId'] as String?;
    if ((imgUrl.isEmpty || (!imgUrl.startsWith('http') && !imgUrl.startsWith('blob:') && !imgUrl.startsWith('/'))) && imageId != null && imageId.isNotEmpty) {
      imgUrl = 'https://sgp.cloud.appwrite.io/v1/storage/buckets/6a99219d002f23752a34/files/$imageId/view?project=6a991b46001c1972b134';
    }
    final rawDate = json['createdAt'] as String? ?? json['\$createdAt'] as String? ?? DateTime.now().toIso8601String();
    final rawUpdatedDate = json['updatedAt'] as String? ?? rawDate;
    final rawCategory = json['category'] as String?;
    final cat = AiService.normalizeCategory(rawCategory);

    final rawFactors = (json['riskFactors'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final rawScore = (json['riskScore'] as num?)?.toInt();
    final calculatedScore = rawScore ?? RiskEngine.calculateTotalScore(cat, rawFactors);

    final rawSeverity = json['severity'] as String?;
    final calculatedSeverity = rawSeverity != null
        ? ReportSeverityExtension.fromCode(rawSeverity)
        : RiskEngine.determineSeverity(calculatedScore);

    final rawPriority = json['priority'] as String? ?? calculatedSeverity.code;
    final rawVerif = json['verificationStatus'] as String? ?? 'NEEDS_REVIEW';

    final logsJson = json['activityLogs'] as List?;
    final logsList = logsJson != null
        ? logsJson.map((e) => ActivityLogModel.fromJson(Map<String, dynamic>.from(e))).toList()
        : <ActivityLogModel>[];

    final defaultTitle = json['title'] as String? ?? '$cat - ${json['address'] as String? ?? "ঢাকা"}';

    return ReportModel(
      id: docId,
      title: defaultTitle,
      userId: json['userId'] as String? ?? json['submittedBy'] as String? ?? 'user_1',
      imagePath: imgUrl,
      videoUrl: json['videoUrl'] as String?,
      category: cat,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 23.8103,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 90.4125,
      address: json['address'] as String? ?? json['location'] as String? ?? 'ঢাকা, বাংলাদেশ',
      description: json['description'] as String? ?? '',
      verificationStatus: VerificationStatusExtension.fromCode(rawVerif),
      status: ReportStatusExtension.fromCode(json['status'] as String? ?? json['currentStatus'] as String? ?? 'NEW_REPORT'),
      severity: calculatedSeverity,
      riskScore: calculatedScore,
      riskFactors: rawFactors,
      priority: rawPriority,
      assignedDepartment: json['assignedDepartment'] as String?,
      assignedArea: json['assignedArea'] as String?,
      assignedTeam: json['assignedTeam'] as String?,
      adminComment: json['adminComment'] as String?,
      officerComment: json['officerComment'] as String?,
      delayReason: json['delayReason'] as String?,
      proofBeforeUrl: json['proofBeforeUrl'] as String?,
      proofAfterUrl: json['proofAfterUrl'] as String?,
      activityLogs: logsList,
      createdAt: DateTime.tryParse(rawDate) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(rawUpdatedDate) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'userId': userId,
      'submittedBy': userId,
      'imagePath': imagePath,
      'imageUrl': imagePath,
      'videoUrl': videoUrl,
      'category': category,
      'confidence': confidence,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'location': address,
      'description': description,
      'verificationStatus': verificationStatus.code,
      'status': status.code,
      'currentStatus': status.code,
      'severity': severity.code,
      'riskScore': riskScore,
      'riskFactors': riskFactors,
      'priority': priority,
      'assignedDepartment': assignedDepartment,
      'assignedArea': assignedArea,
      'assignedTeam': assignedTeam,
      'adminComment': adminComment,
      'officerComment': officerComment,
      'delayReason': delayReason,
      'proofBeforeUrl': proofBeforeUrl,
      'proofAfterUrl': proofAfterUrl,
      'activityLogs': activityLogs.map((l) => l.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ReportModel copyWith({
    String? id,
    String? title,
    String? userId,
    String? imagePath,
    String? videoUrl,
    String? category,
    double? confidence,
    double? latitude,
    double? longitude,
    String? address,
    String? description,
    VerificationStatus? verificationStatus,
    ReportStatus? status,
    ReportSeverity? severity,
    int? riskScore,
    List<String>? riskFactors,
    String? priority,
    String? assignedDepartment,
    String? assignedArea,
    String? assignedTeam,
    String? adminComment,
    String? officerComment,
    String? delayReason,
    String? proofBeforeUrl,
    String? proofAfterUrl,
    List<ActivityLogModel>? activityLogs,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReportModel(
      id: id ?? this.id,
      title: title ?? this.title,
      userId: userId ?? this.userId,
      imagePath: imagePath ?? this.imagePath,
      videoUrl: videoUrl ?? this.videoUrl,
      category: category ?? this.category,
      confidence: confidence ?? this.confidence,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      description: description ?? this.description,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      status: status ?? this.status,
      severity: severity ?? this.severity,
      riskScore: riskScore ?? this.riskScore,
      riskFactors: riskFactors ?? this.riskFactors,
      priority: priority ?? this.priority,
      assignedDepartment: assignedDepartment ?? this.assignedDepartment,
      assignedArea: assignedArea ?? this.assignedArea,
      assignedTeam: assignedTeam ?? this.assignedTeam,
      adminComment: adminComment ?? this.adminComment,
      officerComment: officerComment ?? this.officerComment,
      delayReason: delayReason ?? this.delayReason,
      proofBeforeUrl: proofBeforeUrl ?? this.proofBeforeUrl,
      proofAfterUrl: proofAfterUrl ?? this.proofAfterUrl,
      activityLogs: activityLogs ?? this.activityLogs,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
