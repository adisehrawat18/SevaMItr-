import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dementia_ner_care/core/theme/dementia_theme.dart';
import 'package:dementia_ner_care/ui/screens/caregiver/add_memory_capsule_dialog.dart';
import 'package:dementia_ner_care/core/localization/app_localizations.dart';
import 'package:dementia_ner_care/data/services/sevamitr_sync_service.dart';
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

  @override
  void initState() {
    super.initState();
    _syncService.addListener(_onSyncUpdate);
    _syncService.refreshLocalState();
  }

  @override
  void dispose() {
    _syncService.removeListener(_onSyncUpdate);
    super.dispose();
  }

  void _onSyncUpdate() {
    if (mounted) setState(() {});
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
                Text(
                  context.tr('caregiver_title'),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
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

          // SevaMitr Cloud Sync & 2G Edge Connectivity Card
          _buildSevaMitrSyncCard(),
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

          // Live Cognitive Stability Index & Sundowning Analytics Card
          _buildCognitiveAnalyticsCard(analytics),
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

  Widget _buildCognitiveAnalyticsCard(ServerAnalytics? analytics) {
    final dci = analytics?.overallDci?.toInt() ?? 78;
    final sessionsCount = analytics?.sessionsCount ?? 12;
    final sundowningDetected = analytics?.sundowningDetected ?? false;
    final divergencePct = analytics?.latencyDivergencePct ?? 0;
    final recommendation = analytics?.sundowningRecommendation ??
        "Maintain calming daily routines and provide soft warm lighting before evening activities.";
    final motorStatus = analytics?.motorStatus ?? "fluid";
    final tremorScore = analytics?.motorHesitationScore ?? 2.8;

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
                  "$sessionsCount sessions",
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
                "$dci",
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
                  color: dci >= 75
                      ? DementiaColors.actionGreenLight
                      : DementiaColors.alertTerracottaBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: dci >= 75
                        ? DementiaColors.actionForestGreen
                        : DementiaColors.alertTerracotta,
                  ),
                ),
                child: Text(
                  dci >= 75 ? "Cognitively Stable" : "Mild Agitation Risk",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: dci >= 75
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
          _buildDomainBar("🧠 Memory (Smriti Setu)", analytics?.memoryScore ?? 85.0),
          _buildDomainBar("🎯 Attention (Rang & Tanti)", analytics?.attentionScore ?? 80.0),
          _buildDomainBar("⚡ Executive (Doharani)", analytics?.executiveScore ?? 78.0),
          _buildDomainBar("👂 Auditory (Shabda Tarang)", analytics?.auditoryScore ?? 75.0),
          _buildDomainBar("🛒 Market Math (Bazaar Saathi)", analytics?.mathScore ?? 72.0),

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
