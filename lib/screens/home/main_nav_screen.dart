import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/user_model.dart';
import '../../services/auth_service.dart';

import 'home_screen.dart';
import 'search_screen.dart';
import 'create_event_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _currentIndex = 0;
  final _authService = AuthService();
  final Color _primaryColor = const Color(0xFF6A1221); // İMZA BORDO
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _authService.getCurrentUserProfile();
    if (mounted) {
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    }
  }

  Widget _getPage(int index) {
    if (_currentUser == null) return const Center(child: CircularProgressIndicator());
    switch (index) {
      case 0: return const HomeScreen();
      case 1: return SearchScreen(currentUser: _currentUser!);
      case 2: return NotificationsScreen(currentUser: _currentUser!);
      case 3: return ProfileScreen(currentUser: _currentUser!);
      default: return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading || _currentUser == null) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
        body: Center(child: CircularProgressIndicator(color: _primaryColor)),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F5F3),
      body: _getPage(_currentIndex),

      // ÇIKINTILI VE UÇAN BUTONU KALDIRDIK, YERİNE MODERN VE İÇ İÇE (INLINE) BAR YAPTIK
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          border: Border(top: BorderSide(color: isDark ? Colors.transparent : Colors.grey.shade200)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem(Icons.home_outlined, Icons.home_rounded, 'Ana Sayfa', 0, isDark),
                _buildNavItem(Icons.explore_outlined, Icons.explore_rounded, 'Keşfet', 1, isDark),

                // DAHA BASİT, HİZALI VE MODERN ORTA BUTON (INSTAGRAM/TIKTOK TARZI)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateEventScreen(
                          currentUser: _currentUser!,
                          onSuccess: () {
                            Navigator.pop(context);
                            setState(() => _currentIndex = 0);
                          },
                        ),
                      ),
                    );
                  },
                  child: Container(
                    height: 48,
                    width: 56,
                    decoration: BoxDecoration(
                      color: _primaryColor,
                      borderRadius: BorderRadius.circular(16), // Hafif oval kare tasarım
                    ),
                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
                  ),
                ),

                _buildNotificationNavItem(isDark),
                _buildNavItem(Icons.person_outline_rounded, Icons.person_rounded, 'Profil', 3, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData outlineIcon, IconData filledIcon, String label, int index, bool isDark) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? _primaryColor : (isDark ? Colors.white54 : Colors.black54);

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 65,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isSelected ? filledIcon : outlineIcon, color: color, size: 26),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationNavItem(bool isDark) {
    final isSelected = _currentIndex == 2;
    final color = isSelected ? _primaryColor : (isDark ? Colors.white54 : Colors.black54);

    return InkWell(
      onTap: () => setState(() => _currentIndex = 2),
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 65,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(isSelected ? Icons.notifications_rounded : Icons.notifications_none_rounded, color: color, size: 26),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('notifications')
                      .where('toUserId', isEqualTo: _currentUser!.uid)
                      .where('isRead', isEqualTo: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final hasUnread = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
                    if (!hasUnread) return const SizedBox();

                    return Positioned(
                      right: -2,
                      top: 0,
                      child: Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: isDark ? const Color(0xFF1E1E1E) : Colors.white, width: 2)),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Bildirimler',
              style: TextStyle(color: color, fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}