import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  static const Color _cream = Color(0xFFFAF4E1);
  static const Color _inkBlack = Color(0xFF0A0A0A);
  static const Color _crimson = Color(0xFFA31534);

  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoadingHistory = true;
  String? _myUserId;
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    _myUserId = AuthService.userId;
    _msgCtrl.addListener(_onInputChanged);
    _setupListeners();
    _connectAndJoin();
    _loadHistory();
  }

  void _onInputChanged() {
    final canSend = _msgCtrl.text.trim().isNotEmpty;
    if (canSend != _canSend) {
      setState(() {
        _canSend = canSend;
      });
    }
  }

  @override
  void dispose() {
    _msgCtrl.removeListener(_onInputChanged);
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
      setState(() => _messages.insert(0, msg));
      _scrollToBottom();
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
      _messages.addAll(newMsgs);
      _messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
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

    setState(() => _messages.insert(0, msg));
    ChatService.sendMessage(widget.conversationId, text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          0.0,
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
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _inkBlack, size: 20),
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
                border: isOnline ? Border.all(color: _crimson, width: 1.5) : null,
              ),
              padding: isOnline ? const EdgeInsets.all(2.0) : EdgeInsets.zero,
              child: ClipOval(
                child: photoUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: photoUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: _inkBlack.withOpacity(0.05)),
                        errorWidget: (_, __, ___) => Container(
                          color: _inkBlack.withOpacity(0.05),
                          child: Icon(Icons.person, color: _inkBlack.withOpacity(0.3), size: 18),
                        ),
                      )
                    : Container(
                        color: _inkBlack.withOpacity(0.05),
                        child: Icon(Icons.person, color: _inkBlack.withOpacity(0.3), size: 18),
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
                        color: isOnline ? _crimson : _inkBlack.withOpacity(0.3),
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
          child: Container(
            color: _inkBlack.withOpacity(0.08),
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
        child: CircularProgressIndicator(color: _crimson, strokeWidth: 2),
      );
    }

    if (_messages.isEmpty) {
      return _buildEmptyState(name, photoUrl);
    }

    return ListView.builder(
      reverse: true,
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isConsecutive = index > 0 && _messages[index - 1].senderId == msg.senderId;
        
        return _buildMessageBubble(msg, isConsecutive);
      },
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
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: photoUrl.isNotEmpty
                  ? CachedNetworkImage(imageUrl: photoUrl, fit: BoxFit.cover)
                  : Container(
                      color: _inkBlack.withOpacity(0.05),
                      child: Icon(Icons.person, color: _inkBlack.withOpacity(0.3), size: 36),
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
              Icon(Icons.lock_outline, size: 14, color: _inkBlack.withOpacity(0.3)),
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
        margin: EdgeInsets.only(bottom: isConsecutive ? 4 : 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: msg.isMe ? _crimson : Colors.white,
          border: msg.isMe ? null : Border.all(color: _inkBlack.withOpacity(0.06), width: 1),
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
            const SizedBox(height: 2),
            Text(
              _formatTime(msg.timestamp),
              style: GoogleFonts.inter(
                color: (msg.isMe ? Colors.white : _inkBlack).withOpacity(0.6),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
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
                border: Border.all(color: _inkBlack.withOpacity(0.08), width: 1),
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
