/// Cognitive Performance Metrics for AI Adaptive Scaling
class CognitiveMetric {
  final int? id;
  final String
      gameType; // "MEMORY_MATCH", "OBJECT_RECOGNITION", "ROUTINE_SEQUENCE"
  final int timestamp;
  final int gridDimension; // 2 for 2x2, 3 for 2x3
  final int totalMoves;
  final int errorCount;
  final int completionTimeSeconds;
  final double tremorJitterScore; // Measure of misclicks / erratic touches
  final double calculatedScore; // 0.0 to 100.0
  final int recommendedGridSize;
  final bool isSynced;
  final String serverSessionId;

  const CognitiveMetric({
    this.id,
    required this.gameType,
    required this.timestamp,
    required this.gridDimension,
    required this.totalMoves,
    required this.errorCount,
    required this.completionTimeSeconds,
    required this.tremorJitterScore,
    required this.calculatedScore,
    required this.recommendedGridSize,
    this.isSynced = false,
    this.serverSessionId = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'gameType': gameType,
      'timestamp': timestamp,
      'gridDimension': gridDimension,
      'totalMoves': totalMoves,
      'errorCount': errorCount,
      'completionTimeSeconds': completionTimeSeconds,
      'tremorJitterScore': tremorJitterScore,
      'calculatedScore': calculatedScore,
      'recommendedGridSize': recommendedGridSize,
      'isSynced': isSynced ? 1 : 0,
      'serverSessionId': serverSessionId,
    };
  }

  factory CognitiveMetric.fromMap(Map<String, dynamic> map) {
    return CognitiveMetric(
      id: map['id'] as int?,
      gameType: map['gameType'] as String,
      timestamp: map['timestamp'] as int,
      gridDimension: map['gridDimension'] as int,
      totalMoves: map['totalMoves'] as int,
      errorCount: map['errorCount'] as int,
      completionTimeSeconds: map['completionTimeSeconds'] as int,
      tremorJitterScore: (map['tremorJitterScore'] as num).toDouble(),
      calculatedScore: (map['calculatedScore'] as num).toDouble(),
      recommendedGridSize: map['recommendedGridSize'] as int,
      isSynced: (map['isSynced'] as int? ?? 0) == 1,
      serverSessionId: (map['serverSessionId'] as String?) ?? '',
    );
  }
}

/// Offline-First Sync Queue Item
class SyncQueueItem {
  final int? queueId;
  final String eventType;
  final String payloadJson;
  final int createdAt;
  final int syncAttempts;
  final bool isSynced;

  const SyncQueueItem({
    this.queueId,
    required this.eventType,
    required this.payloadJson,
    required this.createdAt,
    this.syncAttempts = 0,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'queueId': queueId,
      'eventType': eventType,
      'payloadJson': payloadJson,
      'createdAt': createdAt,
      'syncAttempts': syncAttempts,
      'isSynced': isSynced ? 1 : 0,
    };
  }

  factory SyncQueueItem.fromMap(Map<String, dynamic> map) {
    return SyncQueueItem(
      queueId: map['queueId'] as int?,
      eventType: map['eventType'] as String,
      payloadJson: map['payloadJson'] as String,
      createdAt: map['createdAt'] as int,
      syncAttempts: map['syncAttempts'] as int,
      isSynced: (map['isSynced'] as int) == 1,
    );
  }
}
