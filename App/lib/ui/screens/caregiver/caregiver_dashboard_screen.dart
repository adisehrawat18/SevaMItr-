import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dementia_ner_care/core/theme/dementia_theme.dart';
import 'package:dementia_ner_care/ui/screens/caregiver/add_memory_capsule_dialog.dart';
import 'package:dementia_ner_care/ui/screens/caregiver/caregiver_auth_dialog.dart';
import 'package:dementia_ner_care/core/localization/app_localizations.dart';
import 'package:dementia_ner_care/data/services/sevamitr_sync_service.dart';
import 'package:dementia_ner_care/data/services/caregiver_auth_service.dart';
import 'package:dementia_ner_care/data/database/offline_database.dart';
import 'package:dementia_ner_care/data/models/cognitive_metric_model.dart';
import 'package:dementia_ner_care/data/models/server_analytics_model.dart';

/// Caregiver Portal Dashboard
/// Connected with SevaMitr Cloud & Central Health Registry
class CaregiverDashboardScreen extends StatefulWidget {
  final VoidCallback onExitCaregiverMode;
  final VoidCallback onEditPatientDetails;

  const CaregiverDashboardScreen({
    super.key,
    required this.onExitCaregiverMode,
    required this.onEditPatientDetails,
  });

  @override
  State<CaregiverDashboardScreen> createState() =>
      _CaregiverDashboardScreenState();
}

class _CaregiverDashboardScreenState extends State<CaregiverDashboardScreen> {
  int _capsuleCount = 2;
  final _syncService = SevaMitrSyncService.instance;
  final _authService = CaregiverAuthService.instance;
  List<CognitiveMetric> _recentMetrics = [];
  bool _isLoadingMetrics = true;

  @override
  void initState() {
    super.initState();
    _syncService.addListener(_onSyncUpdate);
    _authService.addListener(_onSyncUpdate);
    _syncService.refreshLocalState();
    _loadRecentMetrics();
  }

  @override
  void dispose() {
    _syncService.removeListener(_onSyncUpdate);
    _authService.removeListener(_onSyncUpdate);
    super.dispose();
  }

  void _onSyncUpdate() {
    if (mounted) {
      _loadRecentMetrics();
      setState(() {});
    }
  }

