import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/picklist_controller.dart';
//import 'package:qr_flutter/qr_flutter.dart';

class PickListPage extends StatelessWidget {
  final String session;
  final controller = Get.put(PickListController());

  PickListPage({super.key, required this.session}) {
    // controller.loadPickLists(session);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pick Lists')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          itemCount: controller.pickLists.length,
          itemBuilder: (context, index) {
            final pick = controller.pickLists[index];
            return ListTile(
              title: Text(pick.pickDate),
              subtitle: Text('Status: ${pick.pickDate}'),
              // trailing: QrImageView(data: pick.absoluteEntry.toString(), size: 60),
            );
          },
        );
      }),
    );
  }
}
