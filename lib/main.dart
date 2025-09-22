import 'dart:io';
//import 'package:flutter/rendering.dart' show debugPaintSizeEnabled;
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lost_and_found_kiosk/services/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';

import 'dashboard/home_page.dart';
import 'dashboard/found_page.dart';
import 'dashboard/lost_page.dart';
import 'dashboard/notifications_page.dart';
import 'dashboard/claimed_page.dart';
import 'services/splash_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    if (await _isAndroid13orAbove()) {
      await Permission.notification.request();
    }
  } else if (Platform.isIOS) {
    // iOS-specific notification permission request
    final iosPermission = await Permission.notification.request();
    if (iosPermission.isDenied) {
      print("iOS notification permission denied");
    }
  }

  await NotificationService.init();
  runApp(const MyApp());
}

Future<bool> _isAndroid13orAbove() async {
  final androidInfo = await DeviceInfoPlugin().androidInfo;
  return androidInfo.version.sdkInt >= 33;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lost & Found',
      theme: ThemeData(primarySwatch: Colors.deepOrange, fontFamily: 'Nexa'),
      home: const SplashScreen(),
      routes: {
        '/home': (context) => const HomePage(),
        '/found': (context) => const FoundPage(),
        '/lost': (context) => const LostPage(),
        '/notifications': (context) => const NotificationsPage(),
        '/claimed': (context) => const ClaimedPage(),
      },
    );
  }
}
