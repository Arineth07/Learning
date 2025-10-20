import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../utils/constants.dart';
import '../utils/result.dart';
import '../utils/failures.dart';

class ApiClient {
  ApiClient._internal();

  static final ApiClient instance = ApiClient._internal();

  factory ApiClient() => instance;

  String _baseUrl = SyncConstants.baseUrl;
  String? _authToken;
  http.Client _httpClient = http.Client();

  void setBaseUrl(String url) => _baseUrl = url;
  void setAuthToken(String? token) => _authToken = token;
  void setHttpClient(http.Client client) => _httpClient = client;

  Uri _buildUri(String endpoint) {
    final cleanedBase = _baseUrl.endsWith('/')
        ? _baseUrl.substring(0, _baseUrl.length - 1)
        : _baseUrl;
    final path =
        '/api/${SyncConstants.apiVersion}${endpoint.startsWith('/') ? endpoint : '/$endpoint'}';
    return Uri.parse('$cleanedBase$path');
  }

  Map<String, String> _buildHeaders(Map<String, String>? customHeaders) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    if (customHeaders != null) headers.addAll(customHeaders);
    return headers;
  }

  Future<Result<Map<String, dynamic>>> get(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(endpoint);
    try {
      final resp = await _httpClient
          .get(uri, headers: _buildHeaders(headers))
          .timeout(SyncConstants.apiTimeout);
      return _handleResponse(resp);
    } on SocketException catch (e, st) {
      return Result.error(
        ConnectivityFailure('Network error: $e', cause: e, stackTrace: st),
      );
    } on TimeoutException catch (e, st) {
      return Result.error(
        TimeoutFailure('Request timed out: $e', cause: e, stackTrace: st),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure('Unexpected error: $e', cause: e, stackTrace: st),
      );
    }
  }

  Future<Result<Map<String, dynamic>>> post(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(endpoint);
    try {
      final resp = await _httpClient
          .post(uri, headers: _buildHeaders(headers), body: jsonEncode(body))
          .timeout(SyncConstants.apiTimeout);
      return _handleResponse(resp);
    } on SocketException catch (e, st) {
      return Result.error(
        ConnectivityFailure('Network error: $e', cause: e, stackTrace: st),
      );
    } on TimeoutException catch (e, st) {
      return Result.error(
        TimeoutFailure('Request timed out: $e', cause: e, stackTrace: st),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure('Unexpected error: $e', cause: e, stackTrace: st),
      );
    }
  }

  Future<Result<Map<String, dynamic>>> put(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(endpoint);
    try {
      final resp = await _httpClient
          .put(uri, headers: _buildHeaders(headers), body: jsonEncode(body))
          .timeout(SyncConstants.apiTimeout);
      return _handleResponse(resp);
    } on SocketException catch (e, st) {
      return Result.error(
        ConnectivityFailure('Network error: $e', cause: e, stackTrace: st),
      );
    } on TimeoutException catch (e, st) {
      return Result.error(
        TimeoutFailure('Request timed out: $e', cause: e, stackTrace: st),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure('Unexpected error: $e', cause: e, stackTrace: st),
      );
    }
  }

  Future<Result<void>> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(endpoint);
    try {
      final resp = await _httpClient
          .delete(uri, headers: _buildHeaders(headers))
          .timeout(SyncConstants.apiTimeout);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return const Result.success(null);
      }
      final failure = _mapHttpError(resp);
      return Result.error(failure);
    } on SocketException catch (e, st) {
      return Result.error(
        ConnectivityFailure('Network error: $e', cause: e, stackTrace: st),
      );
    } on TimeoutException catch (e, st) {
      return Result.error(
        TimeoutFailure('Request timed out: $e', cause: e, stackTrace: st),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure('Unexpected error: $e', cause: e, stackTrace: st),
      );
    }
  }

  Future<Result<Map<String, dynamic>>> postBatch(
    String endpoint,
    List<Map<String, dynamic>> items, {
    Map<String, String>? headers,
  }) async {
    if (items.length > SyncConstants.maxItemsPerBatch) {
      return Result.error(
        ValidationFailure(
          'Batch size ${items.length} exceeds max ${SyncConstants.maxItemsPerBatch}',
        ),
      );
    }
    final body = {'items': items, 'count': items.length};
    return post(endpoint, body, headers: headers);
  }

  // Cloud AI specific endpoints
  Future<Result<Map<String, dynamic>>> getCloudTopicRecommendation(
    Map<String, dynamic> requestBody,
  ) async {
    // Validate request before making the call
    final validation = _validateCloudAIRequest(
      requestBody,
      requiredFields: const ['userId', 'subjectId'],
    );
    if (!validation.isSuccess) return validation;
    return _retryCloudAIRequest(() async {
      try {
        final uri = _buildUri(CloudAIConstants.recommendTopicEndpoint);
        final resp = await _httpClient
            .post(
              uri,
              headers: _buildHeaders(null),
              body: jsonEncode(requestBody),
            )
            .timeout(CloudAIConstants.cloudAITimeout);
        return _handleResponse(resp);
      } on TimeoutException catch (e, st) {
        return Result.error(
          TimeoutFailure('Cloud AI timed out: $e', cause: e, stackTrace: st),
        );
      } on SocketException catch (e, st) {
        return Result.error(
          ConnectivityFailure(
            'Cloud AI network error: $e',
            cause: e,
            stackTrace: st,
          ),
        );
      } catch (e, st) {
        return Result.error(
          UnknownFailure(
            'Cloud AI unexpected error: $e',
            cause: e,
            stackTrace: st,
          ),
        );
      }
    });
  }

  Future<Result<Map<String, dynamic>>> getCloudPracticeRecommendation(
    Map<String, dynamic> requestBody,
  ) async {
    final validation = _validateCloudAIRequest(
      requestBody,
      requiredFields: const ['userId', 'topicId'],
    );
    if (!validation.isSuccess) return validation;
    return _retryCloudAIRequest(() async {
      try {
        final uri = _buildUri(CloudAIConstants.recommendPracticeEndpoint);
        final resp = await _httpClient
            .post(
              uri,
              headers: _buildHeaders(null),
              body: jsonEncode(requestBody),
            )
            .timeout(CloudAIConstants.cloudAITimeout);
        return _handleResponse(resp);
      } on TimeoutException catch (e, st) {
        return Result.error(
          TimeoutFailure('Cloud AI timed out: $e', cause: e, stackTrace: st),
        );
      } on SocketException catch (e, st) {
        return Result.error(
          ConnectivityFailure(
            'Cloud AI network error: $e',
            cause: e,
            stackTrace: st,
          ),
        );
      } catch (e, st) {
        return Result.error(
          UnknownFailure(
            'Cloud AI unexpected error: $e',
            cause: e,
            stackTrace: st,
          ),
        );
      }
    });
  }

  Future<Result<Map<String, dynamic>>> getCloudLearningPath(
    Map<String, dynamic> requestBody,
  ) async {
    final validation = _validateCloudAIRequest(
      requestBody,
      requiredFields: const ['userId', 'subjectId'],
    );
    if (!validation.isSuccess) return validation;
    return _retryCloudAIRequest(() async {
      try {
        final uri = _buildUri(CloudAIConstants.generatePathEndpoint);
        final resp = await _httpClient
            .post(
              uri,
              headers: _buildHeaders(null),
              body: jsonEncode(requestBody),
            )
            .timeout(CloudAIConstants.cloudAITimeout);
        return _handleResponse(resp);
      } on TimeoutException catch (e, st) {
        return Result.error(
          TimeoutFailure('Cloud AI timed out: $e', cause: e, stackTrace: st),
        );
      } on SocketException catch (e, st) {
        return Result.error(
          ConnectivityFailure(
            'Cloud AI network error: $e',
            cause: e,
            stackTrace: st,
          ),
        );
      } catch (e, st) {
        return Result.error(
          UnknownFailure(
            'Cloud AI unexpected error: $e',
            cause: e,
            stackTrace: st,
          ),
        );
      }
    });
  }

  Future<Result<Map<String, dynamic>>> getCloudAnalytics(
    Map<String, dynamic> requestBody,
  ) async {
    final validation = _validateCloudAIRequest(
      requestBody,
      requiredFields: const ['userId'],
    );
    if (!validation.isSuccess) return validation;
    return _retryCloudAIRequest(() async {
      try {
        final uri = _buildUri(CloudAIConstants.analyzePerformanceEndpoint);
        final resp = await _httpClient
            .post(
              uri,
              headers: _buildHeaders(null),
              body: jsonEncode(requestBody),
            )
            .timeout(CloudAIConstants.cloudAITimeout);
        return _handleResponse(resp);
      } on TimeoutException catch (e, st) {
        return Result.error(
          TimeoutFailure('Cloud AI timed out: $e', cause: e, stackTrace: st),
        );
      } on SocketException catch (e, st) {
        return Result.error(
          ConnectivityFailure(
            'Cloud AI network error: $e',
            cause: e,
            stackTrace: st,
          ),
        );
      } catch (e, st) {
        return Result.error(
          UnknownFailure(
            'Cloud AI unexpected error: $e',
            cause: e,
            stackTrace: st,
          ),
        );
      }
    });
  }

  Future<Result<Map<String, dynamic>>> _retryCloudAIRequest(
    Future<Result<Map<String, dynamic>>> Function() requestFn,
  ) async {
    Result<Map<String, dynamic>> lastResult = const Result.error(
      UnknownFailure('No attempts made'),
    );
    int attempts = 0;
    const maxAttempts = (CloudAIConstants.maxCloudAIRetries <= 0)
        ? 1
        : (CloudAIConstants.maxCloudAIRetries + 1);
    while (attempts < maxAttempts) {
      attempts += 1;
      final res = await requestFn();
      lastResult = res;
      if (res.isSuccess) return res;
      if (attempts >= maxAttempts) break;
      final delay = Duration(seconds: 1 << (attempts - 1));
      await Future.delayed(delay);
    }
    return lastResult;
  }

  Result<Map<String, dynamic>> _handleResponse(http.Response resp) {
    try {
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        if (resp.body.isEmpty) return const Result.success(<String, dynamic>{});
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return Result.success(data);
      }
      return Result.error(_mapHttpError(resp));
    } catch (e, st) {
      return Result.error(
        SerializationFailure(
          'Failed to parse response: $e',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  Failure _mapHttpError(http.Response response) {
    final code = response.statusCode;
    final body = response.body;
    String message = 'HTTP $code';
    try {
      final parsed = body.isNotEmpty ? jsonDecode(body) : null;
      if (parsed is Map && parsed['message'] != null) {
        message = parsed['message'].toString();
      }
    } catch (_) {}

    if (code == 400) return ValidationFailure('Bad request: $message');
    if (code == 401 || code == 403) {
      return AuthenticationFailure('Authentication failed: $message');
    }
    if (code == 404) return NotFoundFailure('Not found: $message');
    if (code == 409) return ConflictFailure('Conflict: $message');
    if (code == 429) return RateLimitFailure('Rate limited: $message');
    if (code >= 500 && code < 600) {
      return ServerFailure('Server error: $message');
    }
    return UnknownFailure('Unexpected HTTP status $code: $message');
  }

  void dispose() {
    try {
      _httpClient.close();
    } catch (_) {}
  }

  // Validate Cloud AI request payloads to avoid sending malformed requests.
  // Ensures required keys are present and truncates/validates certain array sizes.
  Result<Map<String, dynamic>> _validateCloudAIRequest(
    Map<String, dynamic> body, {
    List<String>? requiredFields,
  }) {
    try {
      requiredFields ??= [];
      for (final f in requiredFields) {
        if (!body.containsKey(f) ||
            body[f] == null ||
            (body[f] is String && (body[f] as String).isEmpty)) {
          return Result.error(
            ValidationFailure('Cloud AI request missing required field: $f'),
          );
        }
      }

      // Enforce max history/session items to send if present
      if (body.containsKey('performanceHistory') &&
          body['performanceHistory'] is List) {
        final List perf = body['performanceHistory'] as List;
        if (perf.length > CloudAIConstants.maxHistorySessionsToSend) {
          // Truncate in-place to limit payload size
          body['performanceHistory'] = perf
              .take(CloudAIConstants.maxHistorySessionsToSend)
              .toList();
        }
      }

      // If 'topics' is provided, ensure it's a list and not too large
      if (body.containsKey('topics') && body['topics'] is List) {
        final List t = body['topics'] as List;
        if (t.length > RecommendationConstants.maxLearningPathLength) {
          body['topics'] = t
              .take(RecommendationConstants.maxLearningPathLength)
              .toList();
        }
      }

      return Result.success(body);
    } catch (e, st) {
      return Result.error(
        ValidationFailure(
          'Invalid Cloud AI request: $e',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }
}
