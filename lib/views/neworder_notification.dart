import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:slide_to_act/slide_to_act.dart'; // ✅ updated package
import '../../models/order_model.dart';

class OrderPopupScreen extends StatefulWidget {
  final Order order;
  final VoidCallback onAccept;
  final VoidCallback onMinimize;
  final VoidCallback onView;

  const OrderPopupScreen({
    super.key,
    required this.order,
    required this.onAccept,
    required this.onMinimize,
    required this.onView,
  });

  @override
  _OrderPopupScreenState createState() => _OrderPopupScreenState();
}

class _OrderPopupScreenState extends State<OrderPopupScreen> {
  bool _isAccepting = false;

  @override
  Widget build(BuildContext context) {
    final bool isActionDisabled = !['Place', 'new', 1].contains(widget.order.status);
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = (screenWidth * 0.04).clamp(14.0, 16.0);
    final iconSize = (screenWidth * 0.05).clamp(18.0, 22.0);
    final padding = (screenWidth * 0.02).clamp(8.0, 12.0);

    final GlobalKey<SlideActionState> _slideKey = GlobalKey();

    return Dialog(
      insetPadding: EdgeInsets.all(padding),
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(maxWidth: screenWidth * 0.9, minHeight: 300),
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'New Order Received',
                    style: TextStyle(
                      fontSize: fontSize * 1.2,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: iconSize),
                  onPressed: widget.onMinimize,
                ),
              ],
            ),
            SizedBox(height: padding),
            Text('Order ID: ${widget.order.orderId}',
                style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w500)),
            SizedBox(height: padding * 0.5),
            Text(widget.order.customerName.isNotEmpty
                ? widget.order.customerName
                : 'Unknown',
                style: TextStyle(fontSize: fontSize * 1.1, fontWeight: FontWeight.bold)),
            SizedBox(height: padding * 0.5),
            Text(
              widget.order.location.isNotEmpty
                  ? widget.order.location
                  : widget.order.location.isNotEmpty
                  ? widget.order.location
                  : 'No address',
              style: TextStyle(color: Colors.black54, fontSize: fontSize * 0.9),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: padding * 0.5),
            Text(
              widget.order.bookingDate.isNotEmpty
                  ? '${widget.order.bookingDate} at ${widget.order.bookingTime}'
                  : 'NA',
              style: TextStyle(
                fontSize: fontSize * 0.95,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: padding * 1.5),
            SizedBox(
              height: 55,
              child: _isAccepting || isActionDisabled
                  ? Container(
                decoration: BoxDecoration(
                  color: isActionDisabled ? Colors.grey.shade200 : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isActionDisabled ? Colors.grey : Colors.black87),
                ),
                child: Center(
                  child: Text(
                    isActionDisabled
                        ? 'Order is ${widget.order.status.toString().toLowerCase()}'
                        : 'Processing...',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: fontSize * 0.9,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              )
                  : SlideAction(
                key: _slideKey,
                text: 'Slide to Accept',
                textStyle: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: fontSize * 0.9,
                ),
                outerColor: Colors.white,
                innerColor: Colors.black87,
                elevation: 1,
                borderRadius: 12,
                sliderButtonIcon: Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: iconSize,
                ),
                onSubmit: () async {
                  HapticFeedback.mediumImpact();
                  setState(() => _isAccepting = true);
                  try {
                    EasyLoading.show(status: 'Accepting order...');
                    await Future.delayed(const Duration(milliseconds: 500));
                    widget.onAccept();
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to accept order: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() => _isAccepting = false);
                      EasyLoading.dismiss();
                      _slideKey.currentState?.reset(); // reset the slider
                    }
                  }
                },
              ),
            ),
            SizedBox(height: padding),
            Center(
              child: ElevatedButton(
                onPressed: widget.onView,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: padding * 2, vertical: padding),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: TextStyle(fontSize: fontSize),
                ),
                child: const Text('View'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
