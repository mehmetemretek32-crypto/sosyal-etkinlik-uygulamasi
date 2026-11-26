import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/event_model.dart';
import '../../models/user_model.dart';
import '../../services/event_service.dart';
import 'event_requests_screen.dart';
import 'event_chat_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final EventModel event;
  final UserModel currentUser;

  const EventDetailScreen({
    super.key,
    required this.event,
    required this.currentUser,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final _eventService = EventService();
  final Color _primaryColor = const Color(0xFF6A1221); // İMZA BORDO
  bool _isLoading = false;

  late EventModel _currentEvent;

  @override
  void initState() {
    super.initState();
    _currentEvent = widget.event;
  }

  Future<void> _joinEvent() async {
    setState(() => _isLoading = true);
    try {
      await _eventService.joinEvent(_currentEvent.id, widget.currentUser.uid, _currentEvent.requiresApproval);
      setState(() {
        if (_currentEvent.requiresApproval) {
          _currentEvent.pendingUserIds.add(widget.currentUser.uid);
        } else {
          _currentEvent.approvedUserIds.add(widget.currentUser.uid);
        }
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_currentEvent.requiresApproval ? 'Katılım isteği gönderildi!' : 'Etkinliğe katıldın!'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _leaveEvent() async {
    setState(() => _isLoading = true);
    try {
      await _eventService.leaveEvent(_currentEvent.id, widget.currentUser.uid);
      setState(() {
        _currentEvent.approvedUserIds.remove(widget.currentUser.uid);
        _currentEvent.pendingUserIds.remove(widget.currentUser.uid);
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Etkinlikten ayrıldın.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteEvent() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Etkinliği İptal Et', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text('Bu etkinliği tamamen silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, elevation: 0),
            onPressed: () async {
              Navigator.pop(context); Navigator.pop(context);
              setState(() => _isLoading = true);
              await FirebaseFirestore.instance.collection('events').doc(_currentEvent.id).delete();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Etkinlik iptal edildi.'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Evet, Sil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showManageOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 20),
                Text('Etkinliği Yönet', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.blue)),
                  title: Text('Grup Sohbetini Aç', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                  trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                  onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => EventChatScreen(event: _currentEvent, currentUser: widget.currentUser))); },
                ),
                ListTile(
                  leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: _primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(Icons.group_add_rounded, color: _primaryColor)),
                  title: Text('Katılım İsteklerini Gör', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                  subtitle: Text('${_currentEvent.pendingUserIds.length} bekleyen istek var', style: TextStyle(color: Colors.grey.shade500)),
                  trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                  onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => EventRequestsScreen(currentUser: widget.currentUser))); },
                ),
                ListTile(
                  leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.delete_forever_rounded, color: Colors.red)),
                  title: const Text('Etkinliği İptal Et', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  subtitle: Text('Etkinliği kalıcı olarak siler', style: TextStyle(color: Colors.grey.shade500)),
                  onTap: _deleteEvent,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getImageForCategory(String category) {
    final value = category.toLowerCase();
    if (value.contains('spor') || value.contains('futbol')) return 'assets/images/event_sports.jpg';
    if (value.contains('müzik') || value.contains('konser')) return 'assets/images/event_music.jpg';
    if (value.contains('sinema') || value.contains('film')) return 'assets/images/event_cinema.jpg';
    if (value.contains('oyun')) return 'assets/images/event_game.jpg';
    if (value.contains('kahve') || value.contains('sohbet')) return 'assets/images/event_coffee.jpg';
    return 'assets/images/event_general.jpg';
  }

  String _monthName(int month) {
    const months = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;

    bool isHost = _currentEvent.hostId == widget.currentUser.uid;
    bool isApproved = _currentEvent.approvedUserIds.contains(widget.currentUser.uid);
    bool isPending = _currentEvent.pendingUserIds.contains(widget.currentUser.uid);
    bool isFull = _currentEvent.currentCount >= _currentEvent.maxCapacity;

    // Harita koordinatlarını kontrol et (Eğer modelde varsa)
    double? eventLat;
    double? eventLng;
    try {
      // ignore: avoid_dynamic_calls
      eventLat = (_currentEvent as dynamic).latitude;
      // ignore: avoid_dynamic_calls
      eventLng = (_currentEvent as dynamic).longitude;
    } catch (_) {}

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320.0,
            pinned: true,
            backgroundColor: bgColor,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), shape: BoxShape.circle),
                    child: const Icon(Icons.ios_share_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(_getImageForCategory(_currentEvent.category), fit: BoxFit.cover),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [Colors.black.withValues(alpha: 0.5), Colors.transparent, bgColor],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_currentEvent.title, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: textColor, letterSpacing: -0.5, height: 1.1)),
                  const SizedBox(height: 24),

                  // ZAMAN
                  _buildListTileInfo(
                    icon: Icons.calendar_month_rounded,
                    title: '${_currentEvent.eventDate.day} ${_monthName(_currentEvent.eventDate.month)} ${DateFormat('yyyy').format(_currentEvent.eventDate)}',
                    subtitle: '${DateFormat('HH:mm').format(_currentEvent.eventDate)} - ${DateFormat('HH:mm').format(_currentEvent.endDate)}',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),

                  // KONUM
                  _buildListTileInfo(
                    icon: _currentEvent.isOnline ? Icons.videocam_rounded : Icons.location_on_rounded,
                    title: _currentEvent.locationName,
                    subtitle: _currentEvent.isOnline ? 'Online Etkinlik' : 'Sivas Cumhuriyet Üniversitesi',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 32),

                  // DÜZENLEYEN (HOST) KARTI
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26, backgroundColor: _primaryColor.withValues(alpha: 0.1),
                          child: Text(_currentEvent.hostName.isNotEmpty ? _currentEvent.hostName[0].toUpperCase() : '?', style: TextStyle(color: _primaryColor, fontWeight: FontWeight.w900, fontSize: 22)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Düzenleyen', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
                              const SizedBox(height: 2),
                              Text(_currentEvent.hostName, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: textColor)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(_currentEvent.hostRating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.amber)),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // KATILIMCILAR
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Katılımcılar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textColor)),
                      Text('${_currentEvent.currentCount} / ${_currentEvent.maxCapacity}', style: TextStyle(fontWeight: FontWeight.w900, color: _primaryColor, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildAttendeesAvatars(_currentEvent.currentCount, isDark),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(isFull ? 'Kontejan Doldu' : '${_currentEvent.maxCapacity - _currentEvent.currentCount} kişilik yer kaldı', style: TextStyle(fontWeight: FontWeight.bold, color: isFull ? Colors.red : textColor)),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: _currentEvent.currentCount / (_currentEvent.maxCapacity == 0 ? 1 : _currentEvent.maxCapacity),
                                minHeight: 6,
                                backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 32),

                  // GERÇEK HARİTA ÖNİZLEMESİ (OpenStreetMap)
                  if (!_currentEvent.isOnline && eventLat != null && eventLng != null) ...[
                    Text('Etkinlik Konumu', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textColor)),
                    const SizedBox(height: 16),
                    Container(
                      height: 180, width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(eventLat, eventLng),
                            initialZoom: 16.0,
                            interactionOptions: const InteractionOptions(flags: InteractiveFlag.none), // Sabit önizleme haritası
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: isDark
                                  ? 'https://cartodb-basemaps-{s}.global.ssl.fastly.net/dark_all/{z}/{x}/{y}.png'
                                  : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.dorduncu.app',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(eventLat, eventLng),
                                  width: 40,
                                  height: 40,
                                  child: Icon(Icons.location_on_rounded, color: _primaryColor, size: 40),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // ETİKETLER
                  if (_currentEvent.tags.isNotEmpty) ...[
                    Text('Etiketler', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textColor)),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: _currentEvent.tags.map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade200),
                        ),
                        child: Text('#$tag', style: TextStyle(color: isDark ? Colors.grey.shade300 : Colors.grey.shade700, fontWeight: FontWeight.w700)),
                      )).toList(),
                    ),
                    const SizedBox(height: 40),
                  ]
                ],
              ),
            ),
          )
        ],
      ),

      // SABİT ALT AKSİYON BAR
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121212) : Colors.white,
          border: Border(top: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200)),
        ),
        child: SafeArea(
          child: _isLoading
              ? const SizedBox(height: 50, child: Center(child: CircularProgressIndicator()))
              : _buildActionButton(isHost, isApproved, isPending, isFull, isDark),
        ),
      ),
    );
  }

  Widget _buildListTileInfo({required IconData icon, required String title, required String subtitle, required bool isDark}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
          child: Icon(icon, color: _primaryColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade500), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttendeesAvatars(int count, bool isDark) {
    int displayCount = count > 5 ? 5 : count;
    if (displayCount == 0) return const SizedBox();

    return SizedBox(
      width: (displayCount * 28.0) + 12.0,
      height: 40,
      child: Stack(
        children: List.generate(displayCount, (index) {
          return Positioned(
            left: index * 22.0,
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _primaryColor.withValues(alpha: 1.0 - (index * 0.15)),
                border: Border.all(color: isDark ? const Color(0xFF121212) : Colors.white, width: 3),
              ),
              child: const Center(child: Icon(Icons.person_rounded, color: Colors.white, size: 20)),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildActionButton(bool isHost, bool isApproved, bool isPending, bool isFull, bool isDark) {
    if (isHost) {
      return ElevatedButton(
        onPressed: _showManageOptions,
        style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 0),
        child: const Text('Etkinliği Yönet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
      );
    }

    if (isApproved) {
      return Row(
        children: [
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventChatScreen(event: _currentEvent, currentUser: widget.currentUser))),
              icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 20),
              label: const Text('Sohbete Gir', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade600, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 0),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: OutlinedButton(
              onPressed: _leaveEvent,
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: const BorderSide(color: Colors.red, width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
              child: const Icon(Icons.exit_to_app_rounded, color: Colors.red),
            ),
          ),
        ],
      );
    }

    if (isPending) {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(disabledBackgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 0),
        child: const Text('Onay Bekleniyor', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.orange)),
      );
    }

    if (isFull) {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(disabledBackgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 0),
        child: const Text('Kontejan Doldu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.grey)),
      );
    }

    return ElevatedButton(
      onPressed: _joinEvent,
      style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 0),
      child: Text(_currentEvent.requiresApproval ? 'Katılım İsteği Gönder' : 'Hemen Katıl', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
    );
  }
}