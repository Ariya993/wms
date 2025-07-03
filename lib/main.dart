import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'routes/app_routes.dart';
// import 'pages/login_page.dart';
// import 'pages/home_page.dart';
import 'package:wms/services/api_service.dart';
import 'package:wms/services/sap_service.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'splashscreen_page.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('id_ID', null);

  Get.put(ApiService(), permanent: true);
  Get.put(SAPService(), permanent: true);

  await _initializeNotifications();
  await _setupInteractedMessage();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    //final box = GetStorage();
    // final token = box.read('token');
    // final expires = box.read('refreshTokenExpiryTime');

    // if (token != null && expires != null) {
    //   final expire = DateTime.parse(expires);
    //   if (!DateTime.now().isBefore(expire.subtract(const Duration(seconds: 10)))) {
    //     Get.find<ApiService>().refreshToken();
    //   }
    // }

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WMS App',
      // home: token != null ? HomePage() : LoginPage(),
       home: const SplashScreenPage(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue.shade700),
        useMaterial3: true,
      ),
      getPages: AppRoutes.routes,
    );
  }
}


Future<void> _initializeNotifications() async {
  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission();

  const initAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: initAndroid);

 await flutterLocalNotificationsPlugin.initialize(
  initSettings,
  onDidReceiveNotificationResponse: (NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      Get.toNamed(payload);
    }
  },
);


  FirebaseMessaging.onMessage.listen((message) => _showNotification(message));
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
}

Future<void> _setupInteractedMessage() async {
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) _handleMessageNavigation(initialMessage);
  FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageNavigation);
}

void _handleMessageNavigation(RemoteMessage message) {
  final target = message.data['target'];
  if (target != null && target.isNotEmpty) {
    Get.toNamed(target);
  }
}

Future<void> _showNotification(RemoteMessage message) async {
  if (kIsWeb) return;
  const androidDetails = AndroidNotificationDetails(
    'SANYMP_WMS_ID', 'WMS Apps',
    importance: Importance.high,
    priority: Priority.high,
  );
  const notifDetails = NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    0,
    message.notification?.title ?? message.data['title'],
    message.notification?.body ?? message.data['body'],
    notifDetails,
    payload: message.data['target'],
  );
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await _showNotification(message);
}
