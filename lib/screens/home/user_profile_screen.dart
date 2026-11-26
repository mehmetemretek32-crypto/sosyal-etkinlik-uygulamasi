import 'package:flutter/material.dart';
import '../../models/user_model.dart';

class UserProfileScreen extends StatelessWidget {
  final UserModel user;

  const UserProfileScreen({super.key, required this.user});

  String get _calculatedAge {
    if (user.birthDate == null) return 'Belirtilmedi';
    final today = DateTime.now();
    int age = today.year - user.birthDate!.year;
    if (today.month < user.birthDate!.month ||
        (today.month == user.birthDate!.month && today.day < user.birthDate!.day)) {
      age--;
    }
    return age.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = const Color(0xFF6A1221);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA);

    String initials = '';
    if (user.fullName.isNotEmpty) {
      var nameParts = user.fullName.split(' ');
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
          // ÜST KISIM (KAPAK VE PROFİL FOTOĞRAFI)
          SliverAppBar(
            expandedHeight: 280.0,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
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
                      Text(user.fullName, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
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

          // İSTATİSTİKLER (PUAN, KATILIM)
          SliverToBoxAdapter(
            child: Container(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem('Puan', '${user.ratingAvg.toStringAsFixed(1)} ⭐', textColor, isDark),
                  _buildStatDivider(),
                  _buildStatItem('Katılım', '${user.attendedCount}', textColor, isDark),
                  _buildStatDivider(),
                  _buildStatItem('Düzenlenen', '0', textColor, isDark),
                ],
              ),
            ),
          ),

          // KULLANICI BİLGİLERİ (BÖLÜM, YAŞ, HAKKINDA)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kullanıcı Hakkında', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textColor)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: [
                      _buildInfoChip(Icons.school_outlined, user.department.isNotEmpty ? user.department : 'Bölüm Yok', isDark),
                      _buildInfoChip(Icons.menu_book_outlined, '${user.grade}. Sınıf', isDark),
                      _buildInfoChip(Icons.cake_outlined, '$_calculatedAge Yaşında', isDark),
                      _buildInfoChip(Icons.person_outline, user.gender, isDark),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade200)),
                    child: Text(
                      user.bio.isNotEmpty ? user.bio : 'Bu kullanıcı henüz biyografi eklememiş.',
                      style: TextStyle(fontSize: 15, height: 1.5, fontStyle: user.bio.isEmpty ? FontStyle.italic : FontStyle.normal, color: user.bio.isEmpty ? Colors.grey : (isDark ? Colors.white70 : Colors.black87)),
                    ),
                  ),
                  const SizedBox(height: 32),

                  Text('İlgi Alanları', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textColor)),
                  const SizedBox(height: 16),
                  if (user.interests.isNotEmpty)
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: user.interests.map((interest) => _buildInterestChip(interest, isDark)).toList(),
                    )
                  else
                    const Text('Kullanıcı henüz ilgi alanı belirtmemiş.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),

      // ALTTAKİ SABİT MESAJ GÖNDER BUTONU
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sohbet altyapısı hazırlanıyor...')));
            },
            icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white),
            label: const Text('Mesaj Gönder', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
            style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0
            ),
          ),
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