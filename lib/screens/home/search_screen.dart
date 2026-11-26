import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../../models/user_model.dart';
import '../../services/event_service.dart';
import 'event_detail_screen.dart';
import 'events_map_screen.dart';

class CategoryItem {
  final String name;
  final IconData icon;

  CategoryItem(this.name, this.icon);
}

class SearchScreen extends StatefulWidget {
  final UserModel currentUser;

  const SearchScreen({super.key, required this.currentUser});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _eventService = EventService();
  final Color _primaryColor = const Color(0xFF6A1221);

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String _selectedCategory = 'Tüm Etkinlikler';

  final List<CategoryItem> _categories = [
    CategoryItem('Tüm Etkinlikler', Icons.explore_rounded),
    CategoryItem('Eğlence', Icons.celebration_rounded),
    CategoryItem('Spor', Icons.emoji_events_rounded),
    CategoryItem('Eğitim', Icons.school_rounded),
    CategoryItem('Oyun', Icons.sports_esports_rounded),
    CategoryItem('Sohbet', Icons.forum_rounded),
    CategoryItem('Yemek', Icons.restaurant_rounded),
    CategoryItem('Kültür', Icons.palette_rounded),
    CategoryItem('Müzik', Icons.music_note_rounded),
  ];

  final Set<String> _savedEventIds = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSave(String eventId) {
    setState(() {
      if (_savedEventIds.contains(eventId)) {
        _savedEventIds.remove(eventId);
      } else {
        _savedEventIds.add(eventId);
      }
    });
  }

