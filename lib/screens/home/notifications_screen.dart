import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';

class NotificationsScreen extends StatefulWidget {
  final UserModel currentUser;

  const NotificationsScreen({super.key, required this.currentUser});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final Color _primaryColor = const Color(0xFF6A1221);

  Future<void> _markAsRead(String docId) async {
    await FirebaseFirestore.instance.collection('notifications').doc(docId).update({
      'isRead': true,
    });
  }

  Future<void> _markAllAsRead() async {
    final unreadDocs = await FirebaseFirestore.instance
        .collection('notifications')
        .where('toUserId', isEqualTo: widget.currentUser.uid)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in unreadDocs.docs) {
      doc.reference.update({'isRead': true});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: Text('Bildirimler', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 26, color: textColor, letterSpacing: -0.5)),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(Icons.done_all_rounded, color: _primaryColor),
            tooltip: 'Tümünü Okundu İşaretle',
            onPressed: _markAllAsRead,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('toUserId', isEqualTo: widget.currentUser.uid)
        // GEÇİCİ ÇÖZÜM: Firebase Index hatasını atlamak için sıralama kapatıldı.
        // Firebase panelinden index oluşturduğunda alttaki satırın başındaki // işaretlerini silebilirsin.
        // .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            // Hata artık ekranda detaylıca (link ile birlikte) yazacak
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'Firebase Hatası:\n${snapshot.error}',
                  style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData) return Center(child: CircularProgressIndicator(color: _primaryColor));

          final notifications = snapshot.data!.docs;

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('Henüz bildirim yok.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final doc = notifications[index];
              final data = doc.data() as Map<String, dynamic>;
              final isRead = data['isRead'] ?? false;
              final title = data['title'] ?? 'Bildirim';
              final body = data['body'] ?? '';
              final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

              return GestureDetector(
                onTap: () {
                  if (!isRead) _markAsRead(doc.id);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isRead
                        ? (isDark ? const Color(0xFF1E1E1E) : Colors.white)
                        : (isDark ? _primaryColor.withOpacity(0.15) : _primaryColor.withOpacity(0.05)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isRead
                          ? (isDark ? Colors.transparent : Colors.grey.shade200)
                          : _primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isRead ? (isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100) : _primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isRead ? Icons.notifications_none_rounded : Icons.notifications_active_rounded,
                          color: isRead ? Colors.grey.shade500 : _primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: TextStyle(fontWeight: isRead ? FontWeight.w700 : FontWeight.w900, fontSize: 16, color: textColor)),
                            const SizedBox(height: 4),
                            Text(body, style: TextStyle(fontSize: 14, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700, height: 1.3)),
                            const SizedBox(height: 8),
                            Text(
                              DateFormat('dd MMM HH:mm', 'tr').format(createdAt),
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 10, height: 10,
                          margin: const EdgeInsets.only(top: 6),
                          decoration: BoxDecoration(color: _primaryColor, shape: BoxShape.circle),
                        )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}