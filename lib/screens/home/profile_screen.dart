import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import 'saved_events_screen.dart';

class ProfileScreen extends StatelessWidget {
  final UserModel currentUser;

  const ProfileScreen({super.key, required this.currentUser});

  String get _calculatedAge {
    if (currentUser.birthDate == null) return 'Belirtilmedi';
    final today = DateTime.now();
    int age = today.year - currentUser.birthDate!.year;
    if (today.month < currentUser.birthDate!.month ||
        (today.month == currentUser.birthDate!.month && today.day < currentUser.birthDate!.day)) {
      age--;
    }
    return age.toString();
  }

  Future<void> _signOut(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text('Hesabından çıkış yapmak istediğine emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, elevation: 0),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
            },
            child: const Text('Çıkış Yap', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = const Color(0xFF6A1221);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA);

    String initials = '';
    if (currentUser.fullName.isNotEmpty) {
      var nameParts = currentUser.fullName.split(' ');
      if (nameParts.length > 1) {
        initials = '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
      } else {
        initials = nameParts[0][0].toUpperCase();
      }
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280.0,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen(currentUser: currentUser))),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primaryColor.withValues(alpha: 0.8),
                          primaryColor.withValues(alpha: 0.4),
                          Colors.orange.withValues(alpha: 0.3)
                        ],
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
                        ),
                        child: Center(
                          child: Text(initials, style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: primaryColor)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(currentUser.fullName, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_on_outlined, color: Colors.white70, size: 16),
                          const SizedBox(width: 6),
                          const Text('Sivas, TR', style: TextStyle(fontSize: 15, color: Colors.white70, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Container(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem('Puan', '${currentUser.ratingAvg.toStringAsFixed(1)} ⭐', textColor, isDark),
                  _buildStatDivider(),
                  _buildStatItem('Katılım', '${currentUser.attendedCount}', textColor, isDark),
                  _buildStatDivider(),
                  _buildStatItem('Düzenlenen', '0', textColor, isDark),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HAKKIMDA BÖLÜMÜ
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Hakkımda', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textColor)),
                      TextButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen(currentUser: currentUser))),
                          child: Text('Düzenle', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold))
                      ),
                    ],
                  ),
                  Text('Seni en iyi ne temsil eder?', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: [
                      _buildInfoChip(Icons.school_outlined, currentUser.department.isNotEmpty ? currentUser.department : 'Bölüm Yok', isDark),
                      _buildInfoChip(Icons.menu_book_outlined, '${currentUser.grade}. Sınıf', isDark),
                      _buildInfoChip(Icons.cake_outlined, '$_calculatedAge Yaşında', isDark),
                      _buildInfoChip(Icons.person_outline, currentUser.gender, isDark),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade200)),
                    child: Text(
                      currentUser.bio.isNotEmpty ? currentUser.bio : 'Kısa bir biyografi ekleyerek kendini diğer öğrencilere tanıt.',
                      style: TextStyle(fontSize: 15, height: 1.5, fontStyle: currentUser.bio.isEmpty ? FontStyle.italic : FontStyle.normal, color: currentUser.bio.isEmpty ? Colors.grey : (isDark ? Colors.white70 : Colors.black87)),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // İLGİ ALANLARI
                  Row(
                    children: [
                      Text('Neler arıyorsun?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textColor)),
                      const SizedBox(width: 8),
                      const Icon(Icons.auto_awesome_rounded, color: Colors.amber, size: 20),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (currentUser.interests.isNotEmpty)
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: currentUser.interests.map((interest) => _buildInterestChip(interest, isDark)).toList(),
                    )
                  else
                    const Text('Henüz ilgi alanı eklenmedi.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),

                  const SizedBox(height: 40),

                  // MEETUP TARZI PROFİL KARTLARI (YENİ TASARIM)
                  Text('Hesap Yönetimi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textColor)),
                  const SizedBox(height: 16),

                  _buildMeetupStyleCard(
                    title: 'Kaydedilen Etkinlikler',
                    subtitle: 'Favoriye aldığın etkinlikleri incele',
                    icon: Icons.bookmark_rounded,
                    iconBgColor: const Color(0xFF8672D3), // Ekran görüntüsündeki tatlı mor
                    isDark: isDark,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SavedEventsScreen(currentUser: currentUser))),
                  ),

                  _buildMeetupStyleCard(
                    title: 'Ayarlar',
                    subtitle: 'Hesap tercihleri ve bildirimler',
                    icon: Icons.settings_rounded,
                    iconBgColor: const Color(0xFFD3A272), // Ekran görüntüsündeki tatlı sarı/turuncu
                    isDark: isDark,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                  ),

                  const SizedBox(height: 24),

                  // SADE ÇIKIŞ YAP METNİ
                  Center(
                    child: TextButton(
                      onPressed: () => _signOut(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text(
                        'Hesaptan Çıkış Yap',
                        style: TextStyle(color: Colors.redAccent, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // EKRAN GÖRÜNTÜSÜNDEKİ KART TASARIMININ BİREBİR AYNISI
  Widget _buildMeetupStyleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBgColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(20), // Ekran görüntüsündeki yuvarlaklık
            border: isDark ? Border.all(color: Colors.white12) : Border.all(color: Colors.grey.shade200),
            boxShadow: [
              if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
            ]
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(14), // İkon kutusu yuvarlaklığı
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      title,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)
                  ),
                  const SizedBox(height: 4),
                  Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w500)
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color textColor, bool isDark) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textColor)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(height: 30, width: 1, color: Colors.grey.shade300);
  }

  Widget _buildInfoChip(IconData icon, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isDark ? Colors.white70 : Colors.black54),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildInterestChip(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade300),
      ),
      child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
    );
  }
}