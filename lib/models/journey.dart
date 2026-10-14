import 'package:flutter/material.dart';
import 'transit_stop.dart';

enum JourneySort { fastest, fewestTransfers, cheapest }

class JourneySegment {
  final TransitMode mode;
  final String routeLabel;
  final String lineDescription;
  final String fromStopName;
  final String toStopName;
  final int durationMinutes;
  final int intermediateStopsCount;
  final List<String> intermediateStops;
  final String? platformOrBay;
  final int? frequencyMinutes;
  final bool isSimulated;

  const JourneySegment({
    required this.mode,
    required this.routeLabel,
    required this.lineDescription,
    required this.fromStopName,
    required this.toStopName,
    required this.durationMinutes,
    this.intermediateStopsCount = 0,
    this.intermediateStops = const [],
    this.platformOrBay,
    this.frequencyMinutes,
    this.isSimulated = true,
  });

  factory JourneySegment.fromJson(Map<String, dynamic> json) {
    final modeStr = (json['mode'] ?? json['travel_mode'] ?? 'train')
        .toString()
        .toLowerCase();
    TransitMode mode = TransitMode.suburban;
    if (modeStr.contains('metro') || modeStr == 'subway') {
      mode = TransitMode.metro;
    } else if (modeStr.contains('mrts') || modeStr.contains('tram')) {
      mode = TransitMode.mrts;
    } else if (modeStr.contains('bus')) {
      mode = TransitMode.bus;
    } else if (modeStr.contains('walk')) {
      mode = TransitMode.walk;
    }

    final int duration =
        (json['duration_minutes'] ?? json['durationMinutes'] ?? 15 as num)
            .toInt();

    final stopsRaw = json['intermediate_stops'] ?? json['stops'] ?? [];
    List<String> stops = [];
    if (stopsRaw is List) {
      stops = stopsRaw.map((s) => s.toString()).toList();
    }

    return JourneySegment(
      mode: mode,
      routeLabel:
          (json['route_label'] ??
                  json['routeLabel'] ??
                  json['service_name'] ??
                  'Transit Line')
              .toString(),
      lineDescription:
          (json['line_description'] ??
                  json['lineDescription'] ??
                  'Connecting Service')
              .toString(),
      fromStopName:
          (json['from_stop_name'] ??
                  json['fromStopName'] ??
                  json['from'] ??
                  'Origin')
              .toString(),
      toStopName:
          (json['to_stop_name'] ??
                  json['toStopName'] ??
                  json['to'] ??
                  'Destination')
              .toString(),
      durationMinutes: duration,
      intermediateStopsCount: stops.isNotEmpty
          ? stops.length
          : (json['intermediate_stops_count'] ?? 0 as num).toInt(),
      intermediateStops: stops,
      platformOrBay: json['platform']?.toString(),
      frequencyMinutes: (json['frequency_minutes'] as num?)?.toInt(),
      isSimulated: json['is_simulated'] ?? false,
    );
  }
}

class Journey {
  final String id;
  final TransitStop origin;
  final TransitStop destination;
  final int durationMinutes;
  final int? fareEstimate; // Nullable: unknown fare is null, never 0
  final int transfersCount;
  final int walkingMeters;
  final TimeOfDay departureTime;
  final TimeOfDay arrivalTime;
  final List<JourneySegment> segments;
  final String tag;
  final bool isSimulated;
  final String disclaimer;
  final String? rankingExplanation;

  const Journey({
    required this.id,
    required this.origin,
    required this.destination,
    required this.durationMinutes,
    this.fareEstimate,
    required this.transfersCount,
    required this.walkingMeters,
    required this.departureTime,
    required this.arrivalTime,
    required this.segments,
    this.tag = 'Recommended',
    this.isSimulated = true,
    this.disclaimer =
        'Static GTFS schedule estimate (live tracking not verified)',
    this.rankingExplanation,
  });

  String get fareDisplay {
    if (fareEstimate == null) {
      return 'Fare unknown';
    }
    return '₹$fareEstimate';
  }

