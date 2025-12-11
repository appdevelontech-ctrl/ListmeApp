import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/order_controller.dart';
import '../models/order_model.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _pincodeController;
  late TextEditingController _totalAmountController;
  int _selectedStatus = 0;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _addressController = TextEditingController();
    _pincodeController = TextEditingController();
    _totalAmountController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderController>(context, listen: false)
          .fetchOrderById(widget.orderId)
          .then((_) {
        final order = Provider.of<OrderController>(context, listen: false)
            .allOrders
            .firstWhere(
              (o) => o.id == widget.orderId,
          orElse: () => Order(
            id: '',
            items: [],
            mode: '',
            details: [],
            discount: '0',
            shipping: '0',
            totalAmount: 0,
            userId: UserId(id: '', username: ''),
            primary: 'false',
            payment: 0,
            status: 0,
            leadStatus: 0,
            orderId: 0,
            category: [],
            type: 0,
            bussId: BussId(id: '', username: '', mId: []),
            sellId: SellId(id: '', username: '', latitude: '', longitude: ''),
            wareId: WareId(id: '', username: ''),
            longitude: '',
            latitude: '',
            razorpayOrderId: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            v: 0,
            razorpayPaymentId: '',
            razorpaySignature: '',
            runnId: RunnId(id: '', username: ''),
          ),
        );

        if (order.id.isNotEmpty) {
          final detail = order.details.isNotEmpty ? order.details.first : null;
          _nameController.text = order.customerName;
          _phoneController.text = detail?.phone ?? '';
          _emailController.text = detail?.email ?? '';
          _addressController.text = order.location;
          _pincodeController.text = detail?.pincode ?? '';
          _totalAmountController.text = order.totalAmount.toString();
          _selectedStatus = order.status;
        }
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    _totalAmountController.dispose();
    super.dispose();
  }

  void _updateOrder() async {
    final controller = Provider.of<OrderController>(context, listen: false);
    final order = controller.allOrders.firstWhere((o) => o.id == widget.orderId);

    // Basic validation
    if (_phoneController.text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number must be 10 digits')),
      );
      return;
    }
    if (!_emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid email address')),
      );
      return;
    }
    if (int.tryParse(_totalAmountController.text) == null || int.parse(_totalAmountController.text) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Total amount must be a positive number')),
      );
      return;
    }

    final updatedOrderData = {
      '_id': order.id,
      'items': order.items.map((item) => {
        'id': item.id,
        'title': item.title,
        'image': item.image,
        'regularPrice': item.regularPrice,
        'price': item.price,
        'color': item.color,
        'customise': item.customise,
        'TotalQuantity': item.totalQuantity,
        'stock': item.stock,
        'pid': item.pid,
        'userId': item.userId,
        'quantity': item.quantity,
      }).toList(),
      'mode': order.mode,
      'details': [
        {
          'username': _nameController.text,
          'phone': _phoneController.text,
          'pincode': _pincodeController.text,
          'state': order.details.isNotEmpty ? order.details.first.state : 'Delhi',
          'address': _addressController.text,
          'email': _emailController.text,
        }
      ],
      'discount': order.discount,
      'shipping': order.shipping,
      'totalAmount': int.parse(_totalAmountController.text),
      'userId': order.userId.id,
      'primary': order.primary,
      'payment': order.payment,
      'status': _selectedStatus,
      'leadStatus': order.leadStatus,
      'orderId': order.orderId,
      'category': order.category,
      'type': order.type,
      'bussId': order.bussId.id,
      'sellId': {
        '_id': order.sellId.id,
        'username': order.sellId.username,
        'latitude': order.sellId.latitude,
        'longitude': order.sellId.longitude,
      },
      'wareId': order.wareId.id,
      'longitude': order.longitude,
      'latitude': order.latitude,
      'razorpay_order_id': order.razorpayOrderId,
      'createdAt': order.createdAt.toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
      '__v': order.v,
      'razorpay_payment_id': order.razorpayPaymentId,
      'razorpay_signature': order.razorpaySignature,
      'runnId': order.runnId.id,
    };
    print("updateOrder Data : $updatedOrderData");

    final success = await controller.updateFullOrder(widget.orderId, updatedOrderData);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order updated successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(controller.errorMessage ?? 'Failed to update order')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = Colors.teal;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(
          '🧾 Order Details',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),

        centerTitle: true,
      ),
      body: Consumer<OrderController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage != null) {
            return _ErrorView(
              message: controller.errorMessage!,
              onRetry: () => controller.fetchOrderById(widget.orderId),
            );
          }

          final order = controller.allOrders.firstWhere(
                (o) => o.id == widget.orderId,
            orElse: () => Order(
              id: '',
              items: [],
              mode: '',
              details: [],
              discount: '0',
              shipping: '0',
              totalAmount: 0,
              userId: UserId(id: '', username: ''),
              primary: 'false',
              payment: 0,
              status: 0,
              leadStatus: 0,
              orderId: 0,
              category: [],
              type: 0,
              bussId: BussId(id: '', username: '', mId: []),
              sellId: SellId(id: '', username: '', latitude: '', longitude: ''),
              wareId: WareId(id: '', username: ''),
              longitude: '',
              latitude: '',
              razorpayOrderId: '',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              v: 0,
              razorpayPaymentId: '',
              razorpaySignature: '',
              runnId: RunnId(id: '', username: ''),
            ),
          );

          if (order.id.isEmpty) {
            return const Center(child: Text('Order not found'));
          }

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _SectionCard(
                    title: "👤 Customer Information",
                    child: Column(
                      children: [
                        _EditableField(
                          label: 'Full Name',
                          icon: Icons.person,
                          value: _nameController.text,
                          onChanged: (value) => _nameController.text = value,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _EditableField(
                                label: 'Phone Number',
                                icon: Icons.phone,
                                value: _phoneController.text,
                                onChanged: (value) => _phoneController.text = value,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _EditableField(
                                label: 'Email',
                                icon: Icons.email,
                                value: _emailController.text,
                                onChanged: (value) => _emailController.text = value,
                              ),
                            ),
                          ],
                        ),
                        _EditableField(
                          label: 'Address',
                          icon: Icons.location_on,
                          value: _addressController.text,
                          onChanged: (value) => _addressController.text = value,
                        ),
                        _EditableField(
                          label: 'Pincode',
                          icon: Icons.pin_drop,
                          value: _pincodeController.text,
                          onChanged: (value) => _pincodeController.text = value,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: "🛍️ Order Items",
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.teal[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Expanded(flex: 4, child: Text('Item')),
                              Expanded(flex: 2, child: Text('Qty')),
                              Expanded(flex: 2, child: Text('Price')),
                              Expanded(flex: 2, child: Text('Total')),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...order.items.map((item) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                )
                              ],
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: Row(
                                    children: [
                                      if (item.image.isNotEmpty)
                                        ClipRRect(
                                          borderRadius:
                                          BorderRadius.circular(6),
                                          child: Image.network(
                                            item.image,
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '${item.quantity}',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '₹${item.price}',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '₹${item.price * item.quantity}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: "💰 Payment Summary",
                    child: Column(
                      children: [
                        _SummaryRow(
                          label: 'Subtotal',
                          value: '₹${order.items.fold(0, (sum, item) => sum + item.price * item.quantity)}',
                        ),
                        _SummaryRow(label: 'Shipping', value: '₹${order.shipping}'),
                        _SummaryRow(label: 'Discount', value: '- ₹${order.discount}'),
                        const Divider(thickness: 1),
                        _EditableField(
                          label: 'Total',
                          icon: Icons.money,
                          value: _totalAmountController.text,
                          onChanged: (value) => _totalAmountController.text = value,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: "📊 Order Status",
                    child: DropdownButton<int>(
                      value: _selectedStatus,
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Placed')),
                        DropdownMenuItem(value: 2, child: Text('Accepted')),
                        DropdownMenuItem(value: 3, child: Text('Processing / Packed')),
                        DropdownMenuItem(value: 4, child: Text('Dispatched')),
                        DropdownMenuItem(value: 5, child: Text('Out for Delivery')),
                        DropdownMenuItem(value: 6, child: Text('Delivered')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedStatus = value;
                          });
                        }
                      },
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      style: const TextStyle(color: Colors.black, fontSize: 16),
                      underline: Container(
                        height: 2,
                        color: Colors.teal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.update),
                    onPressed: _updateOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    label: const Text(
                      'Update Data',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      tween: Tween(begin: 0.9, end: 1.0),
      builder: (context, value, childWidget) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 12),
                childWidget!,
              ],
            ),
          ),
        );
      },
      child: child,
    );
  }
}

class _EditableField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Function(String) onChanged;

  const _EditableField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: TextField(
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.teal),
          labelText: label,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        controller: TextEditingController(text: value)
          ..selection = TextSelection.collapsed(offset: value.length),
        onChanged: onChanged,
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: isBold ? Colors.teal[700] : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 40),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}