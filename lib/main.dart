import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'gen_l10n/app_localizations.dart';

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
  ThemeMode _themeMode = ThemeMode.light;

  void _changeLanguage(Locale newLocale) {
    setState(() {
      _locale = newLocale;
    });
  }

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
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
          themeMode: _themeMode,
          theme: ThemeData(
            brightness: Brightness.light,
            fontFamily: 'Montserrat',
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFD50032)),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                textStyle: const TextStyle(fontFamily: 'Montserrat'),
              ),
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            fontFamily: 'Montserrat',
            scaffoldBackgroundColor: const Color(0xFF181818),
            appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF222222)),
          ),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('ru'), Locale('kk')],
          debugShowCheckedModeBanner: false,
          initialRoute: '/',
          routes: {
            '/': (context) => SplashScreen(
                onLanguageChanged: _changeLanguage,
                onToggleTheme: _toggleTheme,
                themeMode: _themeMode),
            '/profile': (context) => ProfileScreen(
                onLanguageChanged: _changeLanguage,
                onToggleTheme: _toggleTheme,
                themeMode: _themeMode),
            '/home': (context) => HomePage(onToggleTheme: _toggleTheme, themeMode: _themeMode),
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
                return MaterialPageRoute(builder: (_) => DormDetailPage(dormId: id));
              }
            }
            return null;
          },
        );
      },
    );
  }
}
