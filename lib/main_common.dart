import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:wms/pages/unsupported_version.dart';
import 'package:wms/splashscreen_page.dart';
import 'firebase_options_prod.dart' as prod_options;
import 'firebase_options_dev.dart' as dev_options;
// import 'firebase_options_prod.dart' as prod_options;

import 'helper/endpoint.dart';
import 'pages/internet_checker.dart';
import 'routes/app_routes.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'package:wms/services/api_service.dart';
import 'package:wms/services/sap_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart'; 
 import 'package:package_info_plus/package_info_plus.dart';
// import 'package:printing/printing.dart';
//import 'splashscreen_page.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
enum Environment { dev, prod }

late final Environment appEnvironment;


// Future<void> checkVersion() async {
//   try {
//     final info = await PackageInfo.fromPlatform();
//     String currentVersion = info.version;

//     final response = await http.get(Uri.parse(apiVersionWMS));

//     if (response.statusCode != 200) 
//     {
//        Get.offAll(() => const UnsupportedVersionPage());
//     }

//     final data = jsonDecode(response.body);
//     String latestVersion = data['version']?? '0'; // contoh: "1.0.0+3"
//   print(latestVersion);
//   print(currentVersion);
//     if (currentVersion != latestVersion) {
//       Get.offAll(() => const UnsupportedVersionPage()); 
//     }
//   } catch (e) {
//     print("Version check error: $e");
//   }
// }

Future<void> mainCommon(Environment  env) async {
   appEnvironment = env;
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  // await Printing.init();
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform); 


  // await Firebase.initializeApp(
  // options: env == Environment.dev
  //     ? dev_options.DefaultFirebaseOptions.currentPlatform
  //     : prod_options.DefaultFirebaseOptions.currentPlatform,
//);
final firebaseOptions = env == Environment.dev
    ? dev_options.DefaultFirebaseOptions.currentPlatform
    : prod_options.DefaultFirebaseOptions.currentPlatform;

await Firebase.initializeApp(options: firebaseOptions);


 

  if (!kIsWeb && Platform.isAndroid) {
  WebViewPlatform.instance = AndroidWebViewPlatform();
}
  
  await initializeDateFormatting('id_ID', null);

  Get.put(ApiService(), permanent: true);
  Get.put(SAPService(), permanent: true);

  await _initializeNotifications();
  await _setupInteractedMessage();
  // await checkVersion(); 
  runApp(MyApp(env: env));
  //runApp(const MyApp());
}

class MyApp extends StatelessWidget {
   final Environment env;
  const MyApp({super.key, required this.env});
  // const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final box = GetStorage();
    final token = box.read('token');
    final expires = box.read('refreshTokenExpiryTime');

    if (token != null && expires != null) {
      final expire = DateTime.parse(expires);
      if (!DateTime.now().isBefore(expire.subtract(const Duration(seconds: 10)))) {
        Get.find<ApiService>().refreshToken();
      }
    }
  return   GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: (env==Environment.dev ? 'DEV WMS Apps' :'WMS Apps'),
      //  home: token != null ? HomePage() : LoginPage(),
        home:  SplashScreenPage(),
      builder: (context, child) {
        return InternetChecker(child: child!); // Ini menyisipkan pengecek internet ke seluruh app
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent, // Warna dasar untuk menghasilkan palet
          primary: Colors.blue[700],    // Warna primer utama
          secondary: Colors.lightBlue[400], // Warna sekunder
          tertiary: Colors.teal[400], // Warna ketiga (opsional)
          surface: Colors.white,       // Warna untuk permukaan widget (Card, dll.)
          onPrimary: Colors.white,     // Warna teks di atas primary
          onSurface: Colors.grey[800], // Warna teks di atas surface
          error: Colors.redAccent,     // Warna untuk pesan error
        ),
        useMaterial3: true, // AKTIFKAN MATERIAL 3 DESIGN
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue[700], // Warna AppBar
          foregroundColor: Colors.white,     // Warna teks dan ikon di AppBar
          elevation: 2, // Shadow di bawah AppBar
          centerTitle: true,
        ),  
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating, // Snackbar muncul di atas FAB
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          contentTextStyle: const TextStyle(color: Colors.white),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none, // Default tanpa border
          ),
          filled: true, // Selalu diisi
          fillColor: Colors.grey[100], // Warna fill default
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          // hintStyle: TextStyle(color: Colors.grey[500]),
        ),
        listTileTheme: ListTileThemeData(
          tileColor: Colors.white, // Warna latar belakang ListTile
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Sudut melengkung
        )
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
