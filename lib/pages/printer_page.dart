import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/printer_controller.dart';

class SelectPrinterPage extends StatelessWidget {
  final PrinterController printerController = Get.put(PrinterController());

  SelectPrinterPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Panggil scanPrinter hanya sekali saat halaman dibuka
    Future.delayed(Duration.zero, () {
      printerController.scanPrinter();
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Select Bluetooth Printer')),
      body: Obx(() {
        final devices = printerController.devices;

        if (devices.isEmpty) {
          return const Center(child: Text('No Bluetooth devices found.'));
        }

        return ListView.separated(
          itemCount: devices.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final device = devices[index];
            final isSelected =
                printerController.selectedDevice.value?.address == device.address;

            return ListTile(
              title: Text(device.name ?? 'Unknown'),
              subtitle: Text(device.address ?? 'No address'),
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
              onTap: () async {
                await printerController.connectPrinter(device); // ✅ konek printer
              },
            );
          },
        );
      }),
      bottomNavigationBar: Obx(() {
        final isConnected = printerController.isConnected.value;
        final device = printerController.selectedDevice.value;

        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (device != null)
                Text(
                  isConnected
                      ? 'Connected to ${device.name}'
                      : 'Selected: ${device.name}, not connected',
                  style: TextStyle(
                    color: isConnected ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (isConnected)
                ElevatedButton.icon(
                  onPressed: () async {
                    await printerController.disconnectPrinter(); // ✅ disconnect
                  },
                  icon: const Icon(Icons.cancel),
                  label: const Text('Disconnect'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
            ],
          ),
        );
      }),
    );
  }
}
