import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'gen_l10n/app_localizations.dart';

import 'app_settings.dart';

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
import 'providers/chat_provider.dart';
import 'screens/dorm_group_chats_screen.dart';
import 'providers/student_provider.dart'; // ← добавь в блок import-ов

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppSettings()),
        ChangeNotifierProvider(create: (_) => StudentProvider()), // ⭐ новый
        ChangeNotifierProvider(create: (_) => ChatProvider()), // был
      ],
      child: const DormMateApp(),
    ),
  );
}

class DormMateApp extends StatelessWidget {
  const DormMateApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppSettings>(
      builder: (context, settings, _) {
        return ScreenUtilInit(
          designSize: const Size(390, 844),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) {
            return MaterialApp(
              locale: settings.locale,
              themeMode: settings.themeMode,
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
                      onLanguageChanged: (locale) => context.read<AppSettings>().setLocale(locale),
                      onToggleTheme: () => context.read<AppSettings>().toggleTheme(),
                      themeMode: context.watch<AppSettings>().themeMode,
                    ),
                '/profile': (context) => ProfileScreen(
                      onLanguageChanged: (locale) => context.read<AppSettings>().setLocale(locale),
                      onToggleTheme: () => context.read<AppSettings>().toggleTheme(),
                      themeMode: context.watch<AppSettings>().themeMode,
                    ),
                '/home': (context) => HomePage(
                      onToggleTheme: () => context.read<AppSettings>().toggleTheme(),
                      themeMode: context.watch<AppSettings>().themeMode,
                    ),
                '/login': (context) => const LoginScreen(),
                '/chat': (context) => StudentChatScreen(),
                '/dorm_chats': (context) => DormGroupChatsScreen(),
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
      },
    );
  }
}
