import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/auth_service.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() =>
      _VerifyEmailScreenState();
}

class _VerifyEmailScreenState
    extends State<VerifyEmailScreen> {
  final AuthService _authService = AuthService();

  bool _isChecking = false;
  bool _isSending = false;

  Future<void> _checkVerification() async {
    setState(() {
      _isChecking = true;
    });

    try {
      final isVerified =
      await _authService.checkEmailVerified();

      if (!mounted) return;

      if (isVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'E-posta doğrulandı. Uygulamaya yönlendiriliyorsun.',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'E-posta henüz doğrulanmamış. Gelen kutunu ve Spam klasörünü kontrol et.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Doğrulama kontrol edilemedi: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _resendEmail() async {
    setState(() {
      _isSending = true;
    });

    try {
      final user = _authService.currentUser;

      if (user == null) {
        throw Exception(
          'Aktif kullanıcı bulunamadı. Tekrar giriş yap.',
        );
      }

      await user.reload();

      final refreshedUser = _authService.currentUser;

      if (refreshedUser == null) {
        throw Exception(
          'Oturum bulunamadı. Tekrar giriş yap.',
        );
      }

      if (refreshedUser.emailVerified) {
        await _checkVerification();
        return;
      }

      await refreshedUser.sendEmailVerification();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Doğrulama e-postası tekrar gönderildi.',
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      final message = e.code == 'too-many-requests'
          ? 'Çok sık e-posta istendi. Biraz bekleyip tekrar dene.'
          : (e.message ??
          'Doğrulama e-postası gönderilemedi.');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    // Oturum kapanınca main.dart giriş ekranını açar.
  }

  @override
  Widget build(BuildContext context) {
    final email = _authService.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('E-posta Doğrulama'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Çıkış yap',
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 80,
                  color: Colors.deepPurple,
                ),

                const SizedBox(height: 20),

                const Text(
                  'Öğrenci E-postanı Doğrula',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  '$email adresine bir doğrulama bağlantısı gönderdik. '
                      'Lütfen bağlantıya tıkladıktan sonra aşağıdaki butona bas.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 32),

                ElevatedButton.icon(
                  onPressed: _isChecking
                      ? null
                      : _checkVerification,
                  icon: const Icon(
                    Icons.check_circle_outline,
                  ),
                  label: Text(
                    _isChecking
                        ? 'Kontrol Ediliyor...'
                        : 'Doğruladım, Devam Et',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                OutlinedButton(
                  onPressed: _isSending
                      ? null
                      : _resendEmail,
                  child: Text(
                    _isSending
                        ? 'Gönderiliyor...'
                        : 'Doğrulama Mailini Tekrar Gönder',
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'Gelen kutunu ve Spam / Gereksiz klasörünü kontrol et.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}