import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Immutable row object representing a locally-cached chat message.
class CachedMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final int timestamp; // Unix milliseconds
  final String status; // 'pending' | 'sent' | 'delivered' | 'read' | 'failed'
  final bool localOnly;

  const CachedMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.timestamp,
    required this.status,
    this.localOnly = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'conversationId': conversationId,
        'senderId': senderId,
        'content': content,
        'timestamp': timestamp,
        'status': status,
        'localOnly': localOnly ? 1 : 0,
      };

  factory CachedMessage.fromMap(Map<String, dynamic> m) => CachedMessage(
        id: m['id'] as String,
        conversationId: m['conversationId'] as String,
        senderId: m['senderId'] as String,
        content: m['content'] as String,
        timestamp: m['timestamp'] as int,
        status: m['status'] as String? ?? 'sent',
        localOnly: (m['localOnly'] as int? ?? 0) == 1,
      );

  CachedMessage copyWith({
    String? id,
    String? status,
    bool? localOnly,
  }) =>
      CachedMessage(
        id: id ?? this.id,
        conversationId: conversationId,
        senderId: senderId,
        content: content,
        timestamp: timestamp,
        status: status ?? this.status,
        localOnly: localOnly ?? this.localOnly,
      );
}

/// SQLite database for local chat message caching.
/// Two tables:
///   - messages: individual chat messages
///   - conversation_meta: per-conversation flags (hasReachedStart, lastFetchedAt)
class ChatDB {
  static const int _version = 1;
  static Database? _db;

  static Future<Database> get _database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'chat_cache.db');
    return openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE messages (
        id            TEXT PRIMARY KEY,
        conversationId TEXT NOT NULL,
        senderId      TEXT NOT NULL,
        content       TEXT NOT NULL,
        timestamp     INTEGER NOT NULL,
        status        TEXT NOT NULL DEFAULT 'sent',
        localOnly     INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_msgs_conv_ts ON messages (conversationId, timestamp DESC)');

    await db.execute('''
      CREATE TABLE conversation_meta (
        conversationId  TEXT PRIMARY KEY,
        hasReachedStart INTEGER NOT NULL DEFAULT 0,
        lastFetchedAt   INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  static Future<void> _onUpgrade(Database db, int oldV, int newV) async {
    // Future migrations go here.
  }

  // ── Messages ──────────────────────────────────────────────────────────────

  /// Returns messages for [conversationId], ordered newest-first.
  /// If [beforeTimestamp] is provided, only messages older than that ts are returned.
  static Future<List<CachedMessage>> getMessages(
    String conversationId, {
    int limit = 50,
    int? beforeTimestamp,
  }) async {
    final db = await _database;
    final where = beforeTimestamp != null
        ? 'conversationId = ? AND timestamp < ?'
        : 'conversationId = ?';
    final args = beforeTimestamp != null
        ? [conversationId, beforeTimestamp]
        : [conversationId];

    final rows = await db.query(
      'messages',
      where: where,
      whereArgs: args,
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return rows.map(CachedMessage.fromMap).toList();
  }

  /// Upserts [messages] into the local cache.
  static Future<void> insertMessages(List<CachedMessage> messages) async {
    if (messages.isEmpty) return;
    final db = await _database;
    final batch = db.batch();
    for (final m in messages) {
      batch.insert('messages', m.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  /// Updates the status of a locally-created message and optionally replaces
  /// the local temp [localId] with the server-assigned [serverId].
  static Future<void> updateMessageStatus(
    String localId,
    String serverId,
    String status,
  ) async {
    final db = await _database;
    if (localId == serverId) {
      await db.update(
        'messages',
        {'status': status, 'localOnly': 0},
        where: 'id = ?',
        whereArgs: [localId],
      );
    } else {
      final rows =
          await db.query('messages', where: 'id = ?', whereArgs: [localId]);
      if (rows.isNotEmpty) {
        final updated = CachedMessage.fromMap(rows.first)
            .copyWith(id: serverId, status: status, localOnly: false);
        await db.delete('messages', where: 'id = ?', whereArgs: [localId]);
        await db.insert('messages', updated.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
  }

  /// Returns all messages not yet confirmed by the server.
  static Future<List<CachedMessage>> getPendingMessages() async {
    final db = await _database;
    final rows = await db.query(
      'messages',
      where: "localOnly = 1 AND status != 'failed'",
      orderBy: 'timestamp ASC',
    );
    return rows.map(CachedMessage.fromMap).toList();
  }

  /// Drops all data from all tables. Call on logout.
  static Future<void> clearAll() async {
    if (_db == null) return;
    final db = await _database;
    await db.delete('messages');
    await db.delete('conversation_meta');
  }

  // ── Conversation meta ─────────────────────────────────────────────────────

  /// Returns true if we've fetched all the way back to the first message.
  static Future<bool> hasReachedStart(String conversationId) async {
    final db = await _database;
    final rows = await db.query(
      'conversation_meta',
      columns: ['hasReachedStart'],
      where: 'conversationId = ?',
      whereArgs: [conversationId],
    );
    if (rows.isEmpty) return false;
    return (rows.first['hasReachedStart'] as int? ?? 0) == 1;
  }

  /// Marks that we've reached the beginning of this conversation.
  static Future<void> markConversationStart(String conversationId) async {
    final db = await _database;
    await db.insert(
      'conversation_meta',
      {
        'conversationId': conversationId,
        'hasReachedStart': 1,
        'lastFetchedAt': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Returns the timestamp of the newest server-confirmed message, or null.
  static Future<int?> getNewestTimestamp(String conversationId) async {
    final db = await _database;
    final rows = await db.query(
      'messages',
      columns: ['timestamp'],
      where: 'conversationId = ? AND localOnly = 0',
      whereArgs: [conversationId],
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['timestamp'] as int?;
  }
}
