import 'dart:convert';
import 'dart:typed_data'; 
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:wms/helper/endpoint.dart'; 

class PrinterController extends GetxController {
  final bluetooth = BlueThermalPrinter.instance;
  final devices = <BluetoothDevice>[].obs;
  final selectedDevice = Rx<BluetoothDevice?>(null);
  final isConnected = false.obs;

  final box = GetStorage();
  final _selectedPrinterKey = 'selectedPrinterAddress';
 
  @override
  void onInit() {
    super.onInit();
    initPrinter();
  }

  /// 🔹 Print dari image Uint8List (biasanya dari preview API)
  Future<void> printImageFromBytes(Uint8List imageBytes) async {
    if (!isConnected.value) {
      Get.snackbar("Failed", "Printer not found",snackPosition: SnackPosition.TOP,snackStyle: SnackStyle.FLOATING,backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    try {
      final decoded = img.decodeImage(imageBytes);
      if (decoded == null) throw Exception("Gagal decode gambar");

      await bluetooth.printNewLine();
      await bluetooth.printImageBytes(img.encodeJpg(decoded));
      await bluetooth.printNewLine();
      await bluetooth.paperCut();
    } catch (e) {
      Get.snackbar("Print Error", "Gagal print gambar: $e",snackPosition: SnackPosition.TOP,snackStyle: SnackStyle.FLOATING,backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

 Future<Uint8List?> getBarcodeImageFromServer({
  required String itemCode,
  required String itemName,
  required int qty,
}) {
  final token = box.read('token');

  final url = "$apiBarcodeWMS?qty=$qty";
  final body = {
    "ItemCode": itemCode,
    "ItemName": itemName,
  };
  
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
          Get.snackbar("Error", "Failed get barcode: ${response.statusCode}",snackPosition: SnackPosition.TOP,snackStyle: SnackStyle.FLOATING,backgroundColor: Colors.redAccent, colorText: Colors.white);
          return null;
        }
      })
      .catchError((e, stacktrace) { 
        Get.snackbar("Error", "Exception barcode:\n$e",snackPosition: SnackPosition.TOP,snackStyle: SnackStyle.FLOATING,backgroundColor: Colors.redAccent, colorText: Colors.white);
        return null;
      });
}


Future<void> printBarcodeFromServer({
  required String itemCode,
  required String itemName,
  required int qty,
}) async {
  if (!isConnected.value) {
    Get.snackbar("Failed", "Printer not connected",snackPosition: SnackPosition.TOP,snackStyle: SnackStyle.FLOATING,backgroundColor: Colors.redAccent, colorText: Colors.white);
    return;
  }
  final token = box.read('token');
  try {
    final response = await http.post(
      Uri.parse("$apiBarcodeWMS?qty=$qty"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // optional if secured
      },
      body: jsonEncode({
        "itemCode": itemCode,
        "itemName": itemName,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Gagal ambil barcode: ${response.statusCode}");
    }

    final Uint8List imageBytes = response.bodyBytes;

    // Konversi PNG ke format bitmap printer
    final img.Image? image = img.decodeImage(imageBytes);
    if (image == null) throw Exception("Gagal decode image");

    await bluetooth.printNewLine();
    await bluetooth.printImageBytes(img.encodeJpg(image)); // atau encodeBmp(image)
    await bluetooth.printNewLine();
    await bluetooth.paperCut();

  } catch (e) {
    Get.snackbar("Print Error", "$e");
  }
}

  Future<void> initPrinter() async {
    try {
      bool connected = await bluetooth.isConnected ?? false;
      isConnected.value = connected;

      final bondedDevices = await bluetooth.getBondedDevices();
      devices.assignAll(bondedDevices);

      // Coba auto-select printer terakhir
      final savedAddress = box.read(_selectedPrinterKey);
      if (savedAddress != null) {
        final matchedDevice = bondedDevices.firstWhereOrNull(
          (d) => d.address == savedAddress,
        );
        if (matchedDevice != null) {
          selectedDevice.value = matchedDevice;
        }
      }
    } catch (e) {
      Get.snackbar("Printer Error", "Failed to initialize printer: $e",snackPosition: SnackPosition.TOP,snackStyle: SnackStyle.FLOATING,backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  Future<void> connect(BluetoothDevice device) async {
    try {
      await bluetooth.connect(device);
      selectedDevice.value = device;
      isConnected.value = true;
      box.write(_selectedPrinterKey, device.address); // Simpan alamat
      Get.snackbar("Printer", "Connected to ${device.name}",snackPosition: SnackPosition.TOP,snackStyle: SnackStyle.FLOATING,backgroundColor: Colors.redAccent, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Printer", "Failed to connect: $e",snackPosition: SnackPosition.TOP,snackStyle: SnackStyle.FLOATING,backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  Future<void> disconnect() async {
    try {
      await bluetooth.disconnect();
      isConnected.value = false;
      Get.snackbar("Printer", "Disconnected",snackPosition: SnackPosition.TOP,snackStyle: SnackStyle.FLOATING,backgroundColor: Colors.redAccent, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Printer", "Failed to disconnect: $e",snackPosition: SnackPosition.TOP,snackStyle: SnackStyle.FLOATING,backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  // Optional: Reset pilihan printer
  void clearSavedPrinter() {
    box.remove(_selectedPrinterKey);
    selectedDevice.value = null;
  }

  Future<void> printText(String text) async {
    if (isConnected.value) {
      try {
        await bluetooth.printNewLine();
        await bluetooth.printCustom(text, 1, 1);
        await bluetooth.printNewLine();
        await bluetooth.paperCut();
      } catch (e) {
        Get.snackbar("Printer", "Failed to print text: $e",snackPosition: SnackPosition.TOP,snackStyle: SnackStyle.FLOATING,backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    } else {
      Get.snackbar("Printer", "Not connected",snackPosition: SnackPosition.TOP,snackStyle: SnackStyle.FLOATING,backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  Future<void> printQRCode(String data) async {
    if (isConnected.value) {
      try {
        await bluetooth.printQRcode(data, 200, 200, 1);
        await bluetooth.printNewLine();
        await bluetooth.paperCut();
      } catch (e) {
        Get.snackbar("Printer", "Failed to print QR Code: $e",snackPosition: SnackPosition.TOP,snackStyle: SnackStyle.FLOATING,backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    } else {
      Get.snackbar("Printer", "Not connected",snackPosition: SnackPosition.TOP,snackStyle: SnackStyle.FLOATING,backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }
}
