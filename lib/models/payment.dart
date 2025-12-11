class Payment {
  final String id;
  final String? paymentId;
  final String razorpayOrderId;
  final String note;
  final int? totalAmount; // Made nullable
  final String userId;
  final int? payment; // Made nullable
  final int? paymentConfirm; // Made nullable
  final int? local; // Made nullable
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? razorpayPaymentId;
  final String? razorpaySignature;

  Payment({
    required this.id,
    this.paymentId,
    required this.razorpayOrderId,
    required this.note,
    this.totalAmount, // Nullable
    required this.userId,
    this.payment, // Nullable
    this.paymentConfirm, // Nullable
    this.local, // Nullable
    required this.createdAt,
    this.updatedAt,
        this.razorpayPaymentId,
    this.razorpaySignature,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    print('Parsing JSON for Payment: $json');
    return Payment(
      id: json['_id'] as String,
      paymentId: json['paymentId'] != null ? json['paymentId'].toString() : null,
      razorpayOrderId: json['razorpay_order_id'] as String? ?? 'Unknown', // Default if null
      note: json['note'] as String? ?? 'Unknown', // Default if null
      totalAmount: (json['totalAmount'] as num?)?.toInt() ?? 0, // Default to 0 if null
      userId: json['userId'] as String? ?? 'Unknown', // Default if null
      payment: json['payment'] as int? ?? 0, // Default to 0 if null
      paymentConfirm: json['paymentConfirm'] as int? ?? 0, // Default to 0 if null
      local: json['Local'] as int? ?? 0, // Default to 0 if null
      createdAt: DateTime.parse(json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
      razorpayPaymentId: json['razorpay_payment_id'] as String?,
      razorpaySignature: json['razorpay_signature'] as String?,
    );
  }
}