import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'auth_service.dart';

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isMe;
  /// Message delivery status: 'pending' | 'sent' | 'delivered' | 'read' | 'failed'
  final String status;
  /// True while the message hasn't been confirmed by the server yet.
  final bool localOnly;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.isMe,
    this.status = 'sent',
    this.localOnly = false,
  });

  ChatMessage copyWith({
    String? id,
    String? status,
    bool? localOnly,
  }) =>
      ChatMessage(
        id: id ?? this.id,
        conversationId: conversationId,
        senderId: senderId,
        text: text,
        timestamp: timestamp,
        isMe: isMe,
        status: status ?? this.status,
        localOnly: localOnly ?? this.localOnly,
      );
}

class ChatService {
  static const String chatUrl = 'https://frnd-chat-a2cm.onrender.com';
  static const String apiBase = 'https://frnd-api-n3hv.onrender.com/api';

  static IO.Socket? _socket;
  static final Map<String, enc.Encrypter> _encrypters = {};

  // Callbacks
  static Function(ChatMessage)? onMessageReceived;
  static Function(String, DateTime)? onMessageSent;
  static Function(String)? onError;

  static String? _currentConversationId;
  static Timer? _heartbeatTimer;

  // ── Encryption ──────────────────────────────────────────────────────────────

  static enc.Encrypter _getEncrypter(String conversationId) {
    if (_encrypters.containsKey(conversationId)) {
      return _encrypters[conversationId]!;
    }
    final bytes = utf8.encode(conversationId);
    final digest = sha256.convert(bytes);
    final key = enc.Key(Uint8List.fromList(digest.bytes));
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
    _encrypters[conversationId] = encrypter;
    return encrypter;
  }


  static String? _decrypt(String conversationId, String ciphertext, String ivBase64) {
    try {
      final encrypter = _getEncrypter(conversationId);
      final iv = enc.IV.fromBase64(ivBase64);
      return encrypter.decrypt64(ciphertext, iv: iv);
    } catch (e) {
      print('ChatService: Decryption error: $e');
      return null;
    }
  }

  // ── REST: Fetch message history ──────────────────────────────────────────────

