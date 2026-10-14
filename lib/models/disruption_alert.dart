import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import 'transit_stop.dart';

enum DisruptionSeverity { advisory, warning, critical }

extension DisruptionSeverityExtension on DisruptionSeverity {
  Color get color {
    switch (this) {
      case DisruptionSeverity.advisory:
        return const Color(0xFF0284C7);
      case DisruptionSeverity.warning:
        return SafarTokens.alertAmber;
      case DisruptionSeverity.critical:
        return SafarTokens.accentCoral;
    }
  }

  String get label {
    switch (this) {
      case DisruptionSeverity.advisory:
        return 'Service Advisory';
      case DisruptionSeverity.warning:
        return 'Service Disruption';
      case DisruptionSeverity.critical:
        return 'Line Suspended';
    }
  }
}

class DisruptionAlert {
  final String id;
  final String title;
  final String affectedService;
  final TransitMode mode;
  final DisruptionSeverity severity;
  final String description;
  final String commuterImpact;
  final String lastUpdatedText;
  final bool isVerified;
  final String? alternativeActionLabel;

  const DisruptionAlert({
    required this.id,
    required this.title,
    required this.affectedService,
    required this.mode,
    required this.severity,
    required this.description,
    required this.commuterImpact,
    required this.lastUpdatedText,
    this.isVerified = false,
    this.alternativeActionLabel,
  });
}
