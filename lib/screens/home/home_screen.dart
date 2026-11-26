import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/event_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/event_service.dart';
import 'event_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _eventService = EventService();

  UserModel? _currentUser;
  bool _isLoading = true;

  final Color _primaryColor = const Color(0xFF6A1221);

  @override
  void initState() {
    super.initState();
    _loadUser();
    _checkLocationPermission(); // BAŞLANGIÇTA KONUM İZNİ İSTENECEK
  }

  // --- KONUM İZNİ KONTROL FONKSİYONU ---
  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }
  }

  Future<void> _loadUser() async {
    try {
      final user = await _authService.getCurrentUserProfile();

      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF151112)
            : const Color(0xFFF8F5F3),
        body: Center(
          child: CircularProgressIndicator(
            color: _primaryColor,
          ),
        ),
      );
    }

    if (_currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Kullanıcı bilgileri yüklenemedi.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF151112)
          : const Color(0xFFF8F5F3),
      body: SafeArea(
        child: StreamBuilder<List<EventModel>>(
          stream: _eventService.getOpenEvents(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Etkinlikler yüklenirken hata oluştu:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              );
            }

            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(
                  color: _primaryColor,
                ),
              );
            }

            final now = DateTime.now();

            final myEvents = snapshot.data!.where((event) {
              return event.hostId == _currentUser!.uid ||
                  event.approvedUserIds.contains(_currentUser!.uid);
            }).toList();

            final upcomingEvents = myEvents.where((event) {
              return !event.eventDate.isBefore(now);
            }).toList();

            final pastEvents = myEvents.where((event) {
              return event.eventDate.isBefore(now);
            }).toList();

            upcomingEvents.sort(
                  (a, b) => a.eventDate.compareTo(b.eventDate),
            );

            pastEvents.sort(
                  (a, b) => b.eventDate.compareTo(a.eventDate),
            );

            return RefreshIndicator(
              color: _primaryColor,
              onRefresh: () async {
                setState(() {});
                await Future.delayed(
                  const Duration(milliseconds: 500),
                );
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  35,
                ),
                children: [
                  _buildTopBar(isDark),

                  const SizedBox(height: 24),

                  _buildWelcomeSection(isDark),

                  const SizedBox(height: 24),

                  if (upcomingEvents.isNotEmpty)
                    _buildFeaturedEvent(
                      upcomingEvents.first,
                      isDark,
                    ),

                  if (upcomingEvents.isNotEmpty)
                    const SizedBox(height: 30),

                  _buildSectionTitle(
                    title: 'Yaklaşan Etkinlikler',
                    subtitle: upcomingEvents.isEmpty
                        ? 'Henüz katıldığın bir etkinlik yok'
                        : '${upcomingEvents.length} etkinlik seni bekliyor',
                    isDark: isDark,
                  ),

                  const SizedBox(height: 14),

                  if (upcomingEvents.isEmpty)
                    _buildEmptyState(
                      message: 'Yaklaşan bir etkinliğin yok.',
                      subtitle:
                      'Keşfet bölümünden yeni etkinliklere göz atabilirsin.',
                      icon: Icons.explore_outlined,
                      isDark: isDark,
                    )
                  else
                    ...upcomingEvents.map(
                          (event) => _buildModernEventCard(
                        event,
                        isDark,
                        false,
                      ),
                    ),

                  const SizedBox(height: 32),

                  _buildSectionTitle(
                    title: 'Önceden Katıldıklarım',
                    subtitle: pastEvents.isEmpty
                        ? 'Henüz tamamlanan etkinlik yok'
                        : '${pastEvents.length} geçmiş etkinlik',
                    isDark: isDark,
                  ),

                  const SizedBox(height: 14),

                  if (pastEvents.isEmpty)
                    _buildEmptyState(
                      message: 'Geçmiş etkinliğin bulunmuyor.',
                      subtitle:
                      'Katıldığın etkinlikler burada görünecek.',
                      icon: Icons.history_rounded,
                      isDark: isDark,
                    )
                  else
                    ...pastEvents.map(
                          (event) => _buildModernEventCard(
                        event,
                        isDark,
                        true,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopBar(bool isDark) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _primaryColor,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: _primaryColor.withOpacity(0.22),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              '4',
              style: TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            'dördünCü',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: isDark ? Colors.white : const Color(0xFF252329),
            ),
          ),
        ),

        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF241C1D)
                : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.05),
            ),
          ),
          child: Icon(
            Icons.notifications_none_rounded,
            color: isDark
                ? Colors.white
                : const Color(0xFF252329),
            size: 23,
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeSection(bool isDark) {
    final firstName =
        _currentUser!.fullName.trim().split(' ').first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Merhaba, $firstName 👋',
          style: TextStyle(
            fontSize: 29,
            height: 1.1,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: isDark ? Colors.white : const Color(0xFF201D20),
          ),
        ),
        const SizedBox(height: 9),
        Text(
          'Bugün seni hangi etkinlik bekliyor?',
          style: TextStyle(
            fontSize: 15,
            color: isDark
                ? Colors.white.withOpacity(0.62)
                : const Color(0xFF777277),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedEvent(
      EventModel event,
      bool isDark,
      ) {
    return GestureDetector(
      onTap: () => _openEvent(event),
      child: Container(
        height: 245,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(27),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                isDark ? 0.25 : 0.12,
              ),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(27),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildEventImage(
                event,
                height: 245,
              ),

              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.08),
                      Colors.black.withOpacity(0.82),
                    ],
                  ),
                ),
              ),

              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.94),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    event.category.isEmpty
                        ? 'ETKİNLİK'
                        : event.category.toUpperCase(),
                    style: TextStyle(
                      color: _primaryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_outward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),

              Positioned(
                left: 20,
                right: 20,
                bottom: 18,
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        height: 1.05,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.locationName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 7),

                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(event.eventDate),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.people_alt_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${event.currentCount}/${event.maxCapacity}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle({
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: isDark
                      ? Colors.white
                      : const Color(0xFF252329),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark
                      ? Colors.white.withOpacity(0.5)
                      : Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernEventCard(
      EventModel event,
      bool isDark,
      bool isPast,
      ) {
    return GestureDetector(
      onTap: () => _openEvent(event),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF211A1B)
              : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.045),
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.045),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              SizedBox(
                width: 102,
                height: 106,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildEventImage(
                        event,
                        height: 106,
                      ),
                      if (isPast)
                        Container(
                          color: Colors.black.withOpacity(0.35),
                        ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.94),
                            borderRadius:
                            BorderRadius.circular(9),
                          ),
                          child: Column(
                            children: [
                              Text(
                                _monthName(
                                  event.eventDate.month,
                                ),
                                style: TextStyle(
                                  color: _primaryColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '${event.eventDate.day}',
                                style: TextStyle(
                                  color: _primaryColor,
                                  fontSize: 17,
                                  height: 1,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: SizedBox(
                  height: 106,
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              event.title,
                              maxLines: 2,
                              overflow:
                              TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.15,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF242124),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: isDark
                                ? Colors.white38
                                : Colors.grey.shade400,
                            size: 22,
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: isDark
                                ? Colors.white54
                                : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.locationName,
                              maxLines: 1,
                              overflow:
                              TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white54
                                    : Colors.grey.shade600,
                                fontWeight:
                                FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      Row(
                        children: [
                          Icon(
                            Icons.people_alt_rounded,
                            size: 14,
                            color: _primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${event.currentCount}/${event.maxCapacity}',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: _primaryColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding:
                            const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: isPast
                                  ? Colors.grey.withOpacity(
                                0.12,
                              )
                                  : _primaryColor.withOpacity(
                                0.09,
                              ),
                              borderRadius:
                              BorderRadius.circular(9),
                            ),
                            child: Text(
                              isPast
                                  ? 'Tamamlandı'
                                  : 'Yaklaşıyor',
                              style: TextStyle(
                                color: isPast
                                    ? Colors.grey
                                    : _primaryColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventImage(
      EventModel event, {
        required double height,
      }) {
    final imagePath = _getImageForCategory(
      event.category,
    );

    return Image.asset(
      imagePath,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _buildImagePlaceholder(event);
      },
    );
  }

  Widget _buildImagePlaceholder(EventModel event) {
    IconData icon;

    final category = event.category.toLowerCase();

    if (category.contains('spor') ||
        category.contains('futbol') ||
        category.contains('basket')) {
      icon = Icons.sports_soccer_rounded;
    } else if (category.contains('müzik') ||
        category.contains('konser')) {
      icon = Icons.music_note_rounded;
    } else if (category.contains('oyun')) {
      icon = Icons.sports_esports_rounded;
    } else if (category.contains('sinema') ||
        category.contains('film')) {
      icon = Icons.movie_rounded;
    } else if (category.contains('kahve') ||
        category.contains('sohbet')) {
      icon = Icons.local_cafe_rounded;
    } else {
      icon = Icons.celebration_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _primaryColor,
            Color.lerp(
              _primaryColor,
              Colors.black,
              0.35,
            )!,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          color: Colors.white.withOpacity(0.9),
          size: 48,
        ),
      ),
    );
  }

  // --- EKSİK OLAN FONKSİYON EKLENDİ ---
  Widget _buildEmptyState({
    required String message,
    required String subtitle,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 30,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF211A1B)
            : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.045),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: _primaryColor,
              size: 29,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? Colors.white
                  : const Color(0xFF333033),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: isDark
                  ? Colors.white54
                  : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  String _getImageForCategory(String category) {
    final value = category.toLowerCase();

    if (value.contains('spor') ||
        value.contains('futbol') ||
        value.contains('basket')) {
      return 'assets/images/event_sports.jpg';
    }

    if (value.contains('müzik') ||
        value.contains('konser')) {
      return 'assets/images/event_music.jpg';
    }

    if (value.contains('sinema') ||
        value.contains('film')) {
      return 'assets/images/event_cinema.jpg';
    }

    if (value.contains('oyun')) {
      return 'assets/images/event_game.jpg';
    }

    if (value.contains('kahve') ||
        value.contains('sohbet')) {
      return 'assets/images/event_coffee.jpg';
    }

    return 'assets/images/event_general.jpg';
  }

  String _formatDate(DateTime date) {
    const months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
    ];

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final monthName = months[date.month - 1];

    return '${date.day} $monthName $hour:$minute';
  }

  String _monthName(int month) {
    const months = [
      'OCA', 'ŞUB', 'MAR', 'NİS', 'MAY', 'HAZ',
      'TEM', 'AĞU', 'EYL', 'EKİ', 'KAS', 'ARA',
    ];

    return months[month - 1];
  }

  void _openEvent(EventModel event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailScreen(
          event: event,
          currentUser: _currentUser!,
        ),
      ),
    );
  }
}