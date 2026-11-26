import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../../models/user_model.dart';
import '../../services/event_service.dart';
import 'event_detail_screen.dart';

class SavedEventsScreen extends StatefulWidget {
  final UserModel currentUser;

  const SavedEventsScreen({super.key, required this.currentUser});

  @override
  State<SavedEventsScreen> createState() => _SavedEventsScreenState();
}

class _SavedEventsScreenState extends State<SavedEventsScreen> {
  final EventService _eventService = EventService();
  final Color _primaryColor = const Color(0xFF6A1221);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text('Kaydedilenler', style: TextStyle(fontWeight: FontWeight.w900, color: textColor, letterSpacing: -0.5)),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // Şimdilik test için tüm aktif etkinlikleri listeliyoruz.
      // İleride buraya sadece Firebase'den gelen kullanıcının kaydettikleri düşecek.
      body: StreamBuilder<List<EventModel>>(
        stream: _eventService.getOpenEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: _primaryColor));
          }

          final events = snapshot.data ?? [];

          if (events.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E1E) : Colors.white, shape: BoxShape.circle),
                    child: Icon(Icons.bookmark_border_rounded, size: 60, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 20),
                  Text('Henüz etkinlik kaydetmedin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor)),
                  const SizedBox(height: 8),
                  Text('İlgini çeken etkinlikleri kaydederek\ndaha sonra kolayca bulabilirsin.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 10, bottom: 40),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return _buildSavedEventCard(event, isDark);
            },
          );
        },
      ),
    );
  }

  Widget _buildSavedEventCard(EventModel event, bool isDark) {
    String? imageUrl;
    try {
      // ignore: avoid_dynamic_calls
      imageUrl = (event as dynamic).coverImage;
    } catch (_) {}

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(event: event, currentUser: widget.currentUser))),
      child: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
          border: isDark ? Border.all(color: Colors.white12) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(borderRadius: BorderRadius.horizontal(left: Radius.circular(20))),
              child: ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                child: imageUrl != null && imageUrl.startsWith('http')
                    ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallbackImage(event.category))
                    : _fallbackImage(event.category),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isDark ? Colors.white : Colors.black87, height: 1.2)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(event.isOnline ? Icons.videocam_rounded : Icons.location_on_rounded, size: 14, color: _primaryColor),
                        const SizedBox(width: 4),
                        Expanded(child: Text(event.locationName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Icon(Icons.bookmark_rounded, color: _primaryColor, size: 24),
            )
          ],
        ),
      ),
    );
  }

  Widget _fallbackImage(String category) {
    final value = category.toLowerCase();
    String assetPath = 'assets/images/event_general.jpg';
    if (value.contains('spor') || value.contains('futbol')) assetPath = 'assets/images/event_sports.jpg';
    else if (value.contains('müzik') || value.contains('konser')) assetPath = 'assets/images/event_music.jpg';
    else if (value.contains('sinema') || value.contains('film')) assetPath = 'assets/images/event_cinema.jpg';
    else if (value.contains('oyun')) assetPath = 'assets/images/event_game.jpg';
    else if (value.contains('kahve') || value.contains('sohbet')) assetPath = 'assets/images/event_coffee.jpg';

    return Image.asset(assetPath, fit: BoxFit.cover);
  }
}