  Future<void> _loadRecentMetrics() async {
    try {
      final list = await OfflineDatabase.instance.getRecentMetrics();
      if (mounted) {
        setState(() {
          _recentMetrics = list;
          _isLoadingMetrics = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading recent metrics: $e');
    }
  }

  void _showAddCapsuleDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AddMemoryCapsuleDialog(
        onCapsuleAdded: () {
          setState(() => _capsuleCount++);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('memory_saved')),
              backgroundColor: DementiaColors.actionForestGreen,
            ),
          );
        },
      ),
    );
  }

  void _showServerConfigDialog() {
    final controller = TextEditingController(text: _syncService.serverBaseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DementiaColors.canvasWarmCream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.dns, color: DementiaColors.textPrimaryDark),
            SizedBox(width: 8),
            Text(
              "SevaMitr Server Config",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: DementiaColors.textPrimaryDark,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Enter the SevaMitr backend URL to sync patient telemetry and fetch central cognitive analytics:",
              style: TextStyle(fontSize: 13, color: DementiaColors.textSecondaryDark),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: "http://10.0.2.2:3000",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ActionChip(
                  backgroundColor: DementiaColors.actionGreenLight,
                  avatar: const Icon(Icons.cloud_done, size: 14, color: DementiaColors.actionForestGreen),
                  label: const Text("Production (seva-mitr.vercel.app)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () => controller.text = "https://seva-mitr.vercel.app",
                ),
                ActionChip(
                  label: const Text("Localhost (3000)", style: TextStyle(fontSize: 11)),
                  onPressed: () => controller.text = "http://localhost:3000",
                ),
                ActionChip(
                  label: const Text("Emulator (10.0.2.2:3000)", style: TextStyle(fontSize: 11)),
                  onPressed: () => controller.text = "http://10.0.2.2:3000",
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel", style: TextStyle(color: DementiaColors.textSecondaryDark)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: DementiaColors.actionForestGreen,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final newUrl = controller.text.trim();
              if (newUrl.isNotEmpty) {
                await _syncService.setServerBaseUrl(newUrl);
                await _syncService.checkConnectivity();
              }
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text("Save & Test"),
          ),
        ],
      ),
    );
  }

  Future<void> _triggerManualSync() async {
    final result = await _syncService.syncAll();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success
            ? DementiaColors.actionForestGreen
            : (result.isOffline ? DementiaColors.ochreWarmAmber : DementiaColors.alertTerracotta),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final analytics = _syncService.latestAnalytics;

    return Scaffold(
      backgroundColor: DementiaColors.canvasWarmCream,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: Container(
          color: DementiaColors.caregiverShieldGold,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          child: SafeArea(
            bottom: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white70, width: 2),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      context.tr('caregiver_title'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: widget.onExitCaregiverMode,
                ),
              ],
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton.icon(
            onPressed: widget.onEditPatientDetails,
            style: ElevatedButton.styleFrom(
              backgroundColor: DementiaColors.voiceAssistanceBlue,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.manage_accounts),
            label: const Text(
              'Edit patient and family contact details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),

          // Caregiver Cloud Account & Authentication Card (Phone + Password)
          _buildCaregiverAuthCard(),
          const SizedBox(height: 16),

          // SevaMitr Cloud Sync & 2G Edge Connectivity Card
          _buildSevaMitrSyncCard(),
          const SizedBox(height: 16),

          // Live Cognitive Stability Index & Sundowning Analytics Card
          _buildCognitiveAnalyticsCard(analytics),
          const SizedBox(height: 16),

          // Recent Game Sessions & Speed Trials Feed (All 11 Games)
          _buildRecentGameSessionsCard(),
          const SizedBox(height: 16),

          // Weekly Medication Adherence Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: DementiaColors.actionGreenLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: DementiaColors.actionForestGreen, width: 2),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Weekly Medication Adherence",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: DementiaColors.actionForestGreen),
                ),
                SizedBox(height: 6),
                Text(
                  "92% (13/14 Doses Taken on Time)",
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: DementiaColors.textPrimaryDark),
                ),
                Text(
                  "Average response time: 4.2 mins post-alert",
                  style: TextStyle(
                      fontSize: 14, color: DementiaColors.textSecondaryDark),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Memory Capsule Management Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: DementiaColors.alertTerracottaBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: DementiaColors.alertTerracotta, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.photo_library,
                        color: DementiaColors.alertTerracotta, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      context.tr('memory_capsule'),
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: DementiaColors.alertTerracotta),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "$_capsuleCount Active Photo Stories loaded for patient reminiscence sessions.",
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: DementiaColors.textPrimaryDark),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _showAddCapsuleDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DementiaColors.alertTerracotta,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add_a_photo),
                  label: Text(context.tr('add_memory_capsule'),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSevaMitrSyncCard() {
    final isSyncing = _syncService.isSyncing;
    final isOnline = _syncService.isOnline;
    final unsynced = _syncService.unsyncedCount;
    final lastSync = _syncService.lastSyncTime;

    final statusColor = isSyncing
        ? DementiaColors.voiceAssistanceBlue
        : (isOnline
            ? (unsynced == 0 ? DementiaColors.actionForestGreen : DementiaColors.ochreWarmAmber)
            : DementiaColors.alertTerracotta);

    final statusText = isSyncing
        ? "Syncing with SevaMitr Cloud..."
        : (isOnline
            ? (unsynced == 0 ? "Cloud Synced • NER Health Registry Connected" : "$unsynced sessions queued for 2G sync")
            : "Offline Mode • Data Stored Safely on Device");

    final lastSyncText = lastSync != null
        ? "Last sync: ${DateFormat('h:mm a, d MMM').format(lastSync)}"
        : "Not synced yet";

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DementiaColors.surfaceCardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              isSyncing
                  ? const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
                  : Icon(
                      isOnline ? Icons.cloud_done : Icons.cloud_off,
                      color: statusColor,
                      size: 32,
                    ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "SevaMitr Cloud Synchronization",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    Text(
                      statusText,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: DementiaColors.textPrimaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings, size: 22, color: DementiaColors.textSecondaryDark),
                tooltip: "Configure Server URL",
                onPressed: _showServerConfigDialog,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: DementiaColors.dividerColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    "Host: ${_syncService.serverBaseUrl}",
                    style: const TextStyle(fontSize: 12, color: DementiaColors.textSecondaryDark),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  lastSyncText,
                  style: const TextStyle(fontSize: 12, color: DementiaColors.textSecondaryDark),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: isSyncing ? null : _triggerManualSync,
            style: ElevatedButton.styleFrom(
              backgroundColor: DementiaColors.actionForestGreen,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: isSyncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.sync, size: 20),
            label: Text(
              isSyncing ? "Syncing in background..." : "Sync Now (2G Micro-Batch)",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaregiverAuthCard() {
    final isLoggedIn = _authService.isLoggedIn;
    final name = _authService.caregiverName.isNotEmpty
        ? _authService.caregiverName
        : 'Registered Caregiver';
    final ident = _authService.caregiverPhone;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isLoggedIn ? DementiaColors.actionGreenLight : DementiaColors.ochreBadgeBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLoggedIn ? DementiaColors.actionForestGreen : DementiaColors.ochreWarmAmber,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isLoggedIn ? DementiaColors.actionForestGreen : DementiaColors.ochreWarmAmber,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isLoggedIn ? Icons.verified_user : Icons.lock_outline,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLoggedIn ? name : "Link SevaMitr Cloud Account",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: DementiaColors.textPrimaryDark,
                      ),
                    ),
                    Text(
                      isLoggedIn
                          ? "Phone: $ident • Central DB Scoped"
                          : "Enter Phone & Password to sync with seva-mitr.vercel.app",
                      style: const TextStyle(
                        fontSize: 13,
                        color: DementiaColors.textSecondaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!isLoggedIn) ...[
            ElevatedButton.icon(
              onPressed: () => CaregiverAuthDialog.show(context, onAuthSuccess: () {
                _loadRecentMetrics();
                setState(() {});
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: DementiaColors.actionForestGreen,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.login, size: 20),
              label: const Text(
                "Sign In / Register with Phone & Password",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => CaregiverAuthDialog.show(context, onAuthSuccess: () {
                      _loadRecentMetrics();
                      setState(() {});
                    }),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: DementiaColors.actionForestGreen),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: const Icon(Icons.switch_account, size: 18, color: DementiaColors.actionForestGreen),
                    label: const Text(
                      "Switch Account",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: DementiaColors.actionForestGreen),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    await _authService.logout();
                    if (mounted) setState(() {});
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: DementiaColors.alertTerracotta),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  ),
                  icon: const Icon(Icons.logout, size: 18, color: DementiaColors.alertTerracotta),
                  label: const Text(
                    "Sign Out",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: DementiaColors.alertTerracotta),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  double _getLiveDomainScore(List<String> gameTypes, double fallbackScore) {
    final matches = _recentMetrics
        .where((m) => gameTypes.contains(m.gameType.toUpperCase()))
        .toList();
    if (matches.isEmpty) return fallbackScore;
    final total = matches.fold<double>(0.0, (acc, m) => acc + m.calculatedScore);
    return (total / matches.length).clamp(30.0, 100.0);
  }

  Widget _buildCognitiveAnalyticsCard(ServerAnalytics? analytics) {
    final sundowningDetected = analytics?.sundowningDetected ?? false;
    final divergencePct = analytics?.latencyDivergencePct ?? 0;
    final recommendation = analytics?.sundowningRecommendation ??
        "Maintain calming daily routines and provide soft warm lighting before evening activities.";
    final motorStatus = analytics?.motorStatus ?? "fluid";
    final tremorScore = analytics?.motorHesitationScore ?? 2.8;

    // Live domain scores reflecting both cloud data and all 11 local games
    final memScore = _getLiveDomainScore(
        ['MEMORY_MATCH', 'MEMORY_CAPSULE'], analytics?.memoryScore ?? 85.0);
    final attScore = _getLiveDomainScore(
        ['BIJULI_TAP', 'TARGET_TRACKER', 'DOUBLE_DECISION'],
        analytics?.attentionScore ?? 80.0);
    final execScore = _getLiveDomainScore(
        ['SPEED_MAZE', 'ROUTINE_SEQUENCE'], analytics?.executiveScore ?? 78.0);
    final audScore = _getLiveDomainScore(
        ['SOUND_SWEEPS'], analytics?.auditoryScore ?? 75.0);
    final visScore = _getLiveDomainScore(
        ['BIKHAMA_KHOJ', 'OBJECT_RECOGNITION'], 82.0);
    final langScore = _getLiveDomainScore(
        ['PROVERBS_WORD_ASSOC'], 78.0);

    final liveDci = ((memScore * 0.22) +
            (attScore * 0.22) +
            (execScore * 0.18) +
            (audScore * 0.14) +
            (visScore * 0.14) +
            (langScore * 0.10))
        .toInt()
        .clamp(30, 100);

    final displayDci = _recentMetrics.isNotEmpty ? liveDci : (analytics?.overallDci?.toInt() ?? 78);
    final totalSessions = _recentMetrics.isNotEmpty ? _recentMetrics.length : (analytics?.sessionsCount ?? 12);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DementiaColors.ochreBadgeBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DementiaColors.ochreWarmAmber, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Dynamic Cognitive Index (DCI)",
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: DementiaColors.ochreWarmAmber),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "$totalSessions sessions",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                "$displayDci",
                style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: DementiaColors.textPrimaryDark),
              ),
              const Text(
                " / 100",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: DementiaColors.textSecondaryDark),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: displayDci >= 75
                      ? DementiaColors.actionGreenLight
                      : DementiaColors.alertTerracottaBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: displayDci >= 75
                        ? DementiaColors.actionForestGreen
                        : DementiaColors.alertTerracotta,
                  ),
                ),
                child: Text(
                  displayDci >= 75 ? "Cognitively Stable" : "Mild Agitation Risk",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: displayDci >= 75
                        ? DementiaColors.actionForestGreen
                        : DementiaColors.alertTerracotta,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 5-Domain Cognitive Breakdown
          const Text(
            "5-Domain Cognitive Breakdown (SevaMitr Cloud)",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: DementiaColors.textPrimaryDark),
          ),
          const SizedBox(height: 8),
          _buildDomainBar("🧠 Memory (Smriti Setu)", memScore),
          _buildDomainBar("🎯 Attention (Rang & Tanti)", attScore),
          _buildDomainBar("⚡ Executive (Doharani)", execScore),
          _buildDomainBar("👂 Auditory (Shabda Tarang)", audScore),
          _buildDomainBar("🛒 Market Math (Bazaar Saathi)", analytics?.mathScore ?? 72.0),
          _buildDomainBar("🔍 Visual Search (Bikhama Khoj)", visScore),
          _buildDomainBar("📜 Language Recall (Proverbs)", langScore),

          const SizedBox(height: 14),

          // Sundowning Alert / Guidance
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: sundowningDetected
                  ? DementiaColors.alertTerracottaBg
                  : DementiaColors.actionGreenLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: sundowningDetected
                    ? DementiaColors.alertTerracotta
                    : DementiaColors.actionForestGreen,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      sundowningDetected ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                      color: sundowningDetected
                          ? DementiaColors.alertTerracotta
                          : DementiaColors.actionForestGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      sundowningDetected
                          ? "Sundowning Fatigue Detected (+${divergencePct.toInt()}% divergence)"
                          : "Circadian Rhythm Stable",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: sundowningDetected
                            ? DementiaColors.alertTerracotta
                            : DementiaColors.actionForestGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  recommendation,
                  style: const TextStyle(fontSize: 12, color: DementiaColors.textPrimaryDark),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Motor Hesitation Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Motor Hesitation: ${tremorScore.toStringAsFixed(1)} / 10",
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: DementiaColors.textPrimaryDark),
              ),
              Text(
                "Tremor Status: ${motorStatus.toUpperCase()}",
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: DementiaColors.textSecondaryDark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getGameMeta(String gameType) {
    switch (gameType.toUpperCase()) {
      case 'BIJULI_TAP':
        return {
          'title': 'Bijuli Tap (বিজুলী টেপ)',
          'domain': '⚡ Reaction & Inhibitory Control',
          'icon': Icons.flash_on,
          'color': const Color(0xFFD97706),
        };
      case 'BIKHAMA_KHOJ':
        return {
          'title': 'Bikhama Khoj (Visual Search)',
          'domain': '🔍 Visual Odd-One-Out',
          'icon': Icons.search,
          'color': const Color(0xFF0284C7),
        };
      case 'DOUBLE_DECISION':
        return {
          'title': 'Double Decision (দ্বৈত সিদ্ধান্ত)',
          'domain': '🎯 UFOV Dual Processing Speed',
          'icon': Icons.directions_car,
          'color': const Color(0xFF7C3AED),
        };
      case 'SOUND_SWEEPS':
        return {
          'title': 'Sound Sweeps (শব্দ তৰংগ)',
          'domain': '👂 Auditory Temporal Processing',
          'icon': Icons.graphic_eq,
          'color': const Color(0xFF0D9488),
        };
      case 'SPEED_MAZE':
        return {
          'title': 'Speed Maze (দ্ৰুত গোলকধাঁধাঁ)',
          'domain': '🧭 Executive Visuomotor Navigation',
          'icon': Icons.alt_route,
          'color': const Color(0xFF4F46E5),
        };
      case 'TARGET_TRACKER':
        return {
          'title': 'Target Tracker (লক্ষ্য অনুসৰণ)',
          'domain': '👀 Multiple Object Tracking',
          'icon': Icons.radar,
          'color': const Color(0xFFE11D48),
        };
      case 'MEMORY_MATCH':
        return {
          'title': 'Memory Match (স্মৃতি সেতু)',
          'domain': '🧠 Working Memory Matching',
          'icon': Icons.grid_view,
          'color': DementiaColors.actionForestGreen,
        };
      case 'OBJECT_RECOGNITION':
        return {
          'title': 'Object Recognition (বস্তু চিনাক্তকৰণ)',
          'domain': '🏷️ Visual Object Naming',
          'icon': Icons.inventory_2,
          'color': DementiaColors.voiceAssistanceBlue,
        };
      case 'ROUTINE_SEQUENCE':
        return {
          'title': 'Routine Sequence (পুৱাৰ নিয়ম)',
          'domain': '📋 Executive Planning Order',
          'icon': Icons.view_timeline,
          'color': DementiaColors.ochreWarmAmber,
        };
      case 'PROVERBS_WORD_ASSOC':
        return {
          'title': 'Proverbs Recall (ফকৰা যোজনা)',
          'domain': '📜 Language & Semantic Recall',
          'icon': Icons.auto_stories,
          'color': DementiaColors.alertTerracotta,
        };
      case 'MEMORY_CAPSULE':
        return {
          'title': 'Family Memory Capsule',
          'domain': '🖼️ Reminiscence Recall',
          'icon': Icons.photo_library,
          'color': DementiaColors.actionForestGreen,
        };
      default:
        return {
          'title': gameType.replaceAll('_', ' '),
          'domain': '🧠 Cognitive Performance',
          'icon': Icons.sports_esports,
          'color': DementiaColors.primaryKazirangaForest,
        };
    }
  }

  Widget _buildRecentGameSessionsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DementiaColors.borderCharcoal, width: 2),
        boxShadow: const [
          BoxShadow(
            color: DementiaColors.borderCharcoal,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.sports_esports, color: DementiaColors.primaryKazirangaForest, size: 24),
                  SizedBox(width: 8),
                  Text(
                    "Recent Game Sessions",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: DementiaColors.textPrimaryDark,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: DementiaColors.actionGreenLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${_recentMetrics.length} recorded",
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: DementiaColors.actionForestGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingMetrics) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            ),
          ] else if (_recentMetrics.isEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DementiaColors.paleSageBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: DementiaColors.borderSubtle),
              ),
              child: const Column(
                children: [
                  Icon(Icons.query_builder, size: 36, color: DementiaColors.textSecondaryDark),
                  SizedBox(height: 6),
                  Text(
                    "No sessions recorded yet",
                    style: TextStyle(fontWeight: FontWeight.bold, color: DementiaColors.textPrimaryDark),
                  ),
                  Text(
                    "Play any of the 11 cognitive games from the Games Hub to view clinical speed & accuracy biomarkers here.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: DementiaColors.textSecondaryDark),
                  ),
                ],
              ),
            ),
          ] else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentMetrics.length.clamp(0, 10),
              separatorBuilder: (_, __) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final m = _recentMetrics[index];
                final meta = _getGameMeta(m.gameType);
                final score = m.calculatedScore.toInt();
                final date = DateTime.fromMillisecondsSinceEpoch(m.timestamp);
                final timeStr = DateFormat('h:mm a, d MMM').format(date);
                final isSynced = m.isSynced;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: (meta['color'] as Color).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: meta['color'] as Color, width: 1.5),
                      ),
                      child: Icon(meta['icon'] as IconData, color: meta['color'] as Color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  meta['title'] as String,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: DementiaColors.textPrimaryDark,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: score >= 80
                                      ? DementiaColors.actionGreenLight
                                      : (score >= 60 ? DementiaColors.ochreBadgeBg : DementiaColors.alertTerracottaBg),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: score >= 80
                                        ? DementiaColors.actionForestGreen
                                        : (score >= 60 ? DementiaColors.ochreWarmAmber : DementiaColors.alertTerracotta),
                                  ),
                                ),
                                child: Text(
                                  "$score%",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: score >= 80
                                        ? DementiaColors.actionForestGreen
                                        : (score >= 60 ? DementiaColors.ochreWarmAmber : DementiaColors.alertTerracotta),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            meta['domain'] as String,
                            style: const TextStyle(fontSize: 11, color: DementiaColors.textSecondaryDark, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                "Duration: ${m.completionTimeSeconds}s • Moves: ${m.totalMoves}",
                                style: const TextStyle(fontSize: 11, color: DementiaColors.textSecondaryDark),
                              ),
                              const Spacer(),
                              Icon(
                                isSynced ? Icons.cloud_done : Icons.cloud_upload_outlined,
                                size: 14,
                                color: isSynced ? DementiaColors.actionForestGreen : DementiaColors.ochreWarmAmber,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isSynced ? "Synced" : "Queued 2G",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isSynced ? DementiaColors.actionForestGreen : DementiaColors.ochreWarmAmber,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                timeStr,
                                style: const TextStyle(fontSize: 10, color: DementiaColors.textSecondaryDark),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDomainBar(String label, double score) {
    final clamped = score.clamp(0.0, 100.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: DementiaColors.textPrimaryDark),
            ),
          ),
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: clamped / 100.0,
                minHeight: 10,
                backgroundColor: Colors.white,
                valueColor: AlwaysStoppedAnimation<Color>(
                  clamped >= 80
                      ? DementiaColors.actionForestGreen
                      : (clamped >= 60 ? DementiaColors.ochreWarmAmber : DementiaColors.alertTerracotta),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 32,
            child: Text(
              "${clamped.toInt()}%",
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

