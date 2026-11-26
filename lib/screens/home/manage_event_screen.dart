import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/event_model.dart';
import '../../models/user_model.dart';

class ManageEventScreen extends StatefulWidget {
  final EventModel event;

  const ManageEventScreen({super.key, required this.event});

  @override
  State<ManageEventScreen> createState() => _ManageEventScreenState();
}

class _ManageEventScreenState extends State<ManageEventScreen> {
  bool _isLoading = false;

  // UID listesinden kullanıcıların tam profillerini çeken fonksiyon
  Future<List<UserModel>> _fetchParticipants(List<String> uids) async {
    if (uids.isEmpty) return [];
    List<UserModel> users = [];
    for (String uid in uids) {
      var doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        users.add(UserModel.fromMap(doc.data()!, doc.id));
      }
    }
    return users;
  }

  // Etkinliği tamamen silme ve geri dönme işlemi
  Future<void> _deleteEvent() async {
    // Yanlışlıkla silmeyi önlemek için onay penceresi
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Etkinliği Sil'),
        content: const Text('Bu etkinliği tamamen iptal edip silmek istediğine emin misin? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Evet, Sil', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('events').doc(widget.event.id).delete();

      if (!mounted) return;
      // Yönetim ekranını kapat
      Navigator.pop(context);
      // Detay ekranını kapatıp Ana Sayfaya dön
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Etkinlik başarıyla iptal edildi ve silindi.'), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Etkinlik silinirken bir hata oluştu.')),
      );
      setState(() => _isLoading = false);
    }
  }

  // Katılımcıyı etkinlikten çıkarma işlemi
  Future<void> _removeParticipant(String userId, String userName) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Katılımcıyı Çıkar'),
        content: Text('$userName isimli kullanıcıyı etkinlikten çıkarmak istediğine emin misin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Çıkar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Katılımcıyı etkinlik listesinden çıkar
      await FirebaseFirestore.instance.collection('events').doc(widget.event.id).update({
        'approvedUserIds': FieldValue.arrayRemove([userId])
      });

      // İsteğe bağlı: Çıkarılan kişiye bildirim gönderebilirsin
      await FirebaseFirestore.instance.collection('notifications').add({
        'toUserId': userId,
        'title': 'Etkinlikten Çıkarıldın',
        'message': '"${widget.event.title}" etkinliğinin yöneticisi seni listeden çıkardı.',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$userName etkinlikten çıkarıldı.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kullanıcı çıkarılırken bir hata oluştu.', style: TextStyle(color: Colors.red))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Etkinliği Yönet'),
        elevation: 0,
      ),
      // StreamBuilder ile etkinliği canlı dinliyoruz ki biri katılırsa veya çıkarsa anında ekrana yansısın
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('events').doc(widget.event.id).snapshots(),
        builder: (context, eventSnapshot) {
          if (eventSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primaryColor));
          }
          if (!eventSnapshot.hasData || !eventSnapshot.data!.exists) {
            return const Center(child: Text('Etkinlik bulunamadı veya silinmiş.'));
          }

          // Güncel etkinlik verisi
          EventModel currentEvent = EventModel.fromMap(eventSnapshot.data!.data() as Map<String, dynamic>, eventSnapshot.data!.id);

          return Column(
            children: [
              // ÜST KISIM: Etkinlik Özeti Kartı
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2324) : Colors.grey.shade100,
                  border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(currentEvent.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.people, color: primaryColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Mevcut Katılımcı: ${currentEvent.currentCount} / ${currentEvent.maxCapacity}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      '* Sen (Yönetici) sayıya dahilsin.',
                      style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),

              // ORTA KISIM: Katılımcı Listesi Başlığı
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.list_alt),
                    const SizedBox(width: 8),
                    const Text('Katılımcı Listesi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Text('${currentEvent.approvedUserIds.length} Kişi', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              // ALT KISIM: Katılımcıları Fetch edip listeleme
              Expanded(
                child: currentEvent.approvedUserIds.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_off, size: 50, color: Colors.grey.shade400),
                      const SizedBox(height: 10),
                      Text('Henüz kimse katılmadı.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                    ],
                  ),
                )
                    : FutureBuilder<List<UserModel>>(
                  future: _fetchParticipants(currentEvent.approvedUserIds),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!userSnapshot.hasData || userSnapshot.data!.isEmpty) {
                      return const Center(child: Text('Kullanıcı bilgileri alınamadı.'));
                    }

                    final participants = userSnapshot.data!;

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: participants.length,
                      itemBuilder: (context, index) {
                        final user = participants[index];
                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 8),
                          color: isDark ? const Color(0xFF2A2324) : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade300, width: 0.5),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: primaryColor.withOpacity(0.2),
                              child: Text(
                                user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                                style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${user.department} • ${user.grade}. Sınıf'),
                            trailing: IconButton(
                              icon: const Icon(Icons.person_remove, color: Colors.redAccent),
                              tooltip: 'Etkinlikten Çıkar',
                              onPressed: () => _removeParticipant(user.uid, user.fullName),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),

      // EN ALT KISIM: Etkinliği Sil Butonu
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _deleteEvent,
            icon: const Icon(Icons.delete_forever),
            label: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Etkinliği İptal Et & Sil', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(55),
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }
}