import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/apply_screen.dart';
import 'screens/test_page.dart';
import 'screens/notifications_screen.dart';
import 'screens/dorm_detail_page.dart';
import 'screens/admin/admin_main_screen.dart';
import 'screens/edit_application_screen.dart';

void main() {
  runApp(DormMateApp());
}

class DormMateApp extends StatefulWidget {
  @override
  State<DormMateApp> createState() => _DormMateAppState();
}

class _DormMateAppState extends State<DormMateApp> {
  Locale _locale = const Locale('ru'); // Или бери из SharedPreferences при старте

  void _changeLanguage(Locale newLocale) {
    setState(() {
      _locale = newLocale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          locale: _locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('ru'),
            Locale('kk'),
          ],
          debugShowCheckedModeBanner: false,
          initialRoute: '/',
          routes: {
            '/': (context) => SplashScreen(onLanguageChanged: _changeLanguage),
            '/profile': (context) => ProfileScreen(onLanguageChanged: _changeLanguage),
            // '/': (context) => SplashScreen(),
            '/home': (context) => HomePage(),
            '/login': (context) => const LoginScreen(),
            '/chat': (context) => StudentChatScreen(),
            '/apply': (context) => ApplyScreen(),
            '/edit-application': (context) => EditApplicationScreen(),
            '/testpage': (context) => TestPage(),
            '/notification': (context) => NotificationsScreen(
                  onOpenChat: () {
                    Navigator.pushNamed(context, '/chat');
                  },
                ),
            '/adminMain': (context) => const AdminMainScreen(),
          },
          onGenerateRoute: (settings) {
            if (settings.name?.startsWith('/dorm/') == true) {
              final idString = settings.name!.split('/').last;
              final id = int.tryParse(idString);
              if (id != null) {
                return MaterialPageRoute(
                  builder: (_) => DormDetailPage(dormId: id),
                );
              }
            }
            return null;
          },
        );
      },
    );
  }
}
