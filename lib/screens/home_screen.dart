import 'package:flutter/material.dart';
import '../models/search_preferences.dart';
import '../models/transit_stop.dart';
import '../services/transit_data_service.dart';
import '../theme/tokens.dart';
import '../widgets/interactive_3d_hero.dart';
import '../widgets/tactile_cta_button.dart';
import 'disruption_alert_screen.dart';
import 'journey_results_screen.dart';
import 'stop_search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TransitStop? _origin;
  TransitStop? _destination;
  SearchPreferences _preferences = SearchPreferences(
    travelDate: DateTime.now(),
    travelTime: TimeOfDay(
      hour: (DateTime.now().hour + (DateTime.now().minute > 50 ? 1 : 0)) % 24,
      minute: (DateTime.now().minute + 5) % 60,
    ),
    preference: 'fastest',
  );
  bool _showAdvancedOptions = false;

  @override
  void initState() {
    super.initState();
    // Default Chennai Commute Example: Tambaram -> Chennai Central
    _origin = TransitDataService.allStops.firstWhere(
      (s) => s.id == 'TBM_TAMBARAM',
    );
    _destination = TransitDataService.allStops.firstWhere(
      (s) => s.id == 'MAS_CENTRAL',
    );
  }

  void _swapStops() {
    setState(() {
      final temp = _origin;
      _origin = _destination;
      _destination = temp;
    });
  }

  Future<void> _selectOrigin() async {
    final selected = await Navigator.of(context).push<TransitStop>(
      MaterialPageRoute(
        builder: (context) => StopSearchScreen(
          selectionMode: StopSelectionMode.origin,
          currentStop: _origin,
        ),
      ),
    );

    if (selected != null) {
      setState(() => _origin = selected);
    }
  }

  Future<void> _selectDestination() async {
    final selected = await Navigator.of(context).push<TransitStop>(
      MaterialPageRoute(
        builder: (context) => StopSearchScreen(
          selectionMode: StopSelectionMode.destination,
          currentStop: _destination,
        ),
      ),
    );

    if (selected != null) {
      setState(() => _destination = selected);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _preferences.travelDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: SafarTokens.transitGreen,
              onPrimary: Colors.white,
              onSurface: SafarTokens.deepCharcoal,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _preferences = _preferences.copyWith(travelDate: picked);
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _preferences.travelTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: SafarTokens.transitGreen,
              onPrimary: Colors.white,
              onSurface: SafarTokens.deepCharcoal,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _preferences = _preferences.copyWith(travelTime: picked);
      });
    }
  }

  void _findJourney() {
    if (_origin == null || _destination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both Origin and Destination stops.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_origin!.id == _destination!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Origin and Destination cannot be the same station.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => JourneyResultsScreen(
          origin: _origin!,
          destination: _destination!,
          preferences: _preferences,
        ),
      ),
    );
  }

  void _setQuickRoute(String originId, String destId) {
    setState(() {
      _origin = TransitDataService.allStops.firstWhere((s) => s.id == originId);
      _destination = TransitDataService.allStops.firstWhere(
        (s) => s.id == destId,
      );
    });
  }

  void _openFrequentCommutesSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _FrequentCommutesSheet(
        onSelectRoute: (from, to) {
          _setQuickRoute(from, to);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SafarTokens.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // 1. BRANDING & NOTIFICATION HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: SafarTokens.transitGreen,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'SAFAR',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Chennai',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: SafarTokens.deepCharcoal,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const DisruptionAlertScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.notifications_active_outlined,
                      color: SafarTokens.deepCharcoal,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // 2. GREETING & FREQUENT COMMUTES ACTION PILL
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Where are you commuting today?',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: SafarTokens.deepCharcoal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _openFrequentCommutesSheet,
                    borderRadius: BorderRadius.circular(
                      SafarTokens.radiusFull,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: SafarTokens.softMint,
                        borderRadius: BorderRadius.circular(
                          SafarTokens.radiusFull,
                        ),
                        border: Border.all(
                          color: SafarTokens.transitGreen.withValues(
                            alpha: 0.35,
                          ),
                          width: 1.0,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bookmark_outline_rounded,
                            size: 14,
                            color: SafarTokens.transitGreen,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Frequent Commutes',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: SafarTokens.transitGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // 2. SIGNATURE 2.5D ROAMING METRO HERO (Clean, minimal, zero text overlay clutter)
              ClipRRect(
                borderRadius: BorderRadius.circular(SafarTokens.radiusL),
                child: const SizedBox(
                  height: 145,
                  child: Interactive3DHero(
                    height: 145,
                    showBadges: false,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // 3. JOURNEY SEARCH CARD
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(SafarTokens.radiusL),
                  border: Border.all(
                    color: SafarTokens.mutedSage.withValues(alpha: 0.6),
                  ),
                  boxShadow: const [SafarTokens.cardSoftShadow],
                ),
                child: Column(
                  children: [
                    // ORIGIN & DESTINATION WITH SWAP CONTROL
                    Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        Column(
                          children: [
                            // "From" Input
                            _LocationSelectorTile(
                              label: 'From',
                              stop: _origin,
                              isOrigin: true,
                              onTap: _selectOrigin,
                            ),

                            const Divider(height: 14, thickness: 0.8),

                            // "To" Input
                            _LocationSelectorTile(
                              label: 'To',
                              stop: _destination,
                              isOrigin: false,
                              onTap: _selectDestination,
                            ),
                          ],
                        ),

                        // Swap Button
                        Positioned(
                          right: 12,
                          child: GestureDetector(
                            onTap: _swapStops,
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: SafarTokens.softMint,
                                border: Border.all(
                                  color: SafarTokens.transitGreen.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x1F19AC8B),
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.swap_vert_rounded,
                                color: SafarTokens.transitGreen,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    const Divider(height: 1, thickness: 0.8),
                    const SizedBox(height: 12),

                    // SEARCH PREFERENCES: DATE, TIME, ROUTE PREFERENCE & CONSTRAINTS
                    _buildPreferencesSection(),

                    const SizedBox(height: 16),

                    // "FIND MY JOURNEY" CTA BUTTON
                    TactileCtaButton(
                      label: 'Find My Journey',
                      icon: Icons.directions_transit_filled_rounded,
                      onTap: _findJourney,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. DATE & TIME ROW
        Row(
          children: [
            // Date Picker Chip
            Expanded(
              child: GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: SafarTokens.warmIvory,
                    borderRadius: BorderRadius.circular(SafarTokens.radiusM),
                    border: Border.all(
                      color: SafarTokens.mutedSage.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 15,
                        color: SafarTokens.transitGreen,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _preferences.formattedDate,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: SafarTokens.deepCharcoal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Time Picker Chip
            Expanded(
              child: GestureDetector(
                onTap: _pickTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: SafarTokens.warmIvory,
                    borderRadius: BorderRadius.circular(SafarTokens.radiusM),
                    border: Border.all(
                      color: SafarTokens.mutedSage.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 15,
                        color: SafarTokens.transitGreen,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _preferences.displayTime,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: SafarTokens.deepCharcoal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // 2. ROUTE PREFERENCE TOGGLE (Fastest / Fewest Transfers / Cheapest)
        Row(
          children: [
            _buildPrefChip('Fastest', 'fastest', Icons.bolt_rounded),
            const SizedBox(width: 6),
            _buildPrefChip(
              'Fewest Transfers',
              'fewest_transfers',
              Icons.alt_route_rounded,
            ),
            const SizedBox(width: 6),
            _buildPrefChip(
              'Cheapest',
              'cheapest',
              Icons.currency_rupee_rounded,
            ),
          ],
        ),

        const SizedBox(height: 8),

        // 3. ADVANCED CONSTRAINTS (Transfers & Budget)
        InkWell(
          onTap: () {
            setState(() {
              _showAdvancedOptions = !_showAdvancedOptions;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _showAdvancedOptions
                        ? 'Hide travel options'
                        : 'More options (Transfers, Budget)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: SafarTokens.transitGreen,
                    ),
                  ),
                ),
                Icon(
                  _showAdvancedOptions
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: SafarTokens.transitGreen,
                ),
              ],
            ),
          ),
        ),

        if (_showAdvancedOptions) ...[
          const SizedBox(height: 8),
          // Max Transfers constraint
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text(
                  'Transfers:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: SafarTokens.textMuted,
                  ),
                ),
                const SizedBox(width: 8),
                _buildConstraintPill(
                  label: 'Any',
                  isSelected: _preferences.maxTransfers == null,
                  onTap: () => setState(
                    () => _preferences = _preferences.copyWith(
                      clearMaxTransfers: true,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _buildConstraintPill(
                  label: 'Direct only (0)',
                  isSelected: _preferences.maxTransfers == 0,
                  onTap: () => setState(
                    () => _preferences = _preferences.copyWith(maxTransfers: 0),
                  ),
                ),
                const SizedBox(width: 6),
                _buildConstraintPill(
                  label: 'Max 1',
                  isSelected: _preferences.maxTransfers == 1,
                  onTap: () => setState(
                    () => _preferences = _preferences.copyWith(maxTransfers: 1),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Max Budget constraint
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text(
                  'Max Fare:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: SafarTokens.textMuted,
                  ),
                ),
                const SizedBox(width: 8),
                _buildConstraintPill(
                  label: 'Any',
                  isSelected: _preferences.maxBudget == null,
                  onTap: () => setState(
                    () => _preferences = _preferences.copyWith(
                      clearMaxBudget: true,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _buildConstraintPill(
                  label: '≤ ₹25',
                  isSelected: _preferences.maxBudget == 25,
                  onTap: () => setState(
                    () => _preferences = _preferences.copyWith(maxBudget: 25),
                  ),
                ),
                const SizedBox(width: 6),
                _buildConstraintPill(
                  label: '≤ ₹50',
                  isSelected: _preferences.maxBudget == 50,
                  onTap: () => setState(
                    () => _preferences = _preferences.copyWith(maxBudget: 50),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPrefChip(String label, String value, IconData icon) {
    final isSelected = _preferences.preference == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _preferences = _preferences.copyWith(preference: value);
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? SafarTokens.deepCharcoal
                : SafarTokens.warmIvory,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? SafarTokens.deepCharcoal
                  : SafarTokens.mutedSage.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 13,
                color: isSelected ? Colors.white : SafarTokens.textMuted,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
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

  Widget _buildConstraintPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? SafarTokens.transitGreen : SafarTokens.warmIvory,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? SafarTokens.transitGreen
                : SafarTokens.mutedSage.withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : SafarTokens.deepCharcoal,
          ),
        ),
      ),
    );
  }
}

class _LocationSelectorTile extends StatelessWidget {
  final String label;
  final TransitStop? stop;
  final bool isOrigin;
  final VoidCallback onTap;

  const _LocationSelectorTile({
    required this.label,
    required this.stop,
    required this.isOrigin,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(SafarTokens.radiusM),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    (isOrigin
                            ? SafarTokens.transitGreen
                            : SafarTokens.deepCharcoal)
                        .withValues(alpha: 0.12),
              ),
              child: Icon(
                isOrigin
                    ? Icons.trip_origin_rounded
                    : Icons.location_on_rounded,
                color: isOrigin
                    ? SafarTokens.transitGreen
                    : SafarTokens.deepCharcoal,
                size: 17,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: SafarTokens.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stop != null ? stop!.name : 'Select station or bus stop',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: stop != null
                          ? SafarTokens.deepCharcoal
                          : SafarTokens.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.search_rounded,
              size: 20,
              color: SafarTokens.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _FrequentCommutesSheet extends StatelessWidget {
  final void Function(String originId, String destId) onSelectRoute;

  const _FrequentCommutesSheet({required this.onSelectRoute});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: SafarTokens.background,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(SafarTokens.radiusXL),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: SafarTokens.mutedSage.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Frequent Commutes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: SafarTokens.deepCharcoal,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                  color: SafarTokens.textMuted,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(SafarTokens.radiusM),
                border: Border.all(
                  color: SafarTokens.alertAmber.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: SafarTokens.alertAmber,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'MRTS Beach–Velachery Advisory Active',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: SafarTokens.deepCharcoal,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const DisruptionAlertScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Alerts →',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: SafarTokens.alertAmber,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select a route to auto-fill your journey:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: SafarTokens.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            _FrequentRouteCard(
              title: 'Tambaram → Central',
              subtitle: 'Suburban Fast',
              icon: Icons.train_rounded,
              onTap: () => onSelectRoute('TBM_TAMBARAM', 'MAS_CENTRAL'),
            ),
            const SizedBox(height: 8),
            _FrequentRouteCard(
              title: 'Guindy → Koyambedu',
              subtitle: 'Metro Green',
              icon: Icons.subway_rounded,
              onTap: () => onSelectRoute('GDY_GUINDY', 'CMBT_KOYAMBEDU'),
            ),
            const SizedBox(height: 8),
            _FrequentRouteCard(
              title: 'Airport → Egmore',
              subtitle: 'Direct Metro',
              icon: Icons.flight_takeoff_rounded,
              onTap: () => onSelectRoute('AIRPORT_METRO', 'MS_EGMORE'),
            ),
            const SizedBox(height: 8),
            _FrequentRouteCard(
              title: 'Velachery → Central',
              subtitle: 'MRTS & Suburban',
              icon: Icons.directions_transit_rounded,
              onTap: () => onSelectRoute('VLCY_VELACHERY', 'MAS_CENTRAL'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FrequentRouteCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _FrequentRouteCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(SafarTokens.radiusM),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(SafarTokens.radiusM),
          border: Border.all(
            color: SafarTokens.mutedSage.withValues(alpha: 0.5),
          ),
          boxShadow: const [SafarTokens.cardSoftShadow],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: SafarTokens.softMint,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: SafarTokens.transitGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: SafarTokens.deepCharcoal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: SafarTokens.transitGreen,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: SafarTokens.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