  /// Fetches message history from the server.
  /// 
  /// The backend only supports page-based pagination (?page=&limit=).
  /// We use this for both the initial full fetch and "load older" pages.
  /// [page] is 1-indexed.
  static Future<List<ChatMessage>> fetchHistory(
    String conversationId, {
    required String myUserId,
    int page = 1,
    int limit = 30,
  }) async {
    try {
      final token = AuthService.token;
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'cookie': token,
      };

      final url = Uri.parse(
        '$apiBase/conversations/$conversationId/messages?page=$page&limit=$limit',
      );

      final response = await http.get(url, headers: headers);
      print('ChatService: History status=${response.statusCode} page=$page');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List rawMessages = data['messages'] ?? [];

        final messages = <ChatMessage>[];
        for (final raw in rawMessages) {
          final convId = raw['conversationId'] as String? ?? conversationId;
          final senderId = raw['senderId'] as String? ?? '';
          final ciphertext = raw['ciphertext'] as String?;
          final ivBase64 = raw['iv'] as String?;
          final timestampStr = raw['timestamp'] as String?;
          final msgId = raw['_id'] as String? ?? '';

          if (ciphertext == null || ivBase64 == null) continue;

          final decrypted = _decrypt(convId, ciphertext, ivBase64);
          if (decrypted == null) continue;

          messages.add(ChatMessage(
            id: msgId,
            conversationId: convId,
            senderId: senderId,
            text: decrypted,
            timestamp: timestampStr != null
                ? DateTime.parse(timestampStr).toLocal()
                : DateTime.now(),
            isMe: senderId == myUserId,
            status: 'sent',
            localOnly: false,
          ));
        }
        return messages;
      }
      print('ChatService: History error body=${response.body}');
      return [];
    } catch (e) {
      print('ChatService: fetchHistory exception: $e');
      return [];
    }
  }

  /// HTTP POST fallback for sending a message via REST (used by the offline outbox).
  /// Returns the server-assigned message ID on success, null on failure.
  static Future<String?> sendMessageHttp(
    String conversationId,
    String plaintext,
  ) async {
    try {
      final encrypter = _getEncrypter(conversationId);
      final iv = enc.IV.fromSecureRandom(12);
      final encrypted = encrypter.encrypt(plaintext, iv: iv);

      final token = AuthService.token;
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'cookie': token,
      };

      final response = await http
          .post(
            Uri.parse('$apiBase/conversations/$conversationId/messages'),
            headers: headers,
            body: jsonEncode({
              'ciphertext': encrypted.base64,
              'iv': iv.base64,
            }),
          )
          .timeout(const Duration(seconds: 25));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['message']?['_id'] ?? data['_id']) as String?;
      }
      print('ChatService: sendMessageHttp failed ${response.statusCode}');
      return null;
    } catch (e) {
      print('ChatService: sendMessageHttp exception: $e');
      return null;
    }
  }

  // ── Socket.IO connection ─────────────────────────────────────────────────────

  static void connect() {
    if (_socket != null) {
      if (!_socket!.connected) _socket!.connect();
      return;
    }

    final token = AuthService.token;
    // Strip "jwt=" or "token=" prefix + trailing ";path=/" etc.
    final tokenVal = token != null
        ? token
            .replaceAll('jwt=', '')
            .replaceAll('token=', '')
            .split(';')
            .first
            .trim()
        : '';

    print('ChatService: Connecting to $chatUrl, tokenVal="${tokenVal.substring(0, tokenVal.length.clamp(0, 20))}..."');

    _socket = IO.io(
      chatUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': tokenVal})
          .setExtraHeaders({'cookie': token ?? ''})
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      print('ChatService: Socket connected, id=${_socket!.id}');
      if (_currentConversationId != null) {
        _emitJoin(_currentConversationId!);
      }
      _startHeartbeat();
    });

    _socket!.onConnectError((err) {
      print('ChatService: Connect error: $err');
      if (onError != null) onError!('Connection failed: $err');
    });

    _socket!.onError((err) {
      print('ChatService: Socket error: $err');
    });

    _socket!.onDisconnect((_) {
      print('ChatService: Disconnected');
      _heartbeatTimer?.cancel();
    });

    // Server → Client: message received (from other participant)
    _socket!.on('message_received', (data) {
      print('ChatService: message_received data=$data');
      if (data is! Map) return;

      final convId = data['conversationId'] as String?;
      final senderId = data['senderId'] as String?;
      final ciphertext = data['ciphertext'] as String?;
      final ivBase64 = data['iv'] as String?;
      final timestampStr = data['timestamp'] as String?;
      final msgId = data['_id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString();

      if (convId == null || ciphertext == null || ivBase64 == null) {
        print('ChatService: message_received missing fields');
        return;
      }

      final decrypted = _decrypt(convId, ciphertext, ivBase64);
      if (decrypted == null) {
        print('ChatService: Decryption failed for incoming message');
        return;
      }

      final message = ChatMessage(
        id: msgId,
        conversationId: convId,
        senderId: senderId ?? '',
        text: decrypted,
        timestamp: timestampStr != null
            ? DateTime.parse(timestampStr).toLocal()
            : DateTime.now(),
        isMe: false,
      );

      if (onMessageReceived != null) onMessageReceived!(message);
    });

    // Server → Client: acknowledgement that our message was accepted
    _socket!.on('message_sent', (data) {
      print('ChatService: message_sent ack=$data');
      if (data is Map && onMessageSent != null) {
        final convId = data['conversationId'] as String?;
        final timestampStr = data['timestamp'] as String?;
        if (convId != null) {
          onMessageSent!(
            convId,
            timestampStr != null
                ? DateTime.parse(timestampStr).toLocal()
                : DateTime.now(),
          );
        }
      }
    });

    _socket!.on('chat_error', (data) {
      print('ChatService: chat_error data=$data');
      if (data is Map) {
        final err = data['error']?.toString();
        if (err != null && onError != null) onError!(err);
      }
    });
  }

  static void _emitJoin(String conversationId) {
    print('ChatService: Emitting join_conversation for $conversationId');
    _socket!.emit('join_conversation', {'conversationId': conversationId});
  }

  static void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_socket != null && _socket!.connected) {
        _socket!.emit('heartbeat', {});
      }
    });
  }

  // ── Public API ────────────────────────────────────────────────────────────────

  static bool get isConnected => _socket?.connected == true;

  static void joinConversation(String conversationId) {
    _currentConversationId = conversationId;
    if (_socket == null || !_socket!.connected) {
      connect(); // join will be emitted in onConnect
    } else {
      _emitJoin(conversationId);
    }
  }

  static void sendMessage(String conversationId, String plaintext) {
    if (_socket == null || !_socket!.connected) {
      print('ChatService: Socket not connected, attempting reconnect...');
      connect();
      // Wait briefly then send (the socket may reconnect fast on mobile)
      Future.delayed(const Duration(milliseconds: 500), () {
        _doSend(conversationId, plaintext);
      });
      return;
    }
    _doSend(conversationId, plaintext);
  }

  static void _doSend(String conversationId, String plaintext) {
    try {
      final encrypter = _getEncrypter(conversationId);
      final iv = enc.IV.fromSecureRandom(12);
      final encrypted = encrypter.encrypt(plaintext, iv: iv);

      print('ChatService: Sending message to conv $conversationId');
      _socket!.emit('send_message', {
        'conversationId': conversationId,
        'ciphertext': encrypted.base64,
        'iv': iv.base64,
      });
    } catch (e) {
      print('ChatService: Encrypt error: $e');
      if (onError != null) onError!('Failed to encrypt message');
    }
  }

  static void disconnect() {
    _heartbeatTimer?.cancel();
    _currentConversationId = null;
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
