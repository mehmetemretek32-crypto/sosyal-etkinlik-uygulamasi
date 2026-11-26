import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart'; // YENİ: Konum paketi
import '../../models/event_model.dart';
import '../../models/user_model.dart';
import '../../services/event_service.dart';
import 'event_detail_screen.dart';

class EventsMapScreen extends StatefulWidget {
  final UserModel currentUser;

  const EventsMapScreen({super.key, required this.currentUser});

  @override
  State<EventsMapScreen> createState() => _EventsMapScreenState();
}

class _EventsMapScreenState extends State<EventsMapScreen> {
  final EventService _eventService = EventService();
  final Color _primaryColor = const Color(0xFF6A1221);

  final MapController _mapController = MapController();
  final PageController _pageController = PageController(viewportFraction: 0.85);

  // Sivas Cumhuriyet Üniversitesi Kampüs Merkezi
  final LatLng _campusCenter = const LatLng(39.7088, 37.0225);

  // YENİ: Kullanıcının anlık konumu
  LatLng? _currentLocation;

  List<EventModel> _mapEvents = [];

  @override
  void initState() {
    super.initState();
    _getUserLocation(); // Ekran açılır açılmaz konumu bul
  }

  // YENİ: Kullanıcı Konumunu Bulma Fonksiyonu
  Future<void> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
      // İsteğe bağlı: Haritayı açılışta kullanıcının konumuna kaydır
      // _mapController.move(_currentLocation!, 15.0);
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onCardChanged(int index) {
    final event = _mapEvents[index];
    try {
      // ignore: avoid_dynamic_calls
      final lat = (event as dynamic).latitude;
      // ignore: avoid_dynamic_calls
      final lng = (event as dynamic).longitude;

      if (lat != null && lng != null) {
        _mapController.move(LatLng(lat as double, lng as double), 16.5);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      body: Stack(
        children: [
          // 1. GERÇEK ZAMANLI İNTERAKTİF HARİTA
          StreamBuilder<List<EventModel>>(
            stream: _eventService.getOpenEvents(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                _mapEvents = snapshot.data!.where((e) => !e.isOnline).toList();
              }

              List<Marker> markers = [];

              // YENİ: Etkinlik İğneleri ve Başlıkları
              for (var event in _mapEvents) {
                try {
                  // ignore: avoid_dynamic_calls
                  final lat = (event as dynamic).latitude;
                  // ignore: avoid_dynamic_calls
                  final lng = (event as dynamic).longitude;

                  if (lat != null && lng != null) {
                    markers.add(
                      Marker(
                        point: LatLng(lat as double, lng as double),
                        width: 140, // Başlık sığsın diye genişletildi
                        height: 80, // Başlık + İkon için uzatıldı
                        child: GestureDetector(
                          onTap: () {
                            final index = _mapEvents.indexOf(event);
                            _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // ETKİNLİK İSMİ KUTUCUĞU
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 3))],
                                  border: Border.all(color: _primaryColor.withOpacity(0.5), width: 1.5),
                                ),
                                child: Text(
                                  event.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                              // ALTINDAKİ İĞNE (PIN)
                              Icon(
                                Icons.location_on_rounded,
                                color: _primaryColor,
                                size: 40,
                                shadows: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4)],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                } catch (_) {}
              }

              // YENİ: Kullanıcının Kendi Konumu (Mavi Parlayan Nokta)
              if (_currentLocation != null) {
                markers.add(
                  Marker(
                    point: _currentLocation!,
                    width: 40,
                    height: 40,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 24, height: 24,
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 16, height: 16,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _campusCenter,
                  initialZoom: 15.0,
                  minZoom: 10.0,
                  maxZoom: 18.0,
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                ),
                children: [
                  TileLayer(
                    urlTemplate: isDark
                        ? 'https://cartodb-basemaps-{s}.global.ssl.fastly.net/dark_all/{z}/{x}/{y}.png'
                        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.dorduncu.app',
                  ),
                  MarkerLayer(markers: markers),
                ],
              );
            },
          ),

          // 2. ÜST BAR
          Positioned(
            top: 50,
            left: 16,
            child: Row(
              children: [
                FloatingActionButton.small(
                  heroTag: 'back_map_btn',
                  backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  elevation: 4,
                  child: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.map_rounded, color: _primaryColor, size: 18),
                      const SizedBox(width: 8),
                      const Text('Kampüs Haritası', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // BENİ BUL BUTONU (Sağ Üstte)
          Positioned(
            top: 50,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'my_location_btn',
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              elevation: 4,
              onPressed: () {
                if (_currentLocation != null) {
                  _mapController.move(_currentLocation!, 16.5);
                } else {
                  _getUserLocation();
                }
              },
              child: const Icon(Icons.my_location_rounded, color: Colors.blue),
            ),
          ),

          // 3. ALT KARTLAR
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 150,
              child: _mapEvents.isEmpty
                  ? const SizedBox()
                  : PageView.builder(
                controller: _pageController,
                onPageChanged: _onCardChanged,
                itemCount: _mapEvents.length,
                itemBuilder: (context, index) {
                  final event = _mapEvents[index];
                  return _buildMapEventCard(event, isDark);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapEventCard(EventModel event, bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(event: event, currentUser: widget.currentUser))),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Row(
          children: [
            Container(
              width: 110,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
                child: Image.network(
                  (event as dynamic).coverImage ?? 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=600&q=80',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey.shade300, child: const Icon(Icons.broken_image, color: Colors.grey)),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: _primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(event.category.toUpperCase(), style: TextStyle(color: _primaryColor, fontSize: 10, fontWeight: FontWeight.w900)),
                    ),
                    const SizedBox(height: 8),
                    Text(event.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isDark ? Colors.white : Colors.black)),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Expanded(child: Text(event.locationName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}