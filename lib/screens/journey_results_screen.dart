import 'package:flutter/material.dart';
import '../models/journey.dart';
import '../models/search_preferences.dart';
import '../models/transit_stop.dart';
import '../services/transit_data_service.dart';
import '../theme/tokens.dart';
import 'journey_details_screen.dart';

class JourneyResultsScreen extends StatefulWidget {
  final TransitStop origin;
  final TransitStop destination;
  final SearchPreferences? preferences;

  const JourneyResultsScreen({
    super.key,
    required this.origin,
    required this.destination,
    this.preferences,
  });

  @override
  State<JourneyResultsScreen> createState() => _JourneyResultsScreenState();
}

class _JourneyResultsScreenState extends State<JourneyResultsScreen> {
  JourneySort _currentSort = JourneySort.fastest;
  List<Journey> _journeys = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isFromFallback = false;
  String? _blockerDetail;

  @override
  void initState() {
    super.initState();
    _loadJourneys();
  }

  Future<void> _loadJourneys() async {
    final effectivePrefs =
        (widget.preferences ??
                SearchPreferences(
                  travelDate: DateTime.now(),
                  travelTime: TimeOfDay.now(),
                ))
            .copyWith(
              preference: _currentSort == JourneySort.fastest
                  ? 'fastest'
                  : _currentSort == JourneySort.cheapest
                  ? 'cheapest'
                  : 'fewest_transfers',
            );

    setState(() {
      _journeys = TransitDataService.instance.findJourneys(
        widget.origin,
        widget.destination,
        sort: _currentSort,
      );
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await TransitDataService.instance.planJourneysAsync(
      origin: widget.origin,
      destination: widget.destination,
      preferences: effectivePrefs,
      sort: _currentSort,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res.data != null && res.data!.isNotEmpty) {
          _journeys = res.data!;
        }
        _isFromFallback = res.isFromFallback;
        _blockerDetail = res.blockerDetail;
        if (!res.isSuccess) {
          _errorMessage = res.errorMessage;
        }
      });
    }
  }

  void _onSortChanged(JourneySort sort) {
    setState(() {
      _currentSort = sort;
    });
    _loadJourneys();
  }

  @override
  Widget build(BuildContext context) {
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    widget.origin.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: SafarTokens.deepCharcoal,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: SafarTokens.transitGreen,
                  ),
                ),
                Flexible(
                  child: Text(
                    widget.destination.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: SafarTokens.deepCharcoal,
                    ),
                  ),
                ),
              ],
            ),
            const Text(
              'Chennai Commuter Routes',
              style: TextStyle(fontSize: 11.5, color: SafarTokens.textMuted),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // SORTING FILTER BAR
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 6.0,
              ),
              child: Row(
                children: [
                  _SortButton(
                    label: 'Fastest',
                    icon: Icons.bolt_rounded,
                    isSelected: _currentSort == JourneySort.fastest,
                    onTap: () => _onSortChanged(JourneySort.fastest),
                  ),
                  const SizedBox(width: 8),
                  _SortButton(
                    label: 'Fewest Transfers',
                    icon: Icons.transfer_within_a_station_rounded,
                    isSelected: _currentSort == JourneySort.fewestTransfers,
                    onTap: () => _onSortChanged(JourneySort.fewestTransfers),
                  ),
                  const SizedBox(width: 8),
                  _SortButton(
                    label: 'Cheapest',
                    icon: Icons.currency_rupee_rounded,
                    isSelected: _currentSort == JourneySort.cheapest,
                    onTap: () => _onSortChanged(JourneySort.cheapest),
                  ),
                ],
              ),
            ),

            // SIMULATION & DEMO DATA DISCLAIMER BANNER
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 6.0,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: SafarTokens.softMint,
                  borderRadius: BorderRadius.circular(SafarTokens.radiusM),
                  border: Border.all(
                    color: SafarTokens.transitGreen.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isFromFallback
                          ? Icons.info_outline_rounded
                          : Icons.verified_rounded,
                      size: 16,
                      color: SafarTokens.transitGreen,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isFromFallback
                                ? 'Static GTFS Schedule Estimate • Fares & timings based on Southern Railway & CMRL tables'
                                : 'GTFS Timetable Search Results • Static schedules (not live GPS tracking)',
                            style: const TextStyle(
                              fontSize: 11,
                              color: SafarTokens.deepCharcoal,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_blockerDetail != null && _isFromFallback)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                _blockerDetail!,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: SafarTokens.textMuted,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: SafarTokens.alertAmber,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (_isLoading) ...[
                      const SizedBox(width: 8),
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: SafarTokens.transitGreen,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // JOURNEY RESULTS LIST
            Expanded(
              child: _journeys.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.directions_off_rounded,
                              size: 48,
                              color: SafarTokens.textMuted,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _errorMessage ??
                                  'No routes available for this corridor',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: SafarTokens.deepCharcoal,
                              ),
                            ),
                            if (_blockerDetail != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                _blockerDetail!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: SafarTokens.textMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _journeys.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final journey = _journeys[index];
                        return _JourneyCard(
                          journey: journey,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    JourneyDetailsScreen(journey: journey),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? SafarTokens.deepCharcoal : Colors.white,
            borderRadius: BorderRadius.circular(SafarTokens.radiusM),
            border: Border.all(
              color: isSelected
                  ? SafarTokens.deepCharcoal
                  : SafarTokens.mutedSage.withValues(alpha: 0.6),
            ),
            boxShadow: isSelected ? const [SafarTokens.cardSoftShadow] : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : SafarTokens.textMuted,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? Colors.white : SafarTokens.deepCharcoal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JourneyCard extends StatelessWidget {
  final Journey journey;
  final VoidCallback onTap;

  const _JourneyCard({required this.journey, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final depString =
        '${journey.departureTime.hour.toString().padLeft(2, '0')}:${journey.departureTime.minute.toString().padLeft(2, '0')}';
    final arrString =
        '${journey.arrivalTime.hour.toString().padLeft(2, '0')}:${journey.arrivalTime.minute.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(SafarTokens.radiusL),
          border: Border.all(
            color: SafarTokens.mutedSage.withValues(alpha: 0.45),
          ),
          boxShadow: const [SafarTokens.cardSoftShadow],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TOP ROW: DURATION & FARE
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: SafarTokens.softMint,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${journey.durationMinutes} mins',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: SafarTokens.transitGreen,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: SafarTokens.warmIvory,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: SafarTokens.mutedSage.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                          child: Text(
                            journey.tag,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: SafarTokens.deepCharcoal,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  journey.fareDisplay,
                  style: TextStyle(
                    fontSize: journey.fareEstimate != null ? 18 : 12.5,
                    fontWeight: FontWeight.w800,
                    color: journey.fareEstimate != null
                        ? SafarTokens.deepCharcoal
                        : SafarTokens.textMuted,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // TIME & TRANSFERS ROW
            Row(
              children: [
                Text(
                  '$depString → $arrString',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: SafarTokens.deepCharcoal,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${journey.transfersCount == 0 ? 'Direct' : '${journey.transfersCount} transfer'} • ${journey.walkingMeters}m walk',
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: SafarTokens.textMuted,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // VISUAL MULTI-SEGMENT ROUTE BAR
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: SafarTokens.warmIvory,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (int i = 0; i < journey.segments.length; i++) ...[
                      if (i > 0)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            Icons.arrow_right_rounded,
                            size: 16,
                            color: SafarTokens.textMuted,
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: journey.segments[i].mode.color.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: journey.segments[i].mode.color.withValues(
                              alpha: 0.5,
                            ),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              journey.segments[i].mode.icon,
                              size: 13,
                              color: journey.segments[i].mode.color,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              journey.segments[i].routeLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: journey.segments[i].mode.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (journey.rankingExplanation != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: SafarTokens.softMint.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '💡 ${journey.rankingExplanation!}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: SafarTokens.transitGreen,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
