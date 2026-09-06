import 'dart:convert';

/// Analytics Model mirroring SevaMitr Cloud / Central Registry
/// Stores Dynamic Cognitive Index (DCI), domain breakdowns, and sundowning divergence.
class ServerAnalytics {
  final String patientId;
  final double? overallDci;
  final int sessionsCount;
  final Map<String, double> domainScores;
  final bool sundowningDetected;
  final bool sundowningHasData;
  final double latencyDivergencePct;
  final String sundowningRecommendation;
  final double motorHesitationScore;
  final String motorStatus;
  final int lastSyncedTimestamp;
  final String rawJson;

  const ServerAnalytics({
    required this.patientId,
    this.overallDci,
    required this.sessionsCount,
    required this.domainScores,
    required this.sundowningDetected,
    required this.sundowningHasData,
    required this.latencyDivergencePct,
    required this.sundowningRecommendation,
    required this.motorHesitationScore,
    required this.motorStatus,
    required this.lastSyncedTimestamp,
    this.rawJson = '',
  });

  double get memoryScore => domainScores['memory'] ?? 0.0;
  double get executiveScore => domainScores['executive'] ?? 0.0;
  double get attentionScore => domainScores['attention'] ?? 0.0;
  double get auditoryScore => domainScores['auditory'] ?? 0.0;
  double get mathScore => domainScores['math'] ?? 0.0;

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'overallDci': overallDci,
      'sessionsCount': sessionsCount,
      'memoryScore': memoryScore,
      'executiveScore': executiveScore,
      'attentionScore': attentionScore,
      'auditoryScore': auditoryScore,
      'mathScore': mathScore,
      'sundowningDetected': sundowningDetected ? 1 : 0,
      'sundowningHasData': sundowningHasData ? 1 : 0,
      'latencyDivergencePct': latencyDivergencePct,
      'sundowningRecommendation': sundowningRecommendation,
      'motorHesitationScore': motorHesitationScore,
      'motorStatus': motorStatus,
      'lastSyncedTimestamp': lastSyncedTimestamp,
      'rawJson': rawJson,
    };
  }

  factory ServerAnalytics.fromMap(Map<String, dynamic> map) {
    return ServerAnalytics(
      patientId: (map['patientId'] as String?) ?? 'patient-ner-001',
      overallDci: map['overallDci'] != null ? (map['overallDci'] as num).toDouble() : null,
      sessionsCount: (map['sessionsCount'] as int?) ?? 0,
      domainScores: {
        'memory': ((map['memoryScore'] ?? 0) as num).toDouble(),
        'executive': ((map['executiveScore'] ?? 0) as num).toDouble(),
        'attention': ((map['attentionScore'] ?? 0) as num).toDouble(),
        'auditory': ((map['auditoryScore'] ?? 0) as num).toDouble(),
        'math': ((map['mathScore'] ?? 0) as num).toDouble(),
      },
      sundowningDetected: (map['sundowningDetected'] as int? ?? 0) == 1,
      sundowningHasData: (map['sundowningHasData'] as int? ?? 0) == 1,
      latencyDivergencePct: ((map['latencyDivergencePct'] ?? 0.0) as num).toDouble(),
      sundowningRecommendation: (map['sundowningRecommendation'] as String?) ?? '',
      motorHesitationScore: ((map['motorHesitationScore'] ?? 0.0) as num).toDouble(),
      motorStatus: (map['motorStatus'] as String?) ?? 'pending',
      lastSyncedTimestamp: (map['lastSyncedTimestamp'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      rawJson: (map['rawJson'] as String?) ?? '',
    );
  }

  factory ServerAnalytics.fromJson(Map<String, dynamic> json, {String? defaultPatientId}) {
    final patientId = (json['patientId'] as String?) ?? defaultPatientId ?? 'patient-ner-001';
    final analysis = (json['analysis'] as Map?)?.cast<String, dynamic>() ?? {};

    final overallDci = analysis['overallDci'] != null
        ? (analysis['overallDci'] as num).toDouble()
        : null;
    final sessionsCount = (analysis['sessionsCount'] as int?) ??
        (json['totalSessionsRecorded'] as int?) ?? 0;

    final domainMap = (analysis['domainScores'] as Map?)?.cast<String, dynamic>() ?? {};
    final domainScores = {
      'memory': ((domainMap['memory'] ?? 0) as num).toDouble(),
      'executive': ((domainMap['executive'] ?? 0) as num).toDouble(),
      'attention': ((domainMap['attention'] ?? 0) as num).toDouble(),
      'auditory': ((domainMap['auditory'] ?? 0) as num).toDouble(),
      'math': ((domainMap['math'] ?? 0) as num).toDouble(),
    };

    final sundowning = (analysis['sundowning'] as Map?)?.cast<String, dynamic>() ?? {};
    final sundowningDetected = sundowning['detected'] == true;
    final sundowningHasData = sundowning['hasEnoughData'] == true;
    final latencyDivergencePct = ((sundowning['latencyDivergencePct'] ?? 0) as num).toDouble();
    final sundowningRecommendation = (sundowning['recommendation'] as String?) ?? '';

    final motor = (analysis['motorHesitation'] as Map?)?.cast<String, dynamic>() ?? {};
    final motorScore = ((motor['tremorHesitationScore'] ?? 0) as num).toDouble();
    final motorStatus = (motor['status'] as String?) ?? 'pending';


    return ServerAnalytics(
      patientId: patientId,
      overallDci: overallDci,
      sessionsCount: sessionsCount,
      domainScores: domainScores,
      sundowningDetected: sundowningDetected,
      sundowningHasData: sundowningHasData,
      latencyDivergencePct: latencyDivergencePct,
      sundowningRecommendation: sundowningRecommendation,
      motorHesitationScore: motorScore,
      motorStatus: motorStatus,
      lastSyncedTimestamp: (json['timestamp'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      rawJson: jsonEncode(json),
    );
  }
}