  void _shareEvent(EventModel event) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Etkinlik bağlantısı kopyalandı!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        )
    );
  }

  // YEREL GÖRSELLER İÇİN GÜVENLİ FONKSİYON
  String _getImageForCategory(String category) {
    final value = category.toLowerCase();
    if (value.contains('spor') || value.contains('futbol')) return 'assets/images/event_sports.jpg';
    if (value.contains('müzik') || value.contains('konser')) return 'assets/images/event_music.jpg';
    if (value.contains('sinema') || value.contains('film')) return 'assets/images/event_cinema.jpg';
    if (value.contains('oyun')) return 'assets/images/event_game.jpg';
    if (value.contains('kahve') || value.contains('sohbet')) return 'assets/images/event_coffee.jpg';
    return 'assets/images/event_general.jpg';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
                        ],
                        border: isDark ? Border.all(color: Colors.white12) : null,
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: 'Kampüste etkinlik ara...',
                          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15, fontWeight: FontWeight.normal),
                          prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade500),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      boxShadow: [
                        if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
                      ],
                      border: isDark ? Border.all(color: Colors.white12) : null,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.tune_rounded, color: textColor),
                      onPressed: () {},
                    ),
                  )
                ],
              ),
            ),

            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category.name;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = category.name),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? _primaryColor : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isSelected ? _primaryColor : (isDark ? Colors.white12 : Colors.grey.shade300),
                          width: 1.5,
                        ),
                        boxShadow: isSelected
                            ? [BoxShadow(color: _primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            category.icon,
                            size: 18,
                            color: isSelected ? Colors.white : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            category.name,
                            style: TextStyle(
                              color: isSelected ? Colors.white : (isDark ? Colors.grey.shade300 : Colors.black87),
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),
            Divider(height: 1, color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade200),

            Expanded(
              child: StreamBuilder<List<EventModel>>(
                stream: _eventService.getOpenEvents(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return const Center(child: Text('Hata oluştu.'));
                  if (!snapshot.hasData) return Center(child: CircularProgressIndicator(color: _primaryColor));

                  final activeEvents = snapshot.data!.where((event) {
                    // Arama çubuğu filtresi
                    bool matchesSearch = _searchQuery.isEmpty || event.title.toLowerCase().contains(_searchQuery.toLowerCase());

                    // Kategori filtresi (Büyük/küçük harf ve boşluk duyarsız hale getirildi)
                    bool matchesCategory = _selectedCategory == 'Tüm Etkinlikler' ||
                        event.category.trim().toLowerCase() == _selectedCategory.trim().toLowerCase();

                    return matchesSearch && matchesCategory;
                  }).toList();

                  activeEvents.sort((a, b) => a.eventDate.compareTo(b.eventDate));

                  if (activeEvents.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded, size: 60, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text('Bu kategoride etkinlik bulunamadı.', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 20, bottom: 80),
                    itemCount: activeEvents.length,
                    itemBuilder: (context, index) {
                      return _buildPremiumEventCard(activeEvents[index], isDark);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => EventsMapScreen(currentUser: widget.currentUser)));
        },
        backgroundColor: _primaryColor,
        elevation: 4,
        icon: const Icon(Icons.map_rounded, color: Colors.white),
        label: const Text('Haritayı Gör', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildPremiumEventCard(EventModel event, bool isDark) {
    final isSaved = _savedEventIds.contains(event.id);
    final seatsLeft = event.maxCapacity - event.currentCount;
    final isFull = seatsLeft <= 0;

    // YENİ GÜVENLİ RESİM SEÇİCİ (NoSuchMethodError Çözümü)
    String? imageUrl;
    try {
      // Eğer modelinde coverImage varsa onu almaya çalış
      // ignore: avoid_dynamic_calls
      imageUrl = (event as dynamic).coverImage;
    } catch (_) {
      // Modelde henüz yoksa yerel resmi kullanmak için null bırak
    }

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(event: event, currentUser: widget.currentUser))),
      child: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 200,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // RESİM GÖSTERİMİ (Güvenli Yöntem)
                    if (imageUrl != null && imageUrl.startsWith('http'))
                      Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Image.asset(_getImageForCategory(event.category), fit: BoxFit.cover),
                      )
                    else
                      Image.asset(
                        _getImageForCategory(event.category),
                        fit: BoxFit.cover,
                      ),

                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.4),
                            Colors.transparent,
                            Colors.black.withOpacity(0.2),
                          ],
                        ),
                      ),
                    ),

                    Positioned(
                      top: 16, left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            Icon(isFull ? Icons.block_rounded : Icons.info_outline_rounded, color: isFull ? Colors.redAccent : Colors.white, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              isFull ? 'Dolu' : '$seatsLeft kişilik yer kaldı',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Positioned(
                      top: 12, right: 12,
                      child: Row(
                        children: [
                          _buildOverlayIconBtn(Icons.ios_share_rounded, () => _shareEvent(event)),
                          const SizedBox(width: 8),
                          _buildOverlayIconBtn(
                            isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                () => _toggleSave(event.id),
                            iconColor: isSaved ? Colors.redAccent : Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              event.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black,
                letterSpacing: -0.5,
                height: 1.2,
              ),
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Text(
                  '${_monthName(event.eventDate.month)} ${event.eventDate.day} • ${event.eventDate.hour.toString().padLeft(2, '0')}:${event.eventDate.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade500),
                ),
                Text(' • ', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                Icon(event.isOnline ? Icons.videocam_rounded : Icons.location_on_rounded, size: 16, color: isDark ? Colors.white70 : Colors.grey.shade700),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    event.locationName,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.grey.shade800),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Text(
                  'Düzenleyen: ${event.hostName}',
                  style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                ),
                Text(' • ', style: TextStyle(color: Colors.grey.shade500)),
                Text(
                  event.hostRating.toStringAsFixed(1),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                _buildAttendeesAvatars(event.currentCount, isDark),
                const SizedBox(width: 10),
                Text(
                  '${event.currentCount} kişi gidiyor',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlayIconBtn(IconData icon, VoidCallback onTap, {Color iconColor = Colors.white}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }

  Widget _buildAttendeesAvatars(int count, bool isDark) {
    int displayCount = count > 3 ? 3 : count;
    if (displayCount == 0) return const SizedBox();

    return SizedBox(
      width: (displayCount * 22.0) + 8.0,
      height: 28,
      child: Stack(
        children: List.generate(displayCount, (index) {
          return Positioned(
            left: index * 16.0,
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _primaryColor.withOpacity(0.8 - (index * 0.2)),
                border: Border.all(color: isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA), width: 2),
              ),
              child: const Center(
                child: Text('?', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          );
        }),
      ),
    );
  }

  String _monthName(int month) {
    const months = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
    return months[month - 1];
  }
}