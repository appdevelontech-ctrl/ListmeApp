import 'package:flutter/material.dart';
import '../models/order_model.dart';
import 'BlinkingButton.dart';

class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onViewOrder;
  final VoidCallback onTrackOrder;
  final VoidCallback onDelete;
  final Function(int)? onStatusChange;

  const OrderCard({
    super.key,
    required this.order,
    required this.onViewOrder,
    required this.onTrackOrder,
    required this.onDelete,
    this.onStatusChange,
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
          (s) => s['label'].toLowerCase() == order.statusText.toLowerCase(),
      orElse: () => {'label': 'Placed', 'value': 1},
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order ID: ${order.orderId}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  order.mode.isNotEmpty ? order.mode : 'Unknown Mode',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Customer: ${order.userId.username.isNotEmpty ? order.userId.username : 'N/A'}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            Text(
              'User ID: ${order.userId.id}',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
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
                      onChanged: (int? newValue) {
                        if (newValue != null) {
                          onStatusChange?.call(newValue);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                BlinkingButton(
                  label: 'Track Order',
                  icon: Icons.location_on,
                  color: Colors.blueAccent,
                  onPressed: onTrackOrder,
                ),

                ElevatedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.cancel, color: Colors.white),
                  label: const Text('Cancel',style: TextStyle(color: Colors.white),),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}