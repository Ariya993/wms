
import 'dart:typed_data';
import 'package:get/get.dart';
import 'printer_controller.dart';

class PrintQRController {
  final printerController = PrinterController();

  void printImageWeb(Uint8List imageBytes) {
    printerController.printQR(imageBytes);
  }
}
