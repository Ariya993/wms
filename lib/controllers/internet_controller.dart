import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../helper/endpoint.dart';

class InternetController extends GetxController {
  var isConnected = true.obs;

  late final Connectivity _connectivity;
  StreamSubscription? _subscription;

  @override
  void onInit() {
    super.onInit();
    _connectivity = Connectivity();
// _subscription = _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
//   if (results.isNotEmpty) {
//     _handleConnectivityChange(results.first);
//   }
// });

_subscription = _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) async {
  final hasInternet = await _checkConnection();
  isConnected.value = results.isNotEmpty && results.first != ConnectivityResult.none && hasInternet;
});

    // _subscription = _connectivity.onConnectivityChanged.listen((results) {
    //   if (results.isNotEmpty) {
    //     _handleConnectivityChange(results.first);
    //   }  
    // });

    _initialCheck();
  }

  Future<void> _initialCheck() async {
    final result = await _connectivity.checkConnectivity();
    final hasInternet = await _checkConnection();
    //print (hasInternet);
    isConnected.value = result != ConnectivityResult.none && hasInternet;
  }
 
//  void _handleConnectivityChange(ConnectivityResult result) {
//   isConnected.value = result != ConnectivityResult.none;
// }
  Future<void> _handleConnectivityChange(ConnectivityResult result) async {
  final hasInternet = await _checkConnection();
  isConnected.value = result != ConnectivityResult.none && hasInternet;
}
Future<bool> _checkConnection() async {
  try {
    final response = await http.get(
      Uri.parse(apiTestConn),
      headers: {"User-Agent": "Mozilla/5.0"},
    ).timeout(Duration(seconds: 10));

   // print("Status: ${response.statusCode}");
    return response.statusCode == 200;
  } catch (e) {
   // print("Error checking connection: $e");
    return false;
  }
}


  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
