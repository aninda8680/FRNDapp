import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/chat_service.dart';
import '../../services/auth_service.dart';

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

class _IndividualChatScreenState extends State<IndividualChatScreen> {
  static const Color _burgundy = Color(0xFFA41534);
  static const Color _lightGrey = Color(0xFFF3F3F3);

  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoadingHistory = true;
  String? _myUserId;

  @override
  void initState() {
    super.initState();
    _myUserId = AuthService.userId;
    _setupListeners();
    _connectAndJoin();
    _loadHistory();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    // Clear callbacks so stale screen doesn't handle events
    ChatService.onMessageReceived = null;
    ChatService.onMessageSent = null;
    ChatService.onError = null;
    super.dispose();
  }

  // ── Setup ────────────────────────────────────────────────────────────────────

  void _setupListeners() {
    ChatService.onMessageReceived = (msg) {
      if (msg.conversationId != widget.conversationId) return;
      if (!mounted) return;
      setState(() => _messages.add(msg));
      _scrollToBottom();
    };

    ChatService.onError = (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error, style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    };
  }

  void _connectAndJoin() {
    ChatService.connect();
    ChatService.joinConversation(widget.conversationId);
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);

    final myId = _myUserId ?? '';
    final history = await ChatService.fetchHistory(
      widget.conversationId,
      myUserId: myId,
    );

    if (!mounted) return;

    setState(() {
      // Prepend history (oldest first), skip duplicates
      final existingIds = _messages.map((m) => m.id).toSet();
      final newMsgs = history.where((m) => !existingIds.contains(m.id)).toList();
      _messages.insertAll(0, newMsgs);
      _isLoadingHistory = false;
    });

    // Scroll to bottom after history loads
    Future.delayed(const Duration(milliseconds: 150), _scrollToBottom);
  }

  // ── Actions ───────────────────────────────────────────────────────────────────

  void _sendMessage() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();

    final msg = ChatMessage(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: widget.conversationId,
      senderId: _myUserId ?? 'me',
      text: text,
      timestamp: DateTime.now(),
      isMe: true,
    );

    setState(() => _messages.add(msg));
    ChatService.sendMessage(widget.conversationId, text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  String _getPartnerPhoto() {
    final pics = widget.partner['pictures'];
    if (pics is List && pics.isNotEmpty) {
      final pic = pics[0];
      if (pic is Map && pic['url'] != null) return pic['url'] as String;
    }
    return '';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final name = widget.partner['name'] ?? 'Match';
    final photoUrl = _getPartnerPhoto();
    final isOnline = widget.partner['isOnline'] == true;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
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
                border: Border.all(color: _burgundy.withValues(alpha: 0.2), width: 1),
              ),
              child: ClipOval(
                child: photoUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: photoUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: Colors.grey[200]),
                        errorWidget: (_, __, ___) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.person, color: Colors.grey, size: 18),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.person, color: Colors.grey, size: 18),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: isOnline ? Colors.green : Colors.grey[400],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOnline ? 'Active now' : 'Offline',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.black.withValues(alpha: 0.5),
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
          child: Container(
            color: Colors.black.withValues(alpha: 0.05),
            height: 1,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _buildMessageList(name, photoUrl),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(String name, String photoUrl) {
    if (_isLoadingHistory) {
      return const Center(
        child: CircularProgressIndicator(color: _burgundy, strokeWidth: 2),
      );
    }

    if (_messages.isEmpty) {
      return _buildEmptyState(name, photoUrl);
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      itemCount: _messages.length,
      itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
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
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _burgundy, width: 2),
            ),
            child: ClipOval(
              child: photoUrl.isNotEmpty
                  ? CachedNetworkImage(imageUrl: photoUrl, fit: BoxFit.cover)
                  : Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.person, color: Colors.grey, size: 36),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'You matched with $name!',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the conversation.\nMessages are end-to-end encrypted.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.black.withValues(alpha: 0.45),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 13, color: Colors.black.withValues(alpha: 0.3)),
              const SizedBox(width: 4),
              Text(
                'AES-GCM encrypted',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black.withValues(alpha: 0.3),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    return Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: msg.isMe ? _burgundy : _lightGrey,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(msg.isMe ? 18 : 4),
            bottomRight: Radius.circular(msg.isMe ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: TextStyle(
                color: msg.isMe ? Colors.white : Colors.black,
                fontSize: 15,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              _formatTime(msg.timestamp),
              style: TextStyle(
                color: (msg.isMe ? Colors.white : Colors.black)
                    .withValues(alpha: 0.45),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: _lightGrey,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _msgCtrl,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Write a message...',
                  hintStyle: TextStyle(
                    color: Colors.black.withValues(alpha: 0.38),
                    fontSize: 14,
                  ),
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: _burgundy,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
