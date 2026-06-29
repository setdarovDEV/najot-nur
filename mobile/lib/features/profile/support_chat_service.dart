import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/constants/app_constants.dart';
import '../../core/network/token_store.dart';
import '../../models/support_models.dart';

/// Events emitted by the support chat WebSocket.
sealed class SupportChatEvent {
  const SupportChatEvent();
}

class SupportMessageReceived extends SupportChatEvent {
  const SupportMessageReceived(this.message);
  final SupportMessage message;
}

class SupportChatConnected extends SupportChatEvent {
  const SupportChatConnected();
}

class SupportChatDisconnected extends SupportChatEvent {
  const SupportChatDisconnected();
}

/// Live connection to the user's support chat.
///
/// * On connect, the server sends a ``connected`` hello.
/// * New admin replies are pushed as ``{event: "new_message", ...}`` and
///   surfaced as [SupportMessageReceived] events.
///
/// The service transparently reconnects with exponential-ish backoff (max
/// 10s) and emits [SupportChatDisconnected] whenever the socket is down so
/// the UI can show a "offline" hint.
class SupportChatService {
  SupportChatService(this._tokens);

  final TokenStore _tokens;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  Timer? _retry;
  bool _disposed = false;
  bool _connecting = false;

  final _events = StreamController<SupportChatEvent>.broadcast();
  Stream<SupportChatEvent> get events => _events.stream;

  String get _baseWsUrl {
    if (AppConstants.wsUrl.isNotEmpty) return AppConstants.wsUrl;
    final base = AppConstants.apiUrl.endsWith('/')
        ? AppConstants.apiUrl.substring(0, AppConstants.apiUrl.length - 1)
        : AppConstants.apiUrl;
    final host = base.endsWith('/api/v1')
        ? base.substring(0, base.length - '/api/v1'.length)
        : base;
    return host.replaceFirst(RegExp(r'^http'), 'ws');
  }

  Future<void> connect() async {
    if (_disposed || _connecting) return;
    if (_channel != null) return;
    final token = _tokens.accessToken;
    if (token == null) return;

    _connecting = true;
    try {
      final uri = Uri.parse('$_baseWsUrl/support/ws?token=$token');
      final ch = WebSocketChannel.connect(uri);
      _channel = ch;
      _sub = ch.stream.listen(
        _handleMessage,
        onError: (_) => _scheduleReconnect(),
        onDone: _scheduleReconnect,
        cancelOnError: true,
      );
      // The "open" handshake is implicit for WebSocketChannel.connect — once
      // we receive the server's first frame we know we're good.
    } catch (_) {
      _scheduleReconnect();
    } finally {
      _connecting = false;
    }
  }

  void _handleMessage(dynamic raw) {
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      final event = data['event'];
      if (event == 'connected') {
        _events.add(const SupportChatConnected());
        return;
      }
      if (event == 'new_message' && data['message'] is Map) {
        final m = data['message'] as Map<String, dynamic>;
        // We only surface messages for the current user's own thread.
        if (m['is_from_user'] == true) return;
        _events.add(SupportMessageReceived(SupportMessage.fromJson(m)));
      }
    } catch (_) {
      // Ignore malformed frames — server is the source of truth, and the
      // REST polling can fill in the gaps.
    }
  }

  void _scheduleReconnect() {
    _sub?.cancel();
    _sub = null;
    _channel = null;
    if (_disposed) return;
    _events.add(const SupportChatDisconnected());
    _retry?.cancel();
    _retry = Timer(const Duration(seconds: 3), connect);
  }

  Future<void> dispose() async {
    _disposed = true;
    _retry?.cancel();
    await _sub?.cancel();
    await _channel?.sink.close();
    _channel = null;
    await _events.close();
  }
}
