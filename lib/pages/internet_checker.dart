// lib/widgets/internet_checker.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/internet_controller.dart';

class InternetChecker extends StatelessWidget {
  final Widget child;

  InternetChecker({required this.child}) {
    Get.put(InternetController()); // Register controller
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = Get.find<InternetController>();

      if (controller.isConnected.isFalse) {
        return Scaffold(
  backgroundColor: Colors.white,
  body: Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, size: 120, color: Colors.blue),
          const SizedBox(height: 30),
          const Text(
            'Connection Refused',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Please check your connection and try again.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {
              Get.find<InternetController>().onInit();
            },
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(
                horizontal: 30,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    ),
  ),
);

      }
      return child;
    });
  }
}
