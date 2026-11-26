import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_fonts/google_fonts.dart';

import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/verify_email_screen.dart';
import 'screens/home/main_nav_screen.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('Arka planda bildirim geldi: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('1 - Uygulama başlatılıyor...');

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('2 - Firebase başarıyla başlatıldı.');
  } catch (e, stackTrace) {
    debugPrint('FIREBASE HATASI: $e');
    debugPrint('$stackTrace');
    rethrow;
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  try {
    await NotificationService().initialize();
    debugPrint('3 - Bildirim servisi başlatıldı.');
  } catch (e, stackTrace) {
    debugPrint('BİLDİRİM HATASI: $e');
    debugPrint('$stackTrace');
  }

  debugPrint('4 - Arayüz yükleniyor.');
  runApp(const DorduncuApp());
}

class DorduncuApp extends StatelessWidget {
  const DorduncuApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color logoBordo = Color(0xFF6A1221);
    const Color logoBordoLight = Color(0xFFE27C8E);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'dördünCü',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,

          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          supportedLocales: const [
            Locale('tr', 'TR'),
          ],

          locale: const Locale('tr', 'TR'),

          // AYDINLIK TEMA (FONT HATASI ÇÖZÜLDÜ)
          theme: ThemeData(
            brightness: Brightness.light,
            fontFamily: GoogleFonts.urbanist().fontFamily, // EN TEMİZ FONT KULLANIMI
            colorScheme: ColorScheme.fromSeed(
              seedColor: logoBordo,
              primary: logoBordo,
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: Colors.grey.shade50,
            appBarTheme: const AppBarTheme(
              backgroundColor: logoBordo,
              foregroundColor: Colors.white,
              centerTitle: true,
              elevation: 0,
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              selectedItemColor: logoBordo,
              unselectedItemColor: Colors.black54,
            ),
          ),

          // KARANLIK TEMA (FONT HATASI ÇÖZÜLDÜ)
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            fontFamily: GoogleFonts.urbanist().fontFamily, // EN TEMİZ FONT KULLANIMI
            colorScheme: ColorScheme.fromSeed(
              seedColor: logoBordo,
              primary: logoBordoLight,
              brightness: Brightness.dark,
              surface: const Color(0xFF241E1F),
            ),
            scaffoldBackgroundColor: const Color(0xFF181415),
            cardColor: const Color(0xFF241E1F),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF181415),
              foregroundColor: Colors.white,
              centerTitle: true,
              elevation: 0,
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Color(0xFF241E1F),
              selectedItemColor: logoBordoLight,
              unselectedItemColor: Colors.white54,
            ),
            inputDecorationTheme: InputDecorationTheme(
              fillColor: const Color(0xFF2A2324),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          home: const SplashScreen(),
        );
      },
    );
  }
}

// OTURUM KONTROL MANTIĞI
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError) {
          debugPrint('Giriş kontrolü hatası: ${snapshot.error}');
          return const Scaffold(
            body: Center(child: Text('Oturum kontrol edilirken bir hata oluştu.', textAlign: TextAlign.center)),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          return const LoginScreen();
        }

        if (!user.emailVerified) {
          return const VerifyEmailScreen();
        }

        return const MainNavScreen();
      },
    );
  }
}