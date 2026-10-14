import 'package:flutter/material.dart';
import '../theme/tokens.dart';

enum TransitMode { suburban, metro, mrts, bus, walk }

extension TransitModeExtension on TransitMode {
  String get label {
    switch (this) {
      case TransitMode.suburban:
        return 'Suburban Rail';
      case TransitMode.metro:
        return 'Chennai Metro';
      case TransitMode.mrts:
        return 'MRTS';
      case TransitMode.bus:
        return 'MTC Bus';
      case TransitMode.walk:
        return 'Walk';
    }
  }

  IconData get icon {
    switch (this) {
      case TransitMode.suburban:
        return Icons.train_rounded;
      case TransitMode.metro:
        return Icons.subway_rounded;
      case TransitMode.mrts:
        return Icons.tram_rounded;
      case TransitMode.bus:
        return Icons.directions_bus_rounded;
      case TransitMode.walk:
        return Icons.directions_walk_rounded;
    }
  }

  Color get color {
    switch (this) {
      case TransitMode.suburban:
        return SafarTokens.modeSuburban;
      case TransitMode.metro:
        return SafarTokens.modeMetro;
      case TransitMode.mrts:
        return SafarTokens.modeMrts;
      case TransitMode.bus:
        return SafarTokens.modeBus;
      case TransitMode.walk:
        return SafarTokens.modeWalk;
    }
  }
}

class TransitStop {
  final String id;
  final String name;
  final String? tamilName;
  final String code;
  final TransitMode primaryMode;
  final String hubDescription;
  final bool isInterchange;
  final List<String> availableLines;

  const TransitStop({
    required this.id,
    required this.name,
    this.tamilName,
    required this.code,
    required this.primaryMode,
    required this.hubDescription,
    this.isInterchange = false,
    this.availableLines = const [],
  });

  factory TransitStop.fromJson(Map<String, dynamic> json) {
    final id = (json['stop_id'] ?? json['id'] ?? json['code'] ?? '').toString();
    final name = (json['stop_name'] ?? json['name'] ?? 'Transit Stop')
        .toString();
    final tamilName = (json['tamil_name'] ?? json['tamilName']) as String?;
    final code = (json['stop_code'] ?? json['code'] ?? id).toString();

    final modeStr =
        (json['mode'] ?? json['primary_mode'] ?? json['vehicle_type'] ?? '')
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
    } else if (modeStr.contains('suburban') ||
        modeStr.contains('rail') ||
        modeStr.contains('train')) {
      mode = TransitMode.suburban;
    }

    final hubDesc =
        (json['hub_description'] ??
                json['description'] ??
                json['hubDescription'] ??
                'Chennai Transit Stop')
            .toString();
    final isInterchange =
        json['is_interchange'] == true || json['isInterchange'] == true;

    final linesRaw = json['available_lines'] ?? json['lines'] ?? json['routes'];
    List<String> lines = [];
    if (linesRaw is List) {
      lines = linesRaw.map((e) => e.toString()).toList();
    }

    return TransitStop(
      id: id.isNotEmpty ? id : name.toUpperCase().replaceAll(' ', '_'),
      name: name,
      tamilName: tamilName,
      code: code.isNotEmpty
          ? code
          : (name.length >= 3 ? name.substring(0, 3).toUpperCase() : name),
      primaryMode: mode,
      hubDescription: hubDesc,
      isInterchange: isInterchange,
      availableLines: lines,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stop_id': id,
      'stop_name': name,
      if (tamilName != null) 'tamil_name': tamilName,
      'stop_code': code,
      'mode': primaryMode.name,
      'hub_description': hubDescription,
      'is_interchange': isInterchange,
      'available_lines': availableLines,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransitStop &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
