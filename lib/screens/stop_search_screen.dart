import 'package:flutter/material.dart';
import '../models/transit_stop.dart';
import '../services/transit_data_service.dart';
import '../theme/tokens.dart';

enum StopSelectionMode { origin, destination }

class StopSearchScreen extends StatefulWidget {
  final StopSelectionMode selectionMode;
  final TransitStop? currentStop;

  const StopSearchScreen({
    super.key,
    required this.selectionMode,
    this.currentStop,
  });

  @override
  State<StopSearchScreen> createState() => _StopSearchScreenState();
}

class _StopSearchScreenState extends State<StopSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  TransitMode? _selectedModeFilter;
  List<TransitStop> _results = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isFromFallback = false;

  @override
  void initState() {
    super.initState();
    _loadStops('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStops(String query) async {
    // Provide instant local results first to eliminate UI latency
    setState(() {
      _results = TransitDataService.instance.searchStops(
        query,
        modeFilter: _selectedModeFilter,
      );
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await TransitDataService.instance.fetchStopsAsync(
      query: query,
      modeFilter: _selectedModeFilter,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (response.data != null && response.data!.isNotEmpty) {
          _results = response.data!;
        }
        _isFromFallback = response.isFromFallback;
        if (!response.isSuccess) {
          _errorMessage = response.errorMessage;
        }
      });
    }
  }

  void _onQueryChanged(String query) {
    _loadStops(query);
  }

  void _onFilterSelected(TransitMode? mode) {
    setState(() {
      _selectedModeFilter = mode;
    });
    _loadStops(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    final titleText = widget.selectionMode == StopSelectionMode.origin
        ? 'Select Origin (From)'
        : 'Select Destination (To)';

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
        title: Text(
          titleText,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: SafarTokens.deepCharcoal,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // SEARCH INPUT CARD
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(SafarTokens.radiusM),
                  border: Border.all(
                    color: SafarTokens.mutedSage.withValues(alpha: 0.6),
                  ),
                  boxShadow: const [SafarTokens.cardSoftShadow],
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: _onQueryChanged,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: SafarTokens.deepCharcoal,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        'Search station, bus stop, or code (e.g. Tambaram, Guindy, MAS)...',
                    hintStyle: const TextStyle(
                      fontSize: 13.5,
                      color: SafarTokens.textMuted,
                      fontWeight: FontWeight.w400,
                    ),
                    prefixIcon: Icon(
                      widget.selectionMode == StopSelectionMode.origin
                          ? Icons.trip_origin_rounded
                          : Icons.location_on_rounded,
                      color: SafarTokens.transitGreen,
                      size: 22,
                    ),
                    suffixIcon: _isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: SafarTokens.transitGreen,
                              ),
                            ),
                          )
                        : _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear_rounded,
                              color: SafarTokens.textMuted,
                              size: 20,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _onQueryChanged('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            // TRANSIT MODE FILTER CHIPS
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _FilterChip(
                    label: 'All Modes',
                    isSelected: _selectedModeFilter == null,
                    onTap: () => _onFilterSelected(null),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Suburban Rail',
                    icon: Icons.train_rounded,
                    isSelected: _selectedModeFilter == TransitMode.suburban,
                    color: SafarTokens.modeSuburban,
                    onTap: () => _onFilterSelected(TransitMode.suburban),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Chennai Metro',
                    icon: Icons.subway_rounded,
                    isSelected: _selectedModeFilter == TransitMode.metro,
                    color: SafarTokens.modeMetro,
                    onTap: () => _onFilterSelected(TransitMode.metro),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'MRTS Line',
                    icon: Icons.tram_rounded,
                    isSelected: _selectedModeFilter == TransitMode.mrts,
                    color: SafarTokens.modeMrts,
                    onTap: () => _onFilterSelected(TransitMode.mrts),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'MTC Bus',
                    icon: Icons.directions_bus_rounded,
                    isSelected: _selectedModeFilter == TransitMode.bus,
                    color: SafarTokens.modeBus,
                    onTap: () => _onFilterSelected(TransitMode.bus),
                  ),
                ],
              ),
            ),

            if (_isFromFallback)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: SafarTokens.softMint,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: SafarTokens.transitGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.offline_pin_rounded,
                        size: 15,
                        color: SafarTokens.transitGreen,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _errorMessage != null
                              ? 'Offline schedule active • $_errorMessage'
                              : 'Showing verified local Chennai stops (GTFS API fallback)',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: SafarTokens.deepCharcoal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // RESULTS LIST OR EMPTY STATE
            Expanded(
              child: _results.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 54,
                            color: SafarTokens.mutedSage.withValues(alpha: 0.8),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage != null
                                ? 'Notice: $_errorMessage'
                                : _searchController.text.isEmpty
                                ? 'No transit stops available'
                                : 'No stops found for "${_searchController.text}"',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: SafarTokens.deepCharcoal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Try searching "Tambaram", "Guindy", or "Central"',
                            style: TextStyle(
                              fontSize: 13,
                              color: SafarTokens.textMuted,
                            ),
                          ),
                          if (_searchController.text.isNotEmpty ||
                              _selectedModeFilter != null) ...[
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () {
                                _searchController.clear();
                                _onFilterSelected(null);
                              },
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: const Text('Reset filters'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: SafarTokens.transitGreen,
                                side: const BorderSide(
                                  color: SafarTokens.transitGreen,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: _results.length,
                      separatorBuilder: (context, index) => const Divider(
                        height: 1,
                        thickness: 0.8,
                        color: Color(0x1F26332F),
                      ),
                      itemBuilder: (context, index) {
                        final stop = _results[index];
                        final isSelected = widget.currentStop?.id == stop.id;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          onTap: () => Navigator.of(context).pop(stop),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: stop.primaryMode.color.withValues(
                                alpha: 0.14,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              stop.primaryMode.icon,
                              color: stop.primaryMode.color,
                              size: 20,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  stop.name,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w700,
                                    color: SafarTokens.deepCharcoal,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: SafarTokens.softMint,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: SafarTokens.transitGreen.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  stop.code,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: SafarTokens.transitGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  if (stop.isInterchange) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: SafarTokens.alertAmber
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Interchange',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: SafarTokens.alertAmber,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  Expanded(
                                    child: Text(
                                      stop.hubDescription,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: SafarTokens.textMuted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: SafarTokens.transitGreen,
                                  size: 20,
                                )
                              : const Icon(
                                  Icons.chevron_right_rounded,
                                  color: SafarTokens.textMuted,
                                  size: 20,
                                ),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    this.icon,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? SafarTokens.transitGreen;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(SafarTokens.radiusFull),
          border: Border.all(
            color: isSelected
                ? activeColor
                : SafarTokens.mutedSage.withValues(alpha: 0.6),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.28),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : activeColor,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : SafarTokens.deepCharcoal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