  factory Journey.fromJson(
    Map<String, dynamic> json, {
    TransitStop? defaultOrigin,
    TransitStop? defaultDest,
  }) {
    // Origin
    TransitStop orig;
    if (json['origin'] is Map<String, dynamic>) {
      orig = TransitStop.fromJson(json['origin']);
    } else if (defaultOrigin != null) {
      orig = defaultOrigin;
    } else {
      orig = TransitStop(
        id: json['origin_id']?.toString() ?? 'ORIG',
        name: json['origin_name']?.toString() ?? 'Origin',
        code: 'ORG',
        primaryMode: TransitMode.suburban,
        hubDescription: 'Origin Stop',
      );
    }

    // Destination
    TransitStop dest;
    if (json['destination'] is Map<String, dynamic>) {
      dest = TransitStop.fromJson(json['destination']);
    } else if (defaultDest != null) {
      dest = defaultDest;
    } else {
      dest = TransitStop(
        id: json['destination_id']?.toString() ?? 'DEST',
        name: json['destination_name']?.toString() ?? 'Destination',
        code: 'DST',
        primaryMode: TransitMode.suburban,
        hubDescription: 'Destination Stop',
      );
    }

    final duration =
        (json['duration_minutes'] ?? json['durationMinutes'] ?? 35 as num)
            .toInt();

    // Fare: treat missing or unknown as null, never 0
    final rawFare =
        json['fare'] ??
        json['fare_estimate'] ??
        json['fareEstimate'] ??
        json['price'];
    final int? fare = rawFare != null ? (rawFare as num).toInt() : null;

    final transfers =
        (json['transfers_count'] ?? json['transfersCount'] ?? 0 as num).toInt();
    final walkingM =
        (json['walking_meters'] ?? json['walkingMeters'] ?? 200 as num).toInt();

    // Segments
    final segsRaw = json['segments'] ?? json['legs'] ?? [];
    List<JourneySegment> segs = [];
    if (segsRaw is List) {
      segs = segsRaw
          .whereType<Map<String, dynamic>>()
          .map(JourneySegment.fromJson)
          .toList();
    }
    if (segs.isEmpty) {
      segs = [
        JourneySegment(
          mode: orig.primaryMode,
          routeLabel: orig.availableLines.isNotEmpty
              ? orig.availableLines.first
              : 'Direct Line',
          lineDescription: 'Scheduled transit route',
          fromStopName: orig.name,
          toStopName: dest.name,
          durationMinutes: duration,
        ),
      ];
    }

    return Journey(
      id: (json['id'] ?? json['journey_id'] ?? 'JRN_${orig.code}_${dest.code}')
          .toString(),
      origin: orig,
      destination: dest,
      durationMinutes: duration,
      fareEstimate: fare,
      transfersCount: transfers,
      walkingMeters: walkingM,
      departureTime: _parseTime(
        json['departure_time'] ?? json['departureTime'] ?? json['departure'],
      ),
      arrivalTime: _parseTime(
        json['arrival_time'] ?? json['arrivalTime'] ?? json['arrival'],
      ),
      segments: segs,
      tag: (json['tag'] ?? json['label'] ?? 'Optimal').toString(),
      isSimulated: json['is_simulated'] ?? false,
      disclaimer:
          (json['disclaimer'] ??
                  'Static GTFS schedule estimate (live tracking not verified)')
              .toString(),
      rankingExplanation: json['explanation']?.toString(),
    );
  }

  static TimeOfDay _parseTime(dynamic value) {
    if (value is String && value.contains(':')) {
      final parts = value.trim().split(' ');
      final timeParts = parts[0].split(':');
      int h = int.tryParse(timeParts[0]) ?? 8;
      int m = int.tryParse(timeParts[1]) ?? 0;
      if (parts.length > 1 && parts[1].toUpperCase() == 'PM' && h < 12) {
        h += 12;
      } else if (parts.length > 1 &&
          parts[1].toUpperCase() == 'AM' &&
          h == 12) {
        h = 0;
      }
      return TimeOfDay(hour: h, minute: m);
    }
    return const TimeOfDay(hour: 8, minute: 30);
  }
}
