import 'package:flutter/material.dart';

class SearchPreferences {
  final DateTime travelDate;
  final TimeOfDay travelTime;
  final String preference; // 'fastest', 'cheapest', 'fewest_transfers'
  final int? maxTransfers;
  final int? maxBudget;

  const SearchPreferences({
    required this.travelDate,
    required this.travelTime,
    this.preference = 'fastest',
    this.maxTransfers,
    this.maxBudget,
  });

  /// Formatted YYYY-MM-DD for backend GTFS contract
  String get formattedDate {
    final year = travelDate.year.toString().padLeft(4, '0');
    final month = travelDate.month.toString().padLeft(2, '0');
    final day = travelDate.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Formatted HH:mm (24-hr) for backend contract
  String get formattedTime {
    final hour = travelTime.hour.toString().padLeft(2, '0');
    final minute = travelTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Display string for user in 12-hr format
  String get displayTime {
    final period = travelTime.hour >= 12 ? 'PM' : 'AM';
    final hour = travelTime.hourOfPeriod == 0 ? 12 : travelTime.hourOfPeriod;
    final minute = travelTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  SearchPreferences copyWith({
    DateTime? travelDate,
    TimeOfDay? travelTime,
    String? preference,
    int? maxTransfers,
    int? maxBudget,
    bool clearMaxTransfers = false,
    bool clearMaxBudget = false,
  }) {
    return SearchPreferences(
      travelDate: travelDate ?? this.travelDate,
      travelTime: travelTime ?? this.travelTime,
      preference: preference ?? this.preference,
      maxTransfers: clearMaxTransfers
          ? null
          : (maxTransfers ?? this.maxTransfers),
      maxBudget: clearMaxBudget ? null : (maxBudget ?? this.maxBudget),
    );
  }
}
