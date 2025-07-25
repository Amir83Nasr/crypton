import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:crypton_frontend/theme.dart';

import 'package:crypton_frontend/screens/splash.dart';
import 'package:crypton_frontend/screens/login.dart';
import 'package:crypton_frontend/screens/signup.dart';

import 'package:crypton_frontend/screens/admin/dashboard.dart';
import 'package:crypton_frontend/screens/admin/setting.dart';
import 'package:crypton_frontend/screens/admin/messages.dart';
import 'package:crypton_frontend/screens/admin/send_message.dart';

import 'package:crypton_frontend/screens/user/dashboard.dart';
import 'package:crypton_frontend/screens/user/buy.dart';
import 'package:crypton_frontend/screens/user/swap.dart';
import 'package:crypton_frontend/screens/user/setting.dart';
import 'package:crypton_frontend/screens/user/announcement.dart';
import 'package:crypton_frontend/screens/user/sell.dart';
import 'package:crypton_frontend/screens/user/assets.dart';
import 'package:crypton_frontend/screens/user/history.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await initThemeMode();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'Crypton',
          debugShowCheckedModeBanner: false,

          locale: const Locale('fa'),
          supportedLocales: const [Locale('fa')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          themeMode: themeMode,
          theme: lightTheme,
          darkTheme: darkTheme,

          home: const Splash(),
          routes: {
            '/splash': (context) => const Splash(),
            '/login': (context) => const Login(),
            '/signup': (context) => const Signup(),

            '/user/dashboard': (context) => const Dashboard(),
            '/user/buy': (context) => const Buy(),
            '/user/sell': (context) => const Sell(),
            '/user/swap': (context) => const Swap(),
            '/user/history': (context) => const History(),
            '/user/assets': (context) => const Assets(),
            '/user/setting': (context) => const Setting(),
            '/user/announcement': (context) => const Announcement(),

            '/admin/dashboard': (context) => const AdminDashboard(),
            '/admin/setting': (context) => const AdminSetting(),
            '/admin/messages': (context) => const AdminMessages(),
            '/admin/sendmessage': (context) => const AdminSendMessage(),
          },
        );
      },
    );
  }
}
