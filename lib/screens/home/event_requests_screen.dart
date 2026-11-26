import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/event_model.dart';
import '../../models/user_model.dart';
import '../../services/event_service.dart';

class EventRequestsScreen extends StatefulWidget {
  final UserModel currentUser;

  const EventRequestsScreen({super.key, required this.currentUser});

  @override
  State<EventRequestsScreen> createState() => _EventRequestsScreenState();
}

class _EventRequestsScreenState extends State<EventRequestsScreen> {
  final _eventService = EventService();
  final Color _primaryColor = const Color(0xFF6A1221);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF151112) : const Color(0xFFF8F5F3),
      appBar: AppBar(
        title: const Text('Katılım İstekleri', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: StreamBuilder<List<EventModel>>(
        stream: _eventService.getEventRequests(widget.currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Bir hata oluştu: ${snapshot.error}', style: TextStyle(color: isDark ? Colors.white : Colors.black87)));
          }
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator(color: _primaryColor));
          }

          final events = snapshot.data!;

          if (events.isEmpty) {
            return _buildEmptyState(isDark);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return _buildEventRequestCard(event, isDark);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(color: _primaryColor.withOpacity(0.08), shape: BoxShape.circle),
            child: Icon(Icons.mark_email_read_rounded, color: _primaryColor, size: 40),
          ),
          const SizedBox(height: 16),
          Text(
            'Bekleyen İstek Yok',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            'Etkinliklerine gelen katılım talepleri\nburada görünecektir.',
            textAlign: TextAlign.center,
            style: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade600, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildEventRequestCard(EventModel event, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF241C1D) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_activity_rounded, color: _primaryColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    event.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('${event.pendingUserIds.length} İstek', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                )
              ],
            ),
            const Divider(height: 24),

            // İstek Atan Kullanıcıları Listele
            ...event.pendingUserIds.map((userId) => _buildUserRequestTile(event.id, userId, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildUserRequestTile(String eventId, String userId, bool isDark) {
    return FutureBuilder<DocumentSnapshot>(
      // Firestore'dan kullanıcının güncel bilgilerini (isim, bölüm) çekiyoruz
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Center(child: LinearProgressIndicator()),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        if (userData == null) return const SizedBox(); // Kullanıcı silinmişse gösterme

        final userName = userData['fullName'] ?? 'Bilinmeyen Kullanıcı';
        final department = userData['department'] ?? 'Bölüm belirtilmemiş';
        final initial = userName.isNotEmpty ? userName[0].toUpperCase() : '?';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: _primaryColor.withOpacity(0.1),
                radius: 20,
                child: Text(initial, style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(department, style: TextStyle(fontSize: 12, color: Colors.grey.shade500), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),

              // REDDET BUTONU
              InkWell(
                onTap: () => _eventService.rejectRequest(eventId, userId),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.close_rounded, color: Colors.red, size: 20),
                ),
              ),
              const SizedBox(width: 8),

              // ONAYLA BUTONU
              InkWell(
                onTap: () => _eventService.approveRequest(eventId, userId),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.check_rounded, color: Colors.green, size: 20),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}