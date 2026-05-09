import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/app_user.dart';
import '../models/checkin_message.dart';
import '../models/role.dart';

class CheckInApi {
  CheckInApi({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _baseUrl = (baseUrl ??
                const String.fromEnvironment(
                  'CHECKIN_API_BASE_URL',
                  defaultValue:
                      'https://asia-southeast1-checkin-c4d3a.cloudfunctions.net/api/api/v1',
                ))
            .replaceFirst(RegExp(r'/$'), '');

  final http.Client _client;
  final String _baseUrl;

  Future<AppUser> signUp({
    required Role role,
    required String userId,
    required String password,
    String displayName = '',
    String profileContext = '',
    String occupation = '',
  }) async {
    final response = await _post('/auth/signup', {
      'role': role == Role.senior ? 'senior' : 'caregiver',
      'user_id': userId,
      'password': password,
      'display_name': displayName,
      'profile_context': profileContext,
      'occupation': occupation,
    });
    return AppUser.fromApi(response['user'] as Map<String, dynamic>);
  }

  Future<AppUser> login({
    required String userId,
    required String password,
  }) async {
    final response = await _post('/auth/login', {
      'user_id': userId,
      'password': password,
    });
    return AppUser.fromApi(response['user'] as Map<String, dynamic>);
  }

  Future<TriageIngestResult> ingestTriage({
    required String seniorId,
    required String storagePath,
  }) async {
    final response = await _post('/triage/ingest', {
      'senior_id': seniorId,
      'storage_path': storagePath,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
    return TriageIngestResult(
      messageId: response['message_id'] as String? ?? '',
      status: response['status'] as String? ?? 'processing',
    );
  }

  Future<CheckInMessage> analyzeMessage(String messageId) async {
    final response = await _post('/triage/analyze', {
      'message_id': messageId,
    });
    return CheckInMessage.fromApi(response);
  }

  Future<CheckInMessage> transcribeMessage(String messageId) async {
    final response = await _post('/triage/transcribe', {
      'message_id': messageId,
    });
    return CheckInMessage.fromApi(response);
  }

  Future<CheckInMessage> runManualTriage({
    required String seniorId,
    required String storagePath,
  }) async {
    final ingest = await ingestTriage(
      seniorId: seniorId,
      storagePath: storagePath,
    );
    await transcribeMessage(ingest.messageId);
    return analyzeMessage(ingest.messageId);
  }

  Future<List<CheckInMessage>> fetchFeed({
    required String caregiverId,
    String status = 'unread',
    int limit = 20,
  }) async {
    final response = await _get('/messages/feed', {
      'caregiver_id': caregiverId,
      if (status.isNotEmpty) 'status': status,
      'limit': limit.toString(),
    });
    if (response is! List) {
      throw const CheckInApiException('Feed response was not a list.');
    }
    return response
        .whereType<Map<String, dynamic>>()
        .map(CheckInMessage.fromApi)
        .toList();
  }

  Future<void> updateMessageStatus({
    required String messageId,
    required String status,
    required String actionTaken,
  }) async {
    await _patch('/messages/$messageId/status', {
      'status': status,
      'action_taken': actionTaken,
    });
  }

  Future<String> linkSenior({
    required String caregiverId,
    required String seniorPairingCode,
  }) async {
    final response = await _post('/users/link', {
      'caregiver_id': caregiverId,
      'senior_pairing_code': seniorPairingCode,
    });
    return response['linked_senior_id'] as String? ?? '';
  }

  Future<void> updateSeniorContext({
    required String seniorId,
    required String routineContext,
  }) async {
    await _put('/users/$seniorId/context', {
      'routine_context': routineContext,
    });
  }

  Future<void> registerFcmToken({
    required String userId,
    required String token,
  }) async {
    await _post('/users/$userId/fcm-token', {
      'token': token,
    });
  }

  Future<dynamic> _get(String path, Map<String, String> query) async {
    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: query);
    return _decode(await _client.get(uri));
  }

  Future<Map<String, dynamic>> _post(
      String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$_baseUrl$path');
    final response = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    final decoded = _decode(response);
    if (decoded is! Map<String, dynamic>) {
      throw const CheckInApiException('Backend response was not an object.');
    }
    return decoded;
  }

  Future<Map<String, dynamic>> _patch(
      String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$_baseUrl$path');
    final response = await _client.patch(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    final decoded = _decode(response);
    if (decoded is! Map<String, dynamic>) {
      throw const CheckInApiException('Backend response was not an object.');
    }
    return decoded;
  }

  Future<Map<String, dynamic>> _put(
      String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$_baseUrl$path');
    final response = await _client.put(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    final decoded = _decode(response);
    if (decoded is! Map<String, dynamic>) {
      throw const CheckInApiException('Backend response was not an object.');
    }
    return decoded;
  }

  dynamic _decode(http.Response response) {
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = body is Map<String, dynamic>
          ? body['error'] as String? ?? body['detail'] as String?
          : null;
      throw CheckInApiException(
          message ?? 'Backend request failed (${response.statusCode}).');
    }
    return body;
  }
}

class TriageIngestResult {
  const TriageIngestResult({
    required this.messageId,
    required this.status,
  });

  final String messageId;
  final String status;
}

class CheckInApiException implements Exception {
  const CheckInApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
