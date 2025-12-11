import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:slide_to_act/slide_to_act.dart'; // ✅ correct package
import '../../models/order_model.dart';

class JobCardWidget extends StatefulWidget {
  final Order job;
  final VoidCallback? onAccept;

  const JobCardWidget({
    super.key,
    required this.job,
    required this.onAccept,
  });

  @override
  _JobCardWidgetState createState() => _JobCardWidgetState();
}

class _JobCardWidgetState extends State<JobCardWidget> {
  bool _isAccepting = false;

  @override
  Widget build(BuildContext context) {
    print('JobCardWidget: Building card for Order ID: ${widget.job.id}, Status: ${widget.job.status}');

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final fontSize = (screenWidth * 0.04).clamp(14.0, 16.0);
    final iconSize = (screenWidth * 0.05).clamp(18.0, 22.0);
    final padding = (screenWidth * 0.02).clamp(8.0, 12.0);

   return Card(
      margin: EdgeInsets.all(padding * 0.8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Important!
          children: [
            Text(
              widget.job.customerName.isNotEmpty ? widget.job.customerName : 'Unknown',
              style: TextStyle(
                fontSize: fontSize * 1.1,
                fontWeight: FontWeight.bold,
                overflow: TextOverflow.ellipsis,
              ),
              maxLines: 1,
            ),
            SizedBox(height: padding * 0.5),
            Text(
              widget.job.location.isNotEmpty ? widget.job.location : 'No location',
              style: TextStyle(
                fontSize: fontSize * 0.9,
                color: Colors.grey[600],
                overflow: TextOverflow.ellipsis,
              ),
              maxLines: 2,
            ),
            SizedBox(height: padding * 0.8),
            Text(
              widget.job.bookingDate.isNotEmpty
                  ? '${widget.job.bookingDate} at ${widget.job.bookingTime}'
                  : 'NA',
              style: TextStyle(
                fontSize: fontSize * 0.95,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: padding * 0.8), // replace Spacer()
            const Divider(),
            SizedBox(
              height: 55,
              child: _isAccepting
                  ? Center(
                child: CircularProgressIndicator(
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                  strokeWidth: isSmallScreen ? 3 : 4,
                ),
              )
                  : Builder(
                builder: (context) {
                  final GlobalKey<SlideActionState> _key = GlobalKey();
                  return SlideAction(
                    key: _key,
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
                      setState(() => _isAccepting = true);
                      EasyLoading.show(status: 'Accepting order...');
                      await Future.delayed(const Duration(milliseconds: 500));
                      widget.onAccept?.call();
                      if (mounted) {
                        setState(() => _isAccepting = false);
                        EasyLoading.dismiss();
                        _key.currentState?.reset();
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
