import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/picklist_controller.dart';
import '../widgets/statusbadge.dart';
import 'picklist_detail_page.dart';

class PicklistsPage extends StatelessWidget {
  const PicklistsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final PicklistController controller = Get.put(PicklistController());
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    String _formatPickDate(String? rawDate) {
      if (rawDate == null || rawDate.isEmpty) return '-';
      try {
        final parsedDate = DateTime.parse(rawDate);
        return DateFormat('dd-MMM-yyyy').format(parsedDate);
      } catch (_) {
        return '-';
      }
    }

    // Hitung total released & closed
    // int totalReleased =
    //     controller.displayedPicklists.where((p) => p['Status'] == 'R').length;
    // int totalClosed =
    //     controller.displayedPicklists.where((p) => p['Status'] == 'C').length;

    // int totalReleased = controller.allPicklists
    //     .where((p) => p['Status']?.toString().toUpperCase() == 'R')
    //     .length;

    // int totalClosed = controller.allPicklists
    //     .where((p) => p['Status']?.toString().toUpperCase() == 'C')
    //     .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick List Manager'),
        actions: [
          Obx(
            () => PopupMenuButton<String>(
              initialValue: controller.selectedStatusFilter.value,
              onSelected: (String result) {
                controller.changeStatusFilter(result);
              },
              itemBuilder:
                  (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'R',
                      child: Text('Released (Open)'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'C',
                      child: Text('Closed'),
                    ),
                  ],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Icon(Icons.filter_list, color: colorScheme.onPrimary),
                    const SizedBox(width: 6),
                    Text(
                      controller.selectedStatusFilter.value == 'R'
                          ? 'Released'
                          : 'Closed',
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_drop_down, color: colorScheme.onPrimary),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: colorScheme.onPrimary),
            tooltip: 'Refresh Picklists',
            onPressed: () => controller.fetchPickList(),
          ),
        ],
        elevation: 2,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularLoadingIndicator());
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: colorScheme.error, size: 56),
                  const SizedBox(height: 20),
                  Text(
                    controller.errorMessage.value,
                    style: TextStyle(color: colorScheme.error, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => controller.fetchPickList(),
                    icon: const Icon(Icons.replay),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 3,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (controller.displayedPicklists.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, color: Colors.grey[400], size: 80),
                const SizedBox(height: 24),
                Text(
                  'No picklists found for ${controller.selectedStatusFilter.value == 'R' ? 'Released' : 'Closed'} status.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Card summary total released & closed
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            //   child: Row(
            //     children: [
            //       Expanded(
            //         child: GestureDetector(
            //           onTap: () {
            //             controller.changeStatusFilter('R');

            //           },
            //           child: AnimatedStatusSummaryCard(
            //             status: 'Released',
            //             total: totalReleased,
            //             startColor: Colors.blue.shade600,
            //             endColor: Colors.blue.shade400,
            //             icon: Icons.check_circle_outline,
            //           ),
            //         ),
            //       ),
            //       const SizedBox(width: 12),
            //       Expanded(
            //         child: GestureDetector(
            //           onTap: () {
            //              controller.changeStatusFilter('C');

            //           },
            //           child: AnimatedStatusSummaryCard(
            //             status: 'Closed',
            //             total: totalClosed,
            //             startColor: Colors.red.shade600,
            //             endColor: Colors.red.shade400,
            //             icon: Icons.lock_outline,
            //           ),
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: controller.displayedPicklists.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final picklist = controller.displayedPicklists[index];
                  final bool isViewOnly = picklist['Status'] == 'C';

                  return Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color:
                            isViewOnly
                                ? colorScheme.error
                                : colorScheme.primary,
                        width: 1.2,
                      ),
                    ),
                    elevation: 0,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        controller
                            .currentProcessingPicklist
                            .value = Map<String, dynamic>.from(picklist);
                        Get.to(
                          () => PicklistDetailPage(isViewOnly: isViewOnly),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isViewOnly
                                  ? Icons.lock_outline
                                  : Icons.playlist_add_check,
                              color:
                                  isViewOnly
                                      ? colorScheme.error
                                      : colorScheme.primary,
                              size: 30,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    picklist['Name'] ?? 'No Name',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  // Text(
                                  //   'ID: ${picklist['Absoluteentry']} - Items: ${(picklist['DocumentLine'] as List).length}',
                                  //   style: TextStyle(
                                  //     color: Colors.grey[700],
                                  //     fontSize: 14,
                                  //   ),
                                  // ),
                                  Text(
                                    'Total Items: ${(picklist['DocumentLine'] as List).length}',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Pick Date: ${_formatPickDate(picklist['PickDate'])}',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Remarks: ${picklist['Remarks'] ?? '-'}',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            StatusBadge(
                              text: isViewOnly ? 'Closed' : 'Released',
                              backgroundColor:
                                  isViewOnly
                                      ? Colors.red.shade100
                                      : Colors.blue.shade100,
                              textColor:
                                  isViewOnly
                                      ? Colors.red.shade600
                                      : Colors.blue.shade600,
                              icon:
                                  isViewOnly
                                      ? Icons.lock_outline
                                      : Icons.check_circle_outline,
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 18,
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildStatusSummaryCard(String status, int total, Color color) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(14),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Column(
          children: [
            Text(
              '$total',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              status,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 16,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CircularLoadingIndicator extends StatelessWidget {
  const CircularLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: colorScheme.primary, strokeWidth: 3),
        const SizedBox(height: 18),
        Text(
          'Loading Picklists...',
          style: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.8),
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class AnimatedStatusSummaryCard extends StatefulWidget {
  final String status;
  final int total;
  final Color startColor;
  final Color endColor;
  final IconData icon;

  const AnimatedStatusSummaryCard({
    super.key,
    required this.status,
    required this.total,
    required this.startColor,
    required this.endColor,
    required this.icon,
  });

  @override
  State<AnimatedStatusSummaryCard> createState() =>
      _AnimatedStatusSummaryCardState();
}

class _AnimatedStatusSummaryCardState extends State<AnimatedStatusSummaryCard>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    setState(() => _scale = 0.95);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _scale = 1.0);
  }

  void _onTapCancel() {
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [widget.startColor, widget.endColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.endColor.withOpacity(0.5),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: Colors.white, size: 32),
              const SizedBox(width: 14),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${widget.total}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
