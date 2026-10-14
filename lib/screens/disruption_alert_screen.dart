import 'package:flutter/material.dart';
import '../models/disruption_alert.dart';
import '../services/transit_data_service.dart';
import '../theme/tokens.dart';

/// DisruptionAlertScreen — Minimal, calm, easy-to-scan transit alerts.
///
/// Features:
/// - Clean, uncluttered header titled "Alerts".
/// - Restrained cards showing affected route, severity, summary, time, and action.
/// - Polished states: Loading, No Alerts, Alerts Available, and Network Notice.
/// - Single clear action ("View details" / "Find alternatives") via bottom sheet.
class DisruptionAlertScreen extends StatefulWidget {
  const DisruptionAlertScreen({super.key});

  @override
  State<DisruptionAlertScreen> createState() => _DisruptionAlertScreenState();
}

class _DisruptionAlertScreenState extends State<DisruptionAlertScreen> {
  List<DisruptionAlert> _alerts = [];
  bool _isLoading = true;
  bool _isFromFallback = false;
  String? _blockerDetail;

  @override
  void initState() {
    super.initState();
    _checkDisruptions();
  }

  Future<void> _checkDisruptions() async {
    setState(() => _isLoading = true);
    final response = await TransitDataService.instance
        .checkDisruptionsAndRecoveryAsync();
    if (mounted) {
      setState(() {
        _isLoading = false;
        _alerts =
            response.data ?? TransitDataService.instance.getActiveAlerts();
        _isFromFallback = response.isFromFallback;
        _blockerDetail = response.blockerDetail;
      });
    }
  }

  void _showAlertDetails(DisruptionAlert alert) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: SafarTokens.mutedSage.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: alert.severity.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        alert.severity.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: alert.severity.color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        alert.affectedService,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: SafarTokens.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  alert.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: SafarTokens.deepCharcoal,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  alert.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: SafarTokens.deepCharcoal,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: SafarTokens.softMint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.alt_route_rounded,
                        color: SafarTokens.transitGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Commuter Guidance',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: SafarTokens.transitGreen,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              alert.commuterImpact,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: SafarTokens.deepCharcoal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  alert.lastUpdatedText,
                  style: const TextStyle(
                    fontSize: 11,
                    color: SafarTokens.textMuted,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: SafarTokens.background,
      appBar: AppBar(
        backgroundColor: SafarTokens.background,
        elevation: 0,
        leading: canPop
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: SafarTokens.deepCharcoal,
                ),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: const Text(
          'Alerts',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: SafarTokens.deepCharcoal,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: SafarTokens.deepCharcoal,
            ),
            tooltip: 'Refresh alerts',
            onPressed: _checkDisruptions,
          ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    // 1. Loading State
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: SafarTokens.transitGreen,
                ),
              ),
              SizedBox(height: 14),
              Text(
                'Checking transit alerts...',
                style: TextStyle(fontSize: 13, color: SafarTokens.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    // 2. Empty State (No Disruptions)
    if (_alerts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: SafarTokens.softMint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 32,
                  color: SafarTokens.transitGreen,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'All services normal',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: SafarTokens.deepCharcoal,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'No disruptions reported across Chennai Metro, Suburban, or MRTS networks.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: SafarTokens.textMuted,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 3. Alerts Available State (Clean, restrained card list)
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // Subtitle Context
        const Padding(
          padding: EdgeInsets.only(left: 2, bottom: 12),
          child: Text(
            'Active Chennai service notices',
            style: TextStyle(
              fontSize: 12.5,
              color: SafarTokens.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // Alert Items
        ..._alerts.map(
          (alert) => Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _AlertCard(
              alert: alert,
              onTapAction: () => _showAlertDetails(alert),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Restrained Footnote
        if (_isFromFallback)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 13,
                  color: SafarTokens.textMuted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _blockerDetail != null
                        ? 'Timetable estimates • Offline schedule active'
                        : 'Notices based on Southern Railway & CMRL schedule updates',
                    style: const TextStyle(
                      fontSize: 11,
                      color: SafarTokens.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Simple, elegant alert card
class _AlertCard extends StatelessWidget {
  final DisruptionAlert alert;
  final VoidCallback onTapAction;

  const _AlertCard({required this.alert, required this.onTapAction});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(SafarTokens.radiusM),
        border: Border.all(color: SafarTokens.mutedSage.withValues(alpha: 0.5)),
        boxShadow: const [SafarTokens.cardSoftShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Route + Severity Indicator
          Row(
            children: [
              Expanded(
                child: Text(
                  alert.affectedService,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: SafarTokens.deepCharcoal,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: alert.severity.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  alert.severity.label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: alert.severity.color,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Disruption Title
          Text(
            alert.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: SafarTokens.deepCharcoal,
            ),
          ),

          const SizedBox(height: 4),

          // Short Disruption Summary
          Text(
            alert.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: SafarTokens.textMuted,
              height: 1.35,
            ),
          ),

          const SizedBox(height: 10),

          // Footer Row: Timestamp + Action Link
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  alert.lastUpdatedText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: SafarTokens.textMuted,
                  ),
                ),
              ),
              InkWell(
                onTap: onTapAction,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        alert.alternativeActionLabel != null
                            ? 'Alternatives'
                            : 'Details',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: SafarTokens.transitGreen,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 14,
                        color: SafarTokens.transitGreen,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
