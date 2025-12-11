import 'package:flutter/material.dart';
import '../models/order_model.dart';

class JobCardWidget extends StatelessWidget {
  final Order job;
  final Function(int)? onStatusUpdate;
  final VoidCallback? onDelete;
  final VoidCallback? onViewOrder;

  const JobCardWidget({
    super.key,
    required this.job,
    this.onStatusUpdate,
    this.onDelete,
    this.onViewOrder,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> statusOptions = [
      {'value': 1, 'label': 'Placed'},
      {'value': 2, 'label': 'Accepted'},
      {'value': 3, 'label': 'Processing / Packed'},
      {'value': 4, 'label': 'Dispatched'},
      {'value': 5, 'label': 'Out for Delivery'},
      {'value': 6, 'label': 'Delivered'},
    ];

    final currentStatus = statusOptions.firstWhere(
          (s) => s['label'].toLowerCase() == job.statusText.toLowerCase(),
      orElse: () => {'label': 'Placed', 'value': 1}, // Default to 'Placed' if not found
    );

    // 🟢 Get dynamic runner/partner name safely
    String runnerName = 'N/A';
    if (job.bussId.mId.isNotEmpty) {
      runnerName = job.bussId.mId.first.username;
    } else if (job.runnId.username.isNotEmpty) {
      runnerName = job.runnId.username;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Job ID: ${job.orderId}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  job.mode.isNotEmpty ? job.mode : 'Unknown Mode',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),

            /// USER DETAILS
            Text(
              'Customer: ${job.userId.username.isNotEmpty ? job.userId.username : 'N/A'}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            Text(
              'User ID: ${job.userId.id}',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),

            /// STATUS DROPDOWN
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 🟡 View Order
                ElevatedButton.icon(
                  onPressed: onViewOrder,
                  icon: const Icon(Icons.receipt_long, color: Colors.black),
                  label: const Text(
                    'View Order',
                    style: TextStyle(color: Colors.black),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: currentStatus['value'],
                      icon: const Icon(Icons.arrow_drop_down),
                      items: statusOptions.map((status) {
                        return DropdownMenuItem<int>(
                          value: status['value'],
                          child: Text(status['label']),
                        );
                      }).toList(),
                      onChanged: (int? newStatus) {
                        if (newStatus != null) {
                          onStatusUpdate?.call(newStatus);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            /// ACTION ROW
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [

                /// Buttons Row
                Row(
                  children: [
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.cancel, color: Colors.white),
                      label: const Text('Cancel',style: TextStyle(color: Colors.white),),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}