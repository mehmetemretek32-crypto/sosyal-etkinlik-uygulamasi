import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Color _primaryColor = const Color(0xFF6A1221); // İMZA BORDO
  bool _notificationsEnabled = true;

  Future<void> _deleteAccount() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hesabı Sil', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text('Hesabınızı ve tüm verilerinizi kalıcı olarak silmek istediğinize emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, elevation: 0),
            onPressed: () async {
              // Firebase Auth üzerinden hesabı silme işlemi
              try {
                await FirebaseAuth.instance.currentUser?.delete();
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hata: Hesabınızı silmek için yakın zamanda giriş yapmış olmanız gerekir. Lütfen çıkış yapıp tekrar girin.')));
              }
            },
            child: const Text('Evet, Sil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: Text('Ayarlar', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: textColor, letterSpacing: -0.5)),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          // HESAP BÖLÜMÜ
          _buildSectionHeader('Hesap', isDark),
          _buildSettingsGroup(
            isDark: isDark,
            children: [
              _buildSettingsTile(
                icon: Icons.lock_outline_rounded,
                title: 'Şifre Değiştir',
                isDark: isDark,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Şifre sıfırlama bağlantısı e-postanıza gönderilecek.')));
                },
              ),
              _buildDivider(isDark),
              _buildSettingsTile(
                icon: Icons.security_rounded,
                title: 'Gizlilik ve Güvenlik',
                isDark: isDark,
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),

          // UYGULAMA BÖLÜMÜ
          _buildSectionHeader('Uygulama', isDark),
          _buildSettingsGroup(
            isDark: isDark,
            children: [
              _buildSettingsTile(
                icon: Icons.notifications_none_rounded,
                title: 'Bildirimler',
                isDark: isDark,
                trailing: Switch(
                  value: _notificationsEnabled,
                  activeColor: _primaryColor,
                  onChanged: (val) => setState(() => _notificationsEnabled = val),
                ),
                onTap: () => setState(() => _notificationsEnabled = !_notificationsEnabled),
              ),
              _buildDivider(isDark),
              _buildSettingsTile(
                icon: Icons.dark_mode_outlined,
                title: 'Karanlık Mod',
                subtitle: 'Sistem temasına göre ayarlanır',
                isDark: isDark,
                trailing: const Icon(Icons.phone_android_rounded, color: Colors.grey, size: 20),
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),

          // DESTEK BÖLÜMÜ
          _buildSectionHeader('Destek & Hakkında', isDark),
          _buildSettingsGroup(
            isDark: isDark,
            children: [
              _buildSettingsTile(
                icon: Icons.help_outline_rounded,
                title: 'Yardım Merkezi',
                isDark: isDark,
                onTap: () {},
              ),
              _buildDivider(isDark),
              _buildSettingsTile(
                icon: Icons.description_outlined,
                title: 'Kullanım Koşulları',
                isDark: isDark,
                onTap: () {},
              ),
              _buildDivider(isDark),
              _buildSettingsTile(
                icon: Icons.info_outline_rounded,
                title: 'Uygulama Sürümü',
                subtitle: 'v1.0.0 (Beta)',
                isDark: isDark,
                trailing: const SizedBox(), // Ok ikonunu gizle
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 40),

          // TEHLİKELİ BÖLGE
          _buildSettingsGroup(
            isDark: isDark,
            children: [
              _buildSettingsTile(
                icon: Icons.person_off_outlined,
                title: 'Hesabımı Sil',
                titleColor: Colors.red,
                iconColor: Colors.red,
                isDark: isDark,
                trailing: const SizedBox(),
                onTap: _deleteAccount,
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: _primaryColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup({required List<Widget> children, required bool isDark}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade200),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? titleColor,
    Color? iconColor,
    required bool isDark,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? (isDark ? Colors.white : Colors.black)).withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor ?? (isDark ? Colors.white : Colors.black87), size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: titleColor ?? (isDark ? Colors.white : Colors.black87),
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500))
          : null,
      trailing: trailing ?? Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 60,
      endIndent: 16,
      color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
    );
  }
}