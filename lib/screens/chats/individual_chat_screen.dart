import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:uuid/uuid.dart';
import '../../services/chat_service.dart';
import '../../services/chat_db.dart';
import '../../services/auth_service.dart';
import '../../services/outbox_service.dart';

/// Number of items from the top of the reversed list that triggers a
/// "load older messages" fetch — WhatsApp-style pre-fetch before the
/// user hits the very top.
const int _kScrollTriggerItems = 5;

/// Batch size for each "load older messages" fetch.
const int _kPageSize = 30;

class IndividualChatScreen extends StatefulWidget {
  final String conversationId;
  final Map<String, dynamic> partner;

  const IndividualChatScreen({
    super.key,
    required this.conversationId,
    required this.partner,
  });

  @override
  State<IndividualChatScreen> createState() => _IndividualChatScreenState();
}

class _IndividualChatScreenState extends State<IndividualChatScreen>
    with WidgetsBindingObserver {
  static const Color _cream = Color(0xFFFAF4E1);
  static const Color _inkBlack = Color(0xFF0A0A0A);
  static const Color _crimson = Color(0xFFA31534);

  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  // In-memory list — newest at index 0 (reversed ListView).
  final List<ChatMessage> _messages = [];

  bool _isInitialLoading = true; // True only on very first open with empty cache
  bool _isLoadingOlder = false;  // True while fetching a "load older" page
  bool _hasReachedStart = false; // No more pages to load
  int _nextPage = 2;             // Next server page to fetch for "load older"
  String? _myUserId;
  bool _canSend = false;

  static const _uuid = Uuid();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _myUserId = AuthService.userId;
    _msgCtrl.addListener(_onInputChanged);
    _scrollCtrl.addListener(_onScroll);
    _setupServiceListeners();
    _connectAndJoin();
    _initMessages();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Flush the outbox when the user comes back to the app.
      OutboxService.flush();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _msgCtrl.removeListener(_onInputChanged);
    _scrollCtrl.removeListener(_onScroll);
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    ChatService.onMessageReceived = null;
    ChatService.onMessageSent = null;
    ChatService.onError = null;
    OutboxService.onMessageDelivered = null;
    super.dispose();
  }

  // ── Setup ─────────────────────────────────────────────────────────────────

  void _setupServiceListeners() {
    // Live incoming messages via socket.
    ChatService.onMessageReceived = (msg) {
      if (msg.conversationId != widget.conversationId) return;
      if (!mounted) return;
      _upsertMessage(msg);
      _cacheMessage(msg);
      _scrollToBottom();
    };

    // Socket ack that our send was received — update status.
    ChatService.onMessageSent = (convId, ts) {
      // The socket ack doesn't include the server ID, so we leave the
      // optimistic message as-is and let the outbox handle confirmation
      // for failed sends. For successful socket sends we mark 'sent'.
      if (!mounted) return;
      setState(() {
        for (int i = 0; i < _messages.length; i++) {
          if (_messages[i].localOnly &&
              _messages[i].conversationId == convId) {
            _messages[i] = _messages[i].copyWith(status: 'sent', localOnly: false);
            ChatDB.updateMessageStatus(
                _messages[i].id, _messages[i].id, 'sent');
            break;
          }
        }
      });
    };

    ChatService.onError = (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error, style: GoogleFonts.inter(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    };

    // Outbox callback: a pending message was delivered after a cold-start.
    OutboxService.onMessageDelivered = (localId, serverId) {
      if (!mounted) return;
      setState(() {
        for (int i = 0; i < _messages.length; i++) {
          if (_messages[i].id == localId) {
            _messages[i] =
                _messages[i].copyWith(id: serverId, status: 'sent', localOnly: false);
            break;
          }
        }
      });
    };
  }

  void _connectAndJoin() {
    ChatService.connect();
    ChatService.joinConversation(widget.conversationId);
  }

  // ── Loading ───────────────────────────────────────────────────────────────

  /// Step 1: Load from cache instantly.
  /// Step 2: Background-sync new messages from server.
  Future<void> _initMessages() async {
    final cached = await ChatDB.getMessages(
      widget.conversationId,
      limit: 50,
    );

    _hasReachedStart =
        await ChatDB.hasReachedStart(widget.conversationId);

    if (cached.isNotEmpty) {
      // Render from cache immediately — zero network wait.
      if (!mounted) return;
      setState(() {
        _messages.addAll(_toUiMessages(cached));
        _isInitialLoading = false;
      });
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);

      // Background delta-sync: fetch anything newer than our newest cached msg.
      _deltaSync();
    } else {
      // First open: await the full fetch before hiding the loader.
      await _fullFetch();
    }
  }

  /// Converts [CachedMessage] rows to in-memory [ChatMessage] objects.
  List<ChatMessage> _toUiMessages(List<CachedMessage> rows) {
    return rows.map((r) => ChatMessage(
          id: r.id,
          conversationId: r.conversationId,
          senderId: r.senderId,
          text: r.content,
          timestamp: DateTime.fromMillisecondsSinceEpoch(r.timestamp),
          isMe: r.senderId == _myUserId,
          status: r.status,
          localOnly: r.localOnly,
        )).toList();
  }

  /// Full first-time fetch — called when the cache is empty.
  Future<void> _fullFetch() async {
    final msgs = await ChatService.fetchHistory(
      widget.conversationId,
      myUserId: _myUserId ?? '',
      page: 1,
      limit: _kPageSize,
    );

    if (!mounted) return;

    if (msgs.length < _kPageSize) {
      await ChatDB.markConversationStart(widget.conversationId);
      _hasReachedStart = true;
    }
    // Next "load older" will fetch page 2.
    _nextPage = 2;

    await _cacheMessages(msgs);

    setState(() {
      _messages
        ..clear()
        ..addAll(msgs);
      _isInitialLoading = false;
    });
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  /// Background delta-sync: fetch page 1 again and merge any new messages.
  /// Since the backend is page-based, we fetch p1 and skip IDs we already have.
  Future<void> _deltaSync() async {
    final newMsgs = await ChatService.fetchHistory(
      widget.conversationId,
      myUserId: _myUserId ?? '',
      page: 1,
      limit: _kPageSize,
    );

    if (newMsgs.isEmpty || !mounted) return;

    await _cacheMessages(newMsgs);

    setState(() {
      final existingIds = _messages.map((m) => m.id).toSet();
      final toAdd = newMsgs.where((m) => !existingIds.contains(m.id)).toList();
      if (toAdd.isNotEmpty) {
        _messages.insertAll(0, toAdd);
      }
    });
  }

  /// Load a batch of older messages when the user scrolls near the top.
  /// Uses page-based pagination (backend doesn't support cursor/before params).
  Future<void> _loadOlderMessages() async {
    if (_isLoadingOlder || _hasReachedStart) return;

    final oldestTs = _messages.isNotEmpty
        ? _messages.last.timestamp.millisecondsSinceEpoch
        : null;

    // First check local DB for older cached pages.
    final cachedOlder = await ChatDB.getMessages(
      widget.conversationId,
      limit: _kPageSize,
      beforeTimestamp: oldestTs,
    );

    if (cachedOlder.isNotEmpty) {
      final uiMsgs = _toUiMessages(cachedOlder);
      if (!mounted) return;
      setState(() {
        final existingIds = _messages.map((m) => m.id).toSet();
        final toAdd = uiMsgs.where((m) => !existingIds.contains(m.id)).toList();
        _messages.addAll(toAdd);
      });
      return;
    }

    // Nothing in DB — fetch next page from server.
    setState(() => _isLoadingOlder = true);

    final older = await ChatService.fetchHistory(
      widget.conversationId,
      myUserId: _myUserId ?? '',
      page: _nextPage,
      limit: _kPageSize,
    );

    if (older.length < _kPageSize) {
      await ChatDB.markConversationStart(widget.conversationId);
      if (mounted) _hasReachedStart = true;
    } else {
      _nextPage++;
    }

    if (older.isNotEmpty) {
      await _cacheMessages(older);
    }

    if (!mounted) return;
    setState(() {
      final existingIds = _messages.map((m) => m.id).toSet();
      final toAdd = older.where((m) => !existingIds.contains(m.id)).toList();
      _messages.addAll(toAdd);
      _isLoadingOlder = false;
    });
  }

  // ── Scroll ────────────────────────────────────────────────────────────────

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    // Reversed ListView: "top" = max scroll extent.
    final pos = _scrollCtrl.position;
    final distanceFromTop = pos.maxScrollExtent - pos.pixels;
    if (distanceFromTop < _kScrollTriggerItems * 80.0) {
      _loadOlderMessages();
    }
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // ── Send ──────────────────────────────────────────────────────────────────

  void _sendMessage() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();

    final localId = 'local_${_uuid.v4()}';
    final now = DateTime.now();

    // Optimistic: insert into UI and DB immediately.
    final optimistic = ChatMessage(
      id: localId,
      conversationId: widget.conversationId,
      senderId: _myUserId ?? 'me',
      text: text,
      timestamp: now,
      isMe: true,
      status: 'pending',
      localOnly: true,
    );

    setState(() => _messages.insert(0, optimistic));
    _cacheMessage(optimistic);
    _scrollToBottom();

    // Attempt socket send.
    if (ChatService.isConnected) {
      ChatService.sendMessage(widget.conversationId, text);
    } else {
      // Not connected — queue for outbox retry.
      OutboxService.notifyFailed();
    }
  }

  void _onInputChanged() {
    final can = _msgCtrl.text.trim().isNotEmpty;
    if (can != _canSend) setState(() => _canSend = can);
  }

  // ── Cache helpers ─────────────────────────────────────────────────────────

  Future<void> _cacheMessage(ChatMessage msg) async {
    await ChatDB.insertMessages([
      CachedMessage(
        id: msg.id,
        conversationId: msg.conversationId,
        senderId: msg.senderId,
        content: msg.text,
        timestamp: msg.timestamp.millisecondsSinceEpoch,
        status: msg.status,
        localOnly: msg.localOnly,
      )
    ]);
  }

  Future<void> _cacheMessages(List<ChatMessage> msgs) async {
    await ChatDB.insertMessages(msgs.map((m) => CachedMessage(
          id: m.id,
          conversationId: m.conversationId,
          senderId: m.senderId,
          content: m.text,
          timestamp: m.timestamp.millisecondsSinceEpoch,
          status: m.status,
          localOnly: m.localOnly,
        )).toList());
  }

  /// Upsert a single message into the in-memory list (used for incoming socket msgs).
  void _upsertMessage(ChatMessage msg) {
    setState(() {
      final idx = _messages.indexWhere((m) => m.id == msg.id);
      if (idx == -1) {
        _messages.insert(0, msg);
      } else {
        _messages[idx] = msg;
      }
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _getPartnerPhoto() {
    final pics = widget.partner['pictures'];
    if (pics is List && pics.isNotEmpty) {
      final pic = pics[0];
      if (pic is Map && pic['url'] != null) return pic['url'] as String;
    }
    return '';
  }

  String _formatTime(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  String _formatDateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(msgDay).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${dt.day} ${_monthAbbr(dt.month)} ${dt.year}';
  }

  String _monthAbbr(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final name = widget.partner['name'] ?? 'Match';
    final photoUrl = _getPartnerPhoto();
    final isOnline = widget.partner['isOnline'] == true;

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _inkBlack, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border:
                    isOnline ? Border.all(color: _crimson, width: 1.5) : null,
              ),
              padding: isOnline ? const EdgeInsets.all(2.0) : EdgeInsets.zero,
              child: ClipOval(
                child: photoUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: photoUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, _) =>
                            Container(color: _inkBlack.withOpacity(0.05)),
                        errorWidget: (_, _, _) => Container(
                          color: _inkBlack.withOpacity(0.05),
                          child: Icon(Icons.person,
                              color: _inkBlack.withOpacity(0.3), size: 18),
                        ),
                      )
                    : Container(
                        color: _inkBlack.withOpacity(0.05),
                        child: Icon(Icons.person,
                            color: _inkBlack.withOpacity(0.3), size: 18),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _inkBlack,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isOnline
                            ? _crimson
                            : _inkBlack.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOnline ? 'Active now' : 'Offline',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: _inkBlack.withOpacity(0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: _inkBlack.withOpacity(0.08), height: 1),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildMessageList(name, photoUrl)),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(String name, String photoUrl) {
    if (_isInitialLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _crimson, strokeWidth: 2),
      );
    }

    if (_messages.isEmpty) {
      return _buildEmptyState(name, photoUrl);
    }

    // Build a date-grouped item list from the reversed in-memory list.
    // We iterate newest→oldest (index 0 = newest) and insert separators
    // whenever the date changes.
    final items = _buildItemList();

    return ListView.builder(
      reverse: true,
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: items.length + (_isLoadingOlder ? 1 : 0),
      itemBuilder: (context, index) {
        // Index 0 in a reversed list is the bottom (newest).
        // The very last rendered slot is the top (oldest).
        if (_isLoadingOlder && index == items.length) {
          return const _TopLoadingIndicator();
        }
        final item = items[index];
        if (item is _DateSeparatorItem) {
          return _buildDateSeparator(item.label);
        }
        final msg = (item as _MessageItem).message;
        final isConsecutive = index + 1 < items.length &&
            items[index + 1] is _MessageItem &&
            (items[index + 1] as _MessageItem).message.senderId ==
                msg.senderId;
        return _buildMessageBubble(msg, isConsecutive);
      },
    );
  }

  /// Produces an interleaved list of [_MessageItem] and [_DateSeparatorItem].
  /// The list is in reversed order (newest first) to match the reversed ListView.
  List<Object> _buildItemList() {
    final result = <Object>[];
    String? lastDay;

    for (final msg in _messages) {
      final day = _formatDateLabel(msg.timestamp);
      result.add(_MessageItem(msg));
      if (day != lastDay) {
        result.add(_DateSeparatorItem(day));
        lastDay = day;
      }
    }
    return result;
  }

  Widget _buildDateSeparator(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Divider(color: _inkBlack.withOpacity(0.08))),
          const SizedBox(width: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _inkBlack.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: _inkBlack.withOpacity(0.5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Divider(color: _inkBlack.withOpacity(0.08))),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String name, String photoUrl) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: ClipOval(
              child: photoUrl.isNotEmpty
                  ? CachedNetworkImage(imageUrl: photoUrl, fit: BoxFit.cover)
                  : Container(
                      color: _inkBlack.withOpacity(0.05),
                      child: Icon(Icons.person,
                          color: _inkBlack.withOpacity(0.3), size: 36),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'You matched with $name!',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _inkBlack,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the conversation.\nMessages are end-to-end encrypted.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: _inkBlack.withOpacity(0.45),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline,
                  size: 14, color: _inkBlack.withOpacity(0.3)),
              const SizedBox(width: 4),
              Text(
                'AES-GCM encrypted',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: _inkBlack.withOpacity(0.3),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isConsecutive) {
    return Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: isConsecutive ? 3 : 14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: msg.isMe
              ? (msg.status == 'pending'
                  ? _crimson.withOpacity(0.55)
                  : _crimson)
              : Colors.white,
          border: msg.isMe
              ? null
              : Border.all(color: _inkBlack.withOpacity(0.06), width: 1),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(msg.isMe ? 20 : 4),
            bottomRight: Radius.circular(msg.isMe ? 4 : 20),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: GoogleFonts.inter(
                color: msg.isMe ? Colors.white : _inkBlack,
                fontSize: 15,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(msg.timestamp),
                  style: GoogleFonts.inter(
                    color:
                        (msg.isMe ? Colors.white : _inkBlack).withOpacity(0.55),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (msg.isMe) ...[
                  const SizedBox(width: 4),
                  _MessageStatusIcon(status: msg.status),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      color: _cream,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: _cream,
                borderRadius: BorderRadius.circular(24),
                border:
                    Border.all(color: _inkBlack.withOpacity(0.08), width: 1),
              ),
              child: TextField(
                controller: _msgCtrl,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) {
                  if (_canSend) _sendMessage();
                },
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Message...',
                  hintStyle: GoogleFonts.inter(
                    color: _inkBlack.withOpacity(0.4),
                    fontSize: 15,
                  ),
                ),
                style: GoogleFonts.inter(fontSize: 15, color: _inkBlack),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _canSend ? _sendMessage : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _canSend ? _crimson : _inkBlack.withOpacity(0.05),
                shape: BoxShape.circle,
                boxShadow: _canSend
                    ? [
                        BoxShadow(
                          color: _crimson.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [],
              ),
              child: Icon(
                Icons.send_rounded,
                color: _canSend ? Colors.white : _inkBlack.withOpacity(0.2),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data items for the grouped list ──────────────────────────────────────────

class _MessageItem {
  final ChatMessage message;
  const _MessageItem(this.message);
}

class _DateSeparatorItem {
  final String label;
  const _DateSeparatorItem(this.label);
}

// ── Small spinner row shown at the top of the list while loading older msgs ──

class _TopLoadingIndicator extends StatelessWidget {
  const _TopLoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFFA31534),
          ),
        ),
      ),
    );
  }
}

// ── Message status icon (clock / check) ──────────────────────────────────────

class _MessageStatusIcon extends StatelessWidget {
  final String status;
  const _MessageStatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case 'pending':
        return Icon(Icons.access_time_rounded,
            size: 11, color: Colors.white.withOpacity(0.7));
      case 'failed':
        return const Icon(Icons.error_outline_rounded,
            size: 11, color: Colors.redAccent);
      default: // sent / delivered / read
        return Icon(Icons.done_rounded,
            size: 11, color: Colors.white.withOpacity(0.7));
    }
  }
}

