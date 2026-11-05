import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:flutter_hbb/utils/http_service.dart' as http;

import '../common.dart';

class SessionTracker {
  static final Map<String, Timer> _heartbeatTimers = {};

  static void start(String remoteId) {
    if (remoteId.isEmpty) return;
    stopHeartbeat(remoteId);

    // Envia heartbeat a cada 60 segundos
    _heartbeatTimers[remoteId] =
        Timer.periodic(const Duration(seconds: 60), (_) async {
      await _sendHeartbeat(remoteId);
    });
  }

  static void stopHeartbeat(String remoteId) {
    final timer = _heartbeatTimers.remove(remoteId);
    timer?.cancel();
  }

  static Future<void> _sendHeartbeat(String remoteId) async {
    final token = bind.mainGetLocalOption(key: 'access_token');
    if (token.isEmpty) return;

    try {
      final apiServer = await bind.mainGetApiServer();
      final myId = await bind.mainGetMyId();
      final uuid = await bind.mainGetUuid();
      await http
          .post(
            Uri.parse('$apiServer/api/session/heartbeat'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'local_id': myId,
              'remote_id': remoteId,
              'uuid': uuid,
            }),
          )
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('[SessionTracker] heartbeat warning for $remoteId: $e');
    }
  }

  static Future<void> end(String remoteId) async {
    stopHeartbeat(remoteId);

    final token = bind.mainGetLocalOption(key: 'access_token');
    if (token.isEmpty) return;

    try {
      final apiServer = await bind.mainGetApiServer();
      final myId = await bind.mainGetMyId();
      final uuid = await bind.mainGetUuid();
      await http
          .post(
            Uri.parse('$apiServer/api/session/end'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'local_id': myId,
              'remote_id': remoteId,
              'uuid': uuid,
            }),
          )
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('[SessionTracker] session end warning for $remoteId: $e');
    }
  }
}
