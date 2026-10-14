import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/disruption_alert.dart';
import '../models/journey.dart';
import '../models/search_preferences.dart';
import '../models/transit_stop.dart';

class ApiResponse<T> {
  final T? data;
  final String? errorMessage;
  final int? statusCode;
  final bool isSuccess;
  final bool isFromFallback;
  final String? blockerDetail;

  const ApiResponse.success(this.data)
    : errorMessage = null,
      statusCode = 200,
      isSuccess = true,
      isFromFallback = false,
      blockerDetail = null;

  const ApiResponse.fallback(this.data, {this.errorMessage, this.blockerDetail})
    : statusCode = null,
      isSuccess = true,
      isFromFallback = true;

  const ApiResponse.error(
    this.errorMessage, {
    this.statusCode,
    this.blockerDetail,
  }) : data = null,
       isSuccess = false,
       isFromFallback = false;
}

class ApiClient {
  static final ApiClient instance = ApiClient._();
  ApiClient._();

  // Active in-flight requests to prevent duplicate submissions
  final Set<String> _inFlightRequests = {};

  // Base URL resolution
  static String get defaultBaseUrl {
    // Check compile-time environment variable first
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) return envUrl;

    if (kIsWeb) return 'http://localhost:8000';
    if (Platform.isAndroid) {
      // 10.0.2.2 is standard for Android Emulator reaching host machine
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

  String _baseUrl = defaultBaseUrl;
  String get baseUrl => _baseUrl;

  void setBaseUrl(String newUrl) {
    _baseUrl = newUrl.trim().replaceAll(RegExp(r'/+$'), '');
  }

  static const Duration requestTimeout = Duration(seconds: 6);

  Map<String, String> get _defaultHeaders => {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
  };

  // ==========================================
  // 1. GET /api/gtfs/stops
  // ==========================================
  Future<ApiResponse<List<TransitStop>>> getGtfsStops({
    String query = '',
    String? mode,
  }) async {
    final cacheKey = 'GET_STOPS_${query}_$mode';
    if (_inFlightRequests.contains(cacheKey)) {
      // Prevent duplicate parallel requests
      return const ApiResponse.error('A stop search is already in progress.');
    }
    _inFlightRequests.add(cacheKey);

    try {
      final queryParams = <String, String>{};
      if (query.trim().isNotEmpty) queryParams['query'] = query.trim();
      if (mode != null && mode.isNotEmpty) queryParams['mode'] = mode;

      final uri = Uri.parse(
        '$_baseUrl/api/gtfs/stops',
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await http
          .get(uri, headers: _defaultHeaders)
          .timeout(requestTimeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        List<dynamic> list;
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map<String, dynamic>) {
          list = (decoded['stops'] ?? decoded['data'] ?? []) as List<dynamic>;
        } else {
          list = [];
        }

        final stops = list
            .whereType<Map<String, dynamic>>()
            .map(TransitStop.fromJson)
            .toList();
        return ApiResponse.success(stops);
      } else {
        return ApiResponse.error(
          'Failed to load stops from server (HTTP ${response.statusCode}).',
          statusCode: response.statusCode,
          blockerDetail:
              'GET /api/gtfs/stops returned status ${response.statusCode}: ${response.body}',
        );
      }
    } on TimeoutException {
      return ApiResponse.error(
        'Connection timed out while fetching transit stops. Backend at $_baseUrl did not respond.',
        blockerDetail:
            'Request to $_baseUrl/api/gtfs/stops timed out after 6s.',
      );
    } on SocketException catch (e) {
      return ApiResponse.error(
        'Could not connect to transit server. Please check your network or server URL.',
        blockerDetail: 'SocketException: Failed to connect to $_baseUrl ($e).',
      );
    } on FormatException {
      return const ApiResponse.error(
        'Received invalid response format from stops service.',
        blockerDetail: 'JSON parsing failed on response body.',
      );
    } catch (e) {
      return ApiResponse.error(
        'An unexpected error occurred while searching stops.',
        blockerDetail: e.toString(),
      );
    } finally {
      _inFlightRequests.remove(cacheKey);
    }
  }

  // ==========================================
  // 2. POST /api/gtfs/journeys/search & /api/journeys/search
  // ==========================================
  Future<ApiResponse<List<Journey>>> searchJourneys({
    required TransitStop origin,
    required TransitStop destination,
    required SearchPreferences preferences,
  }) async {
    final cacheKey =
        'POST_JOURNEYS_${origin.id}_${destination.id}_${preferences.formattedDate}';
    if (_inFlightRequests.contains(cacheKey)) {
      return const ApiResponse.error(
        'Journey search already in progress. Please wait...',
      );
    }
    _inFlightRequests.add(cacheKey);

    // Required Contract payload: send travelDate in YYYY-MM-DD format (not date)
    final payload = {
      'origin': origin.id,
      'origin_id': origin.id,
      'origin_name': origin.name,
      'destination': destination.id,
      'destination_id': destination.id,
      'destination_name': destination.name,
      'travelDate': preferences.formattedDate, // YYYY-MM-DD
      'departureTime': preferences.formattedTime, // HH:mm
      'preference': preferences.preference,
      if (preferences.maxTransfers != null)
        'maxTransfers': preferences.maxTransfers,
      if (preferences.maxBudget != null) 'maxBudget': preferences.maxBudget,
    };

    try {
      // First try /api/gtfs/journeys/search
      http.Response response;
      String endpointUsed = '/api/gtfs/journeys/search';
      try {
        final uriGtfs = Uri.parse('$_baseUrl/api/gtfs/journeys/search');
        response = await http
            .post(uriGtfs, headers: _defaultHeaders, body: jsonEncode(payload))
            .timeout(requestTimeout);

        // If 404, fall back to /api/journeys/search
        if (response.statusCode == 404) {
          endpointUsed = '/api/journeys/search';
          final uriGeneral = Uri.parse('$_baseUrl/api/journeys/search');
          response = await http
              .post(
                uriGeneral,
                headers: _defaultHeaders,
                body: jsonEncode(payload),
              )
              .timeout(requestTimeout);
        }
      } catch (networkErr) {
        // Rethrow to outer handler
        rethrow;
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        List<dynamic> list;
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map<String, dynamic>) {
          list =
              (decoded['journeys'] ??
                      decoded['results'] ??
                      decoded['options'] ??
                      [])
                  as List<dynamic>;
        } else {
          list = [];
        }

        final journeys = list
            .whereType<Map<String, dynamic>>()
            .map(
              (j) => Journey.fromJson(
                j,
                defaultOrigin: origin,
                defaultDest: destination,
              ),
            )
            .toList();

        return ApiResponse.success(journeys);
      } else {
        return ApiResponse.error(
          'Journey search service returned an error (HTTP ${response.statusCode}).',
          statusCode: response.statusCode,
          blockerDetail:
              'Endpoint $endpointUsed returned ${response.statusCode}: ${response.body}',
        );
      }
    } on TimeoutException {
      return ApiResponse.error(
        'Journey search request timed out.',
        blockerDetail:
            'TimeoutException: Backend at $_baseUrl did not respond within 6s.',
      );
    } on SocketException catch (e) {
      return ApiResponse.error(
        'Could not connect to transit server. Please verify backend availability.',
        blockerDetail: 'SocketException connecting to $_baseUrl: $e',
      );
    } on FormatException {
      return const ApiResponse.error(
        'Received invalid JSON payload from journey planner.',
        blockerDetail: 'FormatException during JSON decode.',
      );
    } catch (e) {
      return ApiResponse.error(
        'Journey search encountered an unexpected problem.',
        blockerDetail: e.toString(),
      );
    } finally {
      _inFlightRequests.remove(cacheKey);
    }
  }

