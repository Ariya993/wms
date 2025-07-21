//print_qr_controller.dart
export 'print_qr_controller_stub.dart'
  if (dart.library.html) 'print_qr_web_controller.dart'
  if (dart.library.io) 'print_qr_mobile_controller.dart';