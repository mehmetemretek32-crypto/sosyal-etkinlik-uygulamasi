import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/event_model.dart';
import '../../models/user_model.dart';
import 'user_profile_screen.dart';

class EventChatScreen extends StatefulWidget {
  final EventModel event;
  final UserModel currentUser;

  const EventChatScreen({super.key, required this.event, required this.currentUser});

  @override
  State<EventChatScreen> createState() => _EventChatScreenState();
}

class _EventChatScreenState extends State<EventChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final Color _primaryColor = const Color(0xFF6A1221); // İMZA BORDO

  Map<String, dynamic>? _replyingMessage;
  late Stream<QuerySnapshot> _messagesStream;

  @override
  void initState() {
    super.initState();
    _messagesStream = FirebaseFirestore.instance
        .collection('events')
        .doc(widget.event.id)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    Map<String, dynamic> messageData = {
      'senderId': widget.currentUser.uid,
      'senderName': widget.currentUser.fullName,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    };

    if (_replyingMessage != null) {
      messageData['replyToName'] = _replyingMessage!['senderName'];
      messageData['replyToText'] = _replyingMessage!['text'];
      setState(() => _replyingMessage = null);
    }

    await FirebaseFirestore.instance
        .collection('events')
        .doc(widget.event.id)
        .collection('messages')
        .add(messageData);
  }

  void _showContextMenu(BuildContext context, Offset tapPosition, String docId, Map<String, dynamic> msg, bool isMe) {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showMenu(
      context: context,
      position: RelativeRect.fromRect(Rect.fromCircle(center: tapPosition, radius: 1), Offset.zero & overlay.size),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      elevation: 4,
      items: [
        PopupMenuItem(
          value: 'reply',
          child: Row(children: [Icon(Icons.reply_rounded, color: _primaryColor, size: 20), const SizedBox(width: 12), const Text('Yanıtla', style: TextStyle(fontWeight: FontWeight.w600))]),
        ),
        if (isMe)
          const PopupMenuItem(
            value: 'delete',
            child: Row(children: [Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20), const SizedBox(width: 12), Text('Mesajı Sil', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600))]),
          ),
      ],
    ).then((value) {
      if (value == 'reply') {
        setState(() => _replyingMessage = msg);
      } else if (value == 'delete') {
        FirebaseFirestore.instance.collection('events').doc(widget.event.id).collection('messages').doc(docId).delete();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.event.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Grup Sohbeti', style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: isDark ? Colors.white70 : Colors.black54)),
          ],
        ),
        elevation: 1,
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text('Hata oluştu.'));
                if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: _primaryColor));

                final messages = snapshot.data?.docs ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.forum_rounded, size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('Henüz mesaj yok.\nİlk mesajı sen gönder!', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final doc = messages[index];
                    final msg = doc.data() as Map<String, dynamic>;
                    final docId = doc.id;
                    final isMe = msg['senderId'] == widget.currentUser.uid;

                    String timeString = '';
                    if (msg['timestamp'] != null) {
                      DateTime time = (msg['timestamp'] as Timestamp).toDate();
                      timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                    }

                    Offset tapPosition = Offset.zero;

                    return SwipeToReply(
                      iconColor: _primaryColor,
                      onReply: () => setState(() => _replyingMessage = msg),
                      child: GestureDetector(
                        onTapDown: (details) => tapPosition = details.globalPosition,
                        onLongPress: () => _showContextMenu(context, tapPosition, docId, msg, isMe),
                        child: Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            // HATA DÜZELTİLDİ: Eksik olan çarpma (*) işareti eklendi.
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isMe ? _primaryColor : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                              boxShadow: [
                                if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 5, offset: const Offset(0, 2))
                              ],
                              border: isDark && !isMe ? Border.all(color: Colors.white.withOpacity(0.05)) : null,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(20), topRight: const Radius.circular(20),
                                bottomLeft: Radius.circular(isMe ? 20 : 4), bottomRight: Radius.circular(isMe ? 4 : 20),
                              ),
                            ),
                            child: IntrinsicWidth(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // ALINTI KUTUSU
                                  if (msg.containsKey('replyToName') && msg.containsKey('replyToText')) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), margin: const EdgeInsets.only(bottom: 6),
                                      decoration: BoxDecoration(color: isMe ? Colors.white.withOpacity(0.15) : _primaryColor.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border(left: BorderSide(color: isMe ? Colors.white70 : _primaryColor, width: 4))),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(msg['replyToName'], style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isMe ? Colors.white : _primaryColor)),
                                          const SizedBox(height: 2),
                                          Text(msg['replyToText'], maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: isMe ? Colors.white.withOpacity(0.9) : (isDark ? Colors.white70 : Colors.black87))),
                                        ],
                                      ),
                                    ),
                                  ],

                                  // GÖNDEREN İSMİ (Tıklanabilir -> Profile Gider)
                                  if (!isMe) ...[
                                    GestureDetector(
                                      // HATA DÜZELTİLDİ: Veritabanından kullanıcıyı çekip UserModel olarak gönderiyoruz
                                      onTap: () async {
                                        final userId = msg['senderId'];
                                        if (userId == null) return;

                                        try {
                                          final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

                                          if (userDoc.exists && context.mounted) {
                                            final clickedUser = UserModel.fromMap(userDoc.data()!, userDoc.id);
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (_) => UserProfileScreen(user: clickedUser)),
                                            );
                                          }
                                        } catch (e) {
                                          debugPrint('Profil çekilemedi: $e');
                                        }
                                      },
                                      child: Text(
                                          msg['senderName'] ?? 'Kullanıcı',
                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _primaryColor),
                                          textAlign: TextAlign.left
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                  ],

                                  // METİN
                                  if (msg['text'] != null)
                                    Text(msg['text'], style: TextStyle(fontSize: 15, height: 1.3, color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87)), textAlign: TextAlign.left),

                                  if (timeString.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(timeString, style: TextStyle(fontSize: 11, color: isMe ? Colors.white.withOpacity(0.7) : Colors.grey.shade500)),
                                          if (isMe) ...[
                                            const SizedBox(width: 4),
                                            Icon(Icons.done_all_rounded, size: 14, color: Colors.white.withOpacity(0.7)),
                                          ]
                                        ],
                                      ),
                                    ),
                                  ]
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          if (_replyingMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
              child: Row(
                children: [
                  Icon(Icons.reply_rounded, color: _primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Yanıtlanıyor: ${_replyingMessage!['senderName']}', style: TextStyle(fontWeight: FontWeight.bold, color: _primaryColor, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(_replyingMessage!['text'], maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => setState(() => _replyingMessage = null)),
                ],
              ),
            ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(color: isDark ? const Color(0xFF121212) : Colors.white, border: Border(top: BorderSide(color: isDark ? Colors.transparent : Colors.grey.shade300, width: 0.5))),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.alternate_email, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                    onPressed: () { _messageController.text += '@'; },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        hintText: 'Mesaj yaz...',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        filled: true, fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 22, backgroundColor: _primaryColor,
                    child: IconButton(icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20), onPressed: () => _sendMessage()),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// SwipeToReply Animasyonu
class SwipeToReply extends StatefulWidget {
  final Widget child;
  final VoidCallback onReply;
  final Color iconColor;
  const SwipeToReply({super.key, required this.child, required this.onReply, required this.iconColor});
  @override
  State<SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<SwipeToReply> with SingleTickerProviderStateMixin {
  double _dragExtent = 0.0;
  late AnimationController _controller;
  Animation<double>? _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _controller.addListener(() { setState(() { _dragExtent = _animation?.value ?? 0.0; }); });
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() { _dragExtent += details.primaryDelta!; if (_dragExtent < 0) _dragExtent = 0; if (_dragExtent > 70) _dragExtent = 70; });
      },
      onHorizontalDragEnd: (details) {
        if (_dragExtent > 40) widget.onReply();
        _animation = Tween<double>(begin: _dragExtent, end: 0.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
        _controller.forward(from: 0.0);
      },
      child: Stack(
        alignment: Alignment.centerLeft,
        fit: StackFit.passthrough,
        children: [
          if (_dragExtent > 0) Positioned(left: 20, child: Opacity(opacity: (_dragExtent / 70).clamp(0.0, 1.0), child: Icon(Icons.reply_rounded, color: widget.iconColor, size: 24))),
          Transform.translate(offset: Offset(_dragExtent, 0), child: widget.child),
        ],
      ),
    );
  }
}