import 'package:flutter/material.dart';
import '../models/journey.dart';
import '../models/transit_stop.dart';
import '../theme/tokens.dart';
import 'disruption_alert_screen.dart';

class JourneyDetailsScreen extends StatefulWidget {
  final Journey journey;

  const JourneyDetailsScreen({super.key, required this.journey});

  @override
  State<JourneyDetailsScreen> createState() => _JourneyDetailsScreenState();
}

class _JourneyDetailsScreenState extends State<JourneyDetailsScreen> {
  final Set<int> _expandedSegments = {};

  void _toggleSegment(int index) {
    setState(() {
      if (_expandedSegments.contains(index)) {
        _expandedSegments.remove(index);
      } else {
        _expandedSegments.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final journey = widget.journey;
    final depString =
        '${journey.departureTime.hour.toString().padLeft(2, '0')}:${journey.departureTime.minute.toString().padLeft(2, '0')}';
    final arrString =
        '${journey.arrivalTime.hour.toString().padLeft(2, '0')}:${journey.arrivalTime.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: SafarTokens.background,
      appBar: AppBar(
        backgroundColor: SafarTokens.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: SafarTokens.deepCharcoal,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Journey Timeline',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: SafarTokens.deepCharcoal,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.warning_amber_rounded,
              color: SafarTokens.alertAmber,
            ),
            tooltip: 'Service Alerts',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DisruptionAlertScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // TOP SUMMARY CARD
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(SafarTokens.radiusL),
                  boxShadow: const [SafarTokens.cardSoftShadow],
                  border: Border.all(
                    color: SafarTokens.mutedSage.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$depString → $arrString',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: SafarTokens.deepCharcoal,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${journey.durationMinutes} mins total duration',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: SafarTokens.transitGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              journey.fareDisplay,
                              style: TextStyle(
                                fontSize: journey.fareEstimate != null
                                    ? 22
                                    : 14,
                                fontWeight: FontWeight.w800,
                                color: SafarTokens.deepCharcoal,
                              ),
                            ),
                            Text(
                              journey.fareEstimate != null
                                  ? 'Estimated Fare'
                                  : 'Fare Unverified',
                              style: const TextStyle(
                                fontSize: 11,
                                color: SafarTokens.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 20, thickness: 0.8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Flexible(
                          child: _StatBadge(
                            icon: Icons.alt_route_rounded,
                            label: journey.transfersCount == 0
                                ? 'Direct'
                                : '${journey.transfersCount} Transfer',
                          ),
                        ),
                        Flexible(
                          child: _StatBadge(
                            icon: Icons.directions_walk_rounded,
                            label: '${journey.walkingMeters}m walk',
                          ),
                        ),
                        const Flexible(
                          child: _StatBadge(
                            icon: Icons.eco_rounded,
                            label: 'Low Carbon',
                            color: SafarTokens.transitGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // VERTICAL ROUTE TIMELINE
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: journey.segments.length,
                itemBuilder: (context, index) {
                  final segment = journey.segments[index];
                  final isExpanded = _expandedSegments.contains(index);

                  return _TimelineSegment(
                    segment: segment,
                    isFirst: index == 0,
                    isLast: index == journey.segments.length - 1,
                    isExpanded: isExpanded,
                    onToggleExpand: () => _toggleSegment(index),
                  );
                },
              ),
            ),

            // ACTION BAR: ALERT NOTIFICATION & RECOVERY
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const DisruptionAlertScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.shield_outlined, size: 18),
                  label: const Text(
                    'Check Service Alerts & Disruption Recovery',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SafarTokens.deepCharcoal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        SafarTokens.radiusFull,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _StatBadge({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? SafarTokens.textMuted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: effectiveColor),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: effectiveColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _TimelineSegment extends StatelessWidget {
  final JourneySegment segment;
  final bool isFirst;
  final bool isLast;
  final bool isExpanded;
  final VoidCallback onToggleExpand;

  const _TimelineSegment({
    required this.segment,
    required this.isFirst,
    required this.isLast,
    required this.isExpanded,
    required this.onToggleExpand,
  });

  @override
  Widget build(BuildContext context) {
    final modeColor = segment.mode.color;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TIMELINE PILLAR
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: modeColor.withValues(alpha: 0.15),
                border: Border.all(color: modeColor, width: 2),
              ),
              child: Icon(segment.mode.icon, size: 14, color: modeColor),
            ),
            if (!isLast)
              Container(
                width: 3,
                height: isExpanded ? 140 : 85,
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: modeColor.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),

        const SizedBox(width: 14),

        // SEGMENT CONTENT CARD
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(SafarTokens.radiusM),
                border: Border.all(
                  color: SafarTokens.mutedSage.withValues(alpha: 0.5),
                ),
                boxShadow: const [SafarTokens.cardSoftShadow],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ROUTE & MODE BADGES
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: modeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            segment.routeLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: modeColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${segment.durationMinutes} min',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: SafarTokens.deepCharcoal,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // FROM -> TO
                  Text(
                    'Board: ${segment.fromStopName}',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: SafarTokens.deepCharcoal,
                    ),
                  ),
                  if (segment.platformOrBay != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(
                        segment.platformOrBay!,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: SafarTokens.transitGreen,
                        ),
                      ),
                    ),

                  const SizedBox(height: 6),
                  Text(
                    'Alight: ${segment.toStopName}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: SafarTokens.textMuted,
                    ),
                  ),

                  // INTERMEDIATE STOPS EXPANDABLE
                  if (segment.intermediateStopsCount > 0) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: onToggleExpand,
                      child: Row(
                        children: [
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: SafarTokens.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${segment.intermediateStopsCount} intermediate stations',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: SafarTokens.textMuted,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isExpanded) ...[
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: segment.intermediateStops
                              .map(
                                (stop) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2.0,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 4,
                                        height: 4,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: SafarTokens.textMuted,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        stop,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: SafarTokens.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