  // ==========================================
  // 3. /api/journeys/alternatives & /api/recovery/recommendations
  // ==========================================
  Future<ApiResponse<List<DisruptionAlert>>> getDisruptionsAndRecovery({
    String? journeyId,
  }) async {
    try {
      // 1. Check /api/journeys/alternatives
      final altUri = Uri.parse('$_baseUrl/api/journeys/alternatives').replace(
        queryParameters: journeyId != null ? {'journey_id': journeyId} : null,
      );

      final altRes = await http
          .get(altUri, headers: _defaultHeaders)
          .timeout(const Duration(seconds: 4));

      if (altRes.statusCode == 200) {
        final decoded = jsonDecode(altRes.body);
        // Parse alerts if present
        if (decoded is List) {
          // parse list
        }
      } else if (altRes.statusCode == 404) {
        // Report exact blocker
        return ApiResponse.error(
          'Disruption alternatives service is not currently active on this server.',
          statusCode: 404,
          blockerDetail:
              'Endpoint /api/journeys/alternatives returned 404 Not Found at $_baseUrl.',
        );
      }

      // 2. Check /api/recovery/recommendations
      final recUri = Uri.parse('$_baseUrl/api/recovery/recommendations');
      final recRes = await http
          .get(recUri, headers: _defaultHeaders)
          .timeout(const Duration(seconds: 4));

      if (recRes.statusCode == 404) {
        return ApiResponse.error(
          'Recovery recommendation service is not deployed on this server.',
          statusCode: 404,
          blockerDetail:
              'Endpoint /api/recovery/recommendations returned 404 Not Found at $_baseUrl.',
        );
      }

      return const ApiResponse.success([]);
    } on SocketException catch (e) {
      return ApiResponse.error(
        'Backend server is not reachable.',
        blockerDetail:
            'SocketException: Could not connect to $_baseUrl for disruption/recovery contracts ($e).',
      );
    } on TimeoutException {
      return ApiResponse.error(
        'Disruption check timed out.',
        blockerDetail:
            'TimeoutException connecting to $_baseUrl/api/journeys/alternatives.',
      );
    } catch (e) {
      return ApiResponse.error(
        'Could not verify disruption recovery services.',
        blockerDetail: e.toString(),
      );
    }
  }
}
