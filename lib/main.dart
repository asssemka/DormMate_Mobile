import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

void main() {
  runApp(DormMateApp());
}

class DormMateApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          initialRoute: '/',
          routes: {
            '/': (context) => SplashScreen(),
            '/home': (context) => HomePage(),
            '/login': (context) => const LoginScreen(),
            '/profile': (context) => ProfileScreen(),
            '/chat': (context) => StudentChatScreen(),
            '/apply': (context) => ApplyScreen(),
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
