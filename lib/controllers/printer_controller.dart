import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:niimbot_label_printer/niimbot_label_printer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:wms/helper/endpoint.dart';
import 'package:image/image.dart' as img;

class PrinterController extends GetxController {
  final niimbot = NiimbotLabelPrinter();
  WebViewController? webViewController;
  final box = GetStorage();
  final isConnected = false.obs;
  final devices = <BluetoothDevice>[].obs;
  final selectedDevice = Rx<BluetoothDevice?>(null);

  final TextEditingController widthController = TextEditingController(
    text: "5",
  ); // mm
  final TextEditingController heightController = TextEditingController(
    text: "3",
  ); // mm
  final TextEditingController dpiController = TextEditingController(
    text: "8",
  ); // pixel per mm
  @override
  void onInit() {
    super.onInit();
    scanPrinter();
    widthController.text = (box.read('label_width') ?? 5).toString();
    heightController.text = (box.read('label_height') ?? 3).toString();
  }

  Future<void> requestBluetoothPermissions() async {
    if (await Permission.bluetoothConnect.isDenied ||
        await Permission.bluetoothScan.isDenied ||
        await Permission.locationWhenInUse.isDenied) {
      await [
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.locationWhenInUse,
      ].request();
    }
  }

  Future<void> scanPrinter() async {
    await requestBluetoothPermissions();
    final isGranted = await niimbot.requestPermissionGrant();
    if (!isGranted) {
      Get.snackbar(
        "Permission",
        "Bluetooth permission denied",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final isEnabled = await niimbot.bluetoothIsEnabled();
    if (!isEnabled) {
      Get.snackbar(
        "Bluetooth",
        "Bluetooth is not enabled",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final foundDevices = await niimbot.getPairedDevices(); // ✅ gunakan ini
    if (foundDevices.isEmpty) {
      Get.snackbar(
        "Scan",
        "No printer found",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    }
    devices.assignAll(foundDevices);

    // final savedAddress = box.read('last_printer_address');
    // if (savedAddress != null && selectedDevice.value == null) {
    //   final matchedDevice = foundDevices.firstWhereOrNull(
    //     (d) => d.address == savedAddress,
    //   );

    //   if (matchedDevice != null) {
    //     debugPrint("Trying auto-reconnect to ${matchedDevice.name}");
    //     await connectPrinter(matchedDevice);
    //   }
    // }
  }

  Future<void> connectPrinter(BluetoothDevice device) async {
    final result = await niimbot.connect(device);
    final status = await niimbot.isConnected(); // <-- tambahkan ini
    isConnected.value = status;
    if (result) {
      isConnected.value = true;
      selectedDevice.value = device;
      Get.snackbar(
        "Printer",
        "Connected to ${device.name}",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        "Printer",
        "Failed to connect",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
    // final savedAddress = box.read('last_printer');
    // if (savedAddress != null) {
    //   final matchingDevice = devices.firstWhereOrNull(
    //     (d) => d.address == savedAddress,
    //   );
    //   if (matchingDevice != null) {
    //     final result = await niimbot.connect(matchingDevice);
    //     if (result) {
    //       isConnected.value = true;
    //       selectedDevice.value = matchingDevice;
    //       Get.snackbar(
    //         "Printer",
    //         "Reconnected to ${matchingDevice.name}",
    //         backgroundColor: Colors.green,
    //         colorText: Colors.white,
    //       );
    //     } else {
    //       isConnected.value = false;
    //       selectedDevice.value = null;
    //       box.write('last_printer_address', null);
    //       Get.snackbar(
    //         "Printer",
    //         "Failed to connect",
    //         backgroundColor: Colors.red,
    //         colorText: Colors.white,
    //       );
    //     }
    //   }
    // } else {
    //   final result = await niimbot.connect(device);
    //   final status = await niimbot.isConnected(); // <-- tambahkan ini
    //   if (result && status) {
    //     isConnected.value = true;
    //     selectedDevice.value = device;
    //     box.write('last_printer_address', device.address);
    //     Get.snackbar(
    //       "Printer",
    //       "Connected to ${device.name}",
    //       backgroundColor: Colors.green,
    //       colorText: Colors.white,
    //     );
    //   } else {
    //     isConnected.value = false;
    //     selectedDevice.value = null;
    //     box.write('last_printer_address', null);
    //     Get.snackbar(
    //       "Printer",
    //       "Failed to connect",
    //       backgroundColor: Colors.red,
    //       colorText: Colors.white,
    //     );
    //   }
    // }
  }

  Future<void> disconnectPrinter() async {
    await niimbot.disconnect();
    isConnected.value = false;
    selectedDevice.value = null;
  }

  Future<Uint8List?> getBarcodeImageFromServer({
    required String itemCode,
    required String itemName,
    required int qty,
    double cmWidth = 5,
    double cmHeight = 3,
  }) {
    final token = box.read('token');
    box.write('label_width', cmWidth);
    box.write('label_height', cmHeight);
    final url = "$apiBarcodeWMS?qty=$qty&cm_width=$cmWidth&cm_height=$cmHeight";
    final body = {"itemCode": itemCode, "itemName": itemName};

    return http
        .post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        )
        .then((response) {
          if (response.statusCode == 200) {
            return response.bodyBytes; // Langsung kembalikan bytes
          } else {
            Get.snackbar(
              "Error",
              "Failed get barcode: ${response.statusCode}",
              snackPosition: SnackPosition.TOP,
              snackStyle: SnackStyle.FLOATING,
              backgroundColor: Colors.redAccent,
              colorText: Colors.white,
            );
            return null;
          }
        })
        .catchError((e, stacktrace) {
          print("ERROR getBarcodeImageFromServer: $e");
          print("STACKTRACE: $stacktrace");
          Get.snackbar(
            "Error",
            "Exception barcode:\n$e",
            snackPosition: SnackPosition.TOP,
            snackStyle: SnackStyle.FLOATING,
            backgroundColor: Colors.redAccent,
            colorText: Colors.white,
          );
          return null;
        });
  }

  Future<String?> getBarcodeHtmlFromServer({
    required String itemCode,
    required String itemName,
    required int qty,
    double cmWidth = 5,
    double cmHeight = 3,
  }) {
    final token = box.read('token');

    final url =
        "$apiBarcodeWMS/QRHtml?qty=$qty&cm_width=$cmWidth&cm_height=$cmHeight";

    final body = {"ItemCode": itemCode, "ItemName": itemName};

    return http
        .post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        )
        .then((response) {
          if (response.statusCode == 200) {
            return response.body; // HTML string
          } else {
            Get.snackbar(
              "Error",
              "Failed get HTML barcode: ${response.statusCode}",
              snackPosition: SnackPosition.TOP,
              snackStyle: SnackStyle.FLOATING,
              backgroundColor: Colors.redAccent,
              colorText: Colors.white,
            );
            return null;
          }
        })
        .catchError((e) {
          Get.snackbar(
            "Error",
            "Exception barcode:\n$e",
            snackPosition: SnackPosition.TOP,
            snackStyle: SnackStyle.FLOATING,
            backgroundColor: Colors.redAccent,
            colorText: Colors.white,
          );
          return null;
        });
  }

  Future<ui.Image> decodeToUiImage(Uint8List bytes) {
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(bytes, (ui.Image img) {
      completer.complete(img);
    });
    return completer.future;
  }

  void printImage(Uint8List html) async {
    try {
      final isConnected = await niimbot.isConnected();
      if (!isConnected) {
        Get.snackbar(
          "Printer",
          "Not connected",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        //return;
      }

      final Completer<ui.Image> completer = Completer();
      ui.decodeImageFromList(html, (ui.Image img) {
        completer.complete(img);
      });
      final ui.Image image = await completer.future;

      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      final List<int> bytesImage = byteData!.buffer.asUint8List().toList();
      print(image.height);
      print('----------------');
      print(image.width);

      final printData = PrintData.fromMap({
        "bytes": bytesImage,
        "width": image.width,
        "height": image.height,
        "rotate": false,
        "invertColor": false,
        "density": 3,
        "labelType": 1,
      });
      final result = await niimbot.send(printData);
      if (result) {
        Get.snackbar(
          "Printer",
          "Printed successfully",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          "Printer",
          "Print failed",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        "Print Error",
        '$e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void printQR(Uint8List imageBytes) async {
    try {
      final isConnected = await niimbot.isConnected();
      if (!isConnected) {
        Get.snackbar(
          "Printer",
          "Not connected",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        //return;
      }


      
      await Future.delayed(Duration(milliseconds: 500));
      final double widthCm = 5; // misalnya
      final double heightCm = 3;
      final double dpi = 8 * 10; // 8 pixel per mm = 80 per cm

      final int width = (widthCm * dpi).toInt();
      final int height = (heightCm * dpi).toInt();

      final Completer<ui.Image> completer = Completer();
      ui.decodeImageFromList(imageBytes, (ui.Image img) {
        completer.complete(img);
      });
      final ui.Image image = await completer.future;
      //final ui.Image image = await decodeToUiImage(imageBytes);

      final ByteData? byteData = await image.toByteData();
      //final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      final List<int> bytesImage = byteData!.buffer.asUint8List().toList();

      print("Image Width: ${image.width}, Height: ${image.height}");
      final printData = PrintData.fromMap({
        "bytes": bytesImage, // atau rgba
        "width": image.width,
        "height": image.height,
        "rotate": false,
        "invertColor": false,
        "density": 3,
        "labelType": 1,
      });
      final result = await niimbot.send(printData);
      if (result) {
        Get.snackbar(
          "Printer",
          "Printed successfully",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          "Printer",
          "Print failed",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        "Print Error",
        '$e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
