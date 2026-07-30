import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'chat_db.dart';
import 'chat_service.dart';

/// Callback fired when the outbox successfully delivers a pending message.
/// [localId] is the temp UUID, [serverId] is the real ID returned by the server.
typedef OnMessageDelivered = void Function(String localId, String serverId);

/// Manages the local outbox: queues messages that couldn't be delivered
/// (backend cold-start, network loss) and retries them automatically.
///
/// Retry strategy: exponential backoff capped at 30 s.
/// Flush is triggered on:
///   - App start (via [start])
///   - Connectivity restored
///   - Periodic timer (30 s) while queue is non-empty
class OutboxService {
  static StreamSubscription? _connectivitySub;
  static Timer? _retryTimer;
  static bool _flushing = false;
  static int _backoffSeconds = 5;

  /// Optional callback so the active chat screen can update its UI
  /// when a pending message is confirmed by the server.
  static OnMessageDelivered? onMessageDelivered;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  /// Call once on app start (after AuthService.init).
  static Future<void> start() async {
    // Attempt to flush any pending messages left over from last session.
    _scheduleFlush(delay: const Duration(seconds: 2));

    // Re-flush whenever connectivity is restored.
    _connectivitySub = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final hasConnection =
          results.any((r) => r != ConnectivityResult.none);
      if (hasConnection) {
        print('[Outbox] Connectivity restored — flushing queue');
        _scheduleFlush();
      }
    });
  }

  static void stop() {
    _connectivitySub?.cancel();
    _retryTimer?.cancel();
    _flushing = false;
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  static void _scheduleFlush({Duration delay = Duration.zero}) {
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, _flush);
  }

  /// Attempts to deliver all pending messages oldest-first.
  static Future<void> _flush() async {
    if (_flushing) return;
    _flushing = true;

    try {
      final pending = await ChatDB.getPendingMessages();
      if (pending.isEmpty) {
        _flushing = false;
        return;
      }

      // Server is up — reset backoff and flush.
      _backoffSeconds = 5;

      for (final msg in pending) {
        final serverId = await ChatService.sendMessageHttp(
          msg.conversationId,
          msg.content,
        );

        if (serverId != null) {
          await ChatDB.updateMessageStatus(msg.id, serverId, 'sent');
          onMessageDelivered?.call(msg.id, serverId);
          print('[Outbox] Delivered ${msg.id} → $serverId');
        } else {
          print('[Outbox] Failed to deliver ${msg.id}, will retry');
        }
      }

      // If there are still pending items (some failed), schedule another retry.
      final remaining = await ChatDB.getPendingMessages();
      if (remaining.isNotEmpty) {
        _scheduleFlush(delay: Duration(seconds: _backoffSeconds));
        _backoffSeconds = (_backoffSeconds * 2).clamp(5, 30);
      }
    } catch (e) {
      print('[Outbox] Flush error: $e');
    } finally {
      _flushing = false;
    }
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Call after any message send fails to trigger an immediate retry cycle.
  static void notifyFailed() {
    _scheduleFlush(delay: Duration(seconds: _backoffSeconds));
  }

  /// Manually trigger a flush (e.g., when the chat screen comes into focus).
  static Future<void> flush() => _flush();
}
