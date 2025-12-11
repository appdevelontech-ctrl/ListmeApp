import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class Order {
  final String id;
  final List<Item> items;
  final String mode;
  final List<Detail> details;
  final String discount;
  final String shipping;
  final int totalAmount;
  final UserId userId; // Typically the buyer or rider
  final String primary;
  final int payment;
  final int status;
  final int leadStatus;
  final int orderId;
  final List<String> category;
  final int type;
  final BussId bussId; // Business entity
  final SellId sellId; // Seller
  final WareId wareId; // Warehouse
  final String longitude;
  final String latitude;
  final String razorpayOrderId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int v;
  final String razorpayPaymentId;
  final String razorpaySignature;
  final RunnId runnId; // Runner or delivery person

  Order({
    required this.id,
    required this.items,
    required this.mode,
    required this.details,
    required this.discount,
    required this.shipping,
    required this.totalAmount,
    required this.userId,
    required this.primary,
    required this.payment,
    required this.status,
    required this.leadStatus,
    required this.orderId,
    required this.category,
    required this.type,
    required this.bussId,
    required this.sellId,
    required this.wareId,
    required this.longitude,
    required this.latitude,
    required this.razorpayOrderId,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
    required this.razorpayPaymentId,
    required this.razorpaySignature,
    required this.runnId,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['_id'] as String? ?? '',
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => Item.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      mode: json['mode'] as String? ?? '',
      details: (json['details'] as List<dynamic>?)
          ?.map((e) => Detail.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      discount: json['discount'] as String? ?? '0',
      shipping: json['shipping'] as String? ?? '0',
      totalAmount: (json['totalAmount'] as num?)?.toInt() ?? 0,
      userId: json['userId'] != null
          ? UserId.fromJson(json['userId'])
          : UserId(id: '', username: ''),
      primary: json['primary'] as String? ?? 'false',
      payment: (json['payment'] as num?)?.toInt() ?? 0,
      status: (json['status'] as num?)?.toInt() ?? 0,
      leadStatus: (json['leadStatus'] as num?)?.toInt() ?? 0,
      orderId: (json['orderId'] as num?)?.toInt() ?? 0,
      category: List<String>.from(json['category'] ?? []),
      type: (json['type'] as num?)?.toInt() ?? 0,
      bussId: json['bussId'] != null
          ? BussId.fromJson(json['bussId'])
          : BussId(id: '', username: '', mId: []),
      sellId: json['sellId'] != null
          ? SellId.fromJson(json['sellId'])
          : SellId(id: '', username: '', latitude: '', longitude: ''),
      wareId: json['wareId'] != null
          ? WareId.fromJson(json['wareId'])
          : WareId(id: '', username: ''),
      longitude: json['longitude'] as String? ?? '',
      latitude: json['latitude'] as String? ?? '',
      razorpayOrderId: json['razorpay_order_id'] as String? ?? '',
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(json['updatedAt']) ?? DateTime.now(),
      v: (json['__v'] as num?)?.toInt() ?? 0,
      razorpayPaymentId: json['razorpay_payment_id'] as String? ?? '',
      razorpaySignature: json['razorpay_signature'] as String? ?? '',
      runnId: json['runnId'] != null
          ? RunnId.fromJson(json['runnId'])
          : RunnId(id: '', username: ''),
    );
  }

  static DateTime? _parseDateTime(dynamic date) {
    if (date is String) {
      try {
        return DateTime.parse(date);
      } catch (e) {
        return null;
      }
    }
    return date as DateTime?;
  }

  // Safe getters for UI
  String get customerName =>
      details.isNotEmpty ? details.first.username : 'Unknown Customer';
  String get location =>
      details.isNotEmpty ? details.first.address : 'No location';
  String get bookingDate => DateFormat('dd MMM yyyy').format(createdAt);
  String get bookingTime => DateFormat('HH:mm').format(createdAt);
  String get partnerName => bussId.username.isNotEmpty ? bussId.username : 'N/A';
  String get statusText {
    switch (status) {
      case 1:
        return 'Placed';
      case 2:
        return 'Accepted';
      case 3:
        return 'Processing / Packed';
      case 4:
        return 'Dispatched';
      case 5:
        return 'Out for Delivery';
      case 6:
        return 'Delivered';
      default:
        return 'Unknown';
    }
  }
}

class Item {
  final String id;
  final String title;
  final String image;
  final int regularPrice;
  final int price;
  final String color;
  final String customise;
  final int totalQuantity;
  final int? weight;
  final int? gst;
  final int stock;
  final String pid;
  final String userId;
  final int quantity;

  Item({
    required this.id,
    required this.title,
    required this.image,
    required this.regularPrice,
    required this.price,
    required this.color,
    required this.customise,
    required this.totalQuantity,
    this.weight,
    this.gst,
    required this.stock,
    required this.pid,
    required this.userId,
    required this.quantity,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      image: json['image'] as String? ?? '',
      regularPrice: (json['regularPrice'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toInt() ?? 0,
      color: json['color'] as String? ?? '',
      customise: json['customise'] as String? ?? '',
      totalQuantity: (json['TotalQuantity'] as num?)?.toInt() ?? 0,
      weight: (json['weight'] as num?)?.toInt(),
      gst: (json['gst'] as num?)?.toInt(),
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      pid: json['pid'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    );
  }
}

class Detail {
  final String username;
  final String phone;
  final String pincode;
  final String state;
  final String address;
  final String email;

  Detail({
    required this.username,
    required this.phone,
    required this.pincode,
    required this.state,
    required this.address,
    required this.email,
  });

  factory Detail.fromJson(Map<String, dynamic> json) {
    return Detail(
      username: json['username'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      pincode: json['pincode'] as String? ?? '',
      state: json['state'] as String? ?? '',
      address: json['address'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }
}

class UserId {
  final String id;
  final String username;

  UserId({required this.id, required this.username});

  factory UserId.fromJson(dynamic json) {
    if (json is String) return UserId(id: json, username: '');
    return UserId(
      id: json['_id'] as String? ?? '',
      username: json['username'] as String? ?? '',
    );
  }
}

class BussId {
  final String id;
  final String username;
  final List<MId> mId;

  BussId({required this.id, required this.username, required this.mId});

  factory BussId.fromJson(dynamic json) {
    if (json is String) return BussId(id: json, username: '', mId: []);
    return BussId(
      id: json['_id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      mId: (json['mId'] as List<dynamic>?)
          ?.map((e) => MId.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }
}

class MId {
  final String id;
  final String username;
  final String latitude;
  final String longitude;

  MId({
    required this.id,
    required this.username,
    required this.latitude,
    required this.longitude,
  });

  factory MId.fromJson(Map<String, dynamic> json) {
    return MId(
      id: json['_id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      latitude: json['latitude'] as String? ?? '',
      longitude: json['longitude'] as String? ?? '',
    );
  }
}

class SellId {
  final String id;
  final String username;
  final String latitude;
  final String longitude;

  SellId({
    required this.id,
    required this.username,
    required this.latitude,
    required this.longitude,
  });

  factory SellId.fromJson(dynamic json) {
    if (json is String) return SellId(id: json, username: '', latitude: '', longitude: '');
    return SellId(
      id: json['_id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      latitude: json['latitude'] as String? ?? '',
      longitude: json['longitude'] as String? ?? '',
    );
  }
}

class WareId {
  final String id;
  final String username;

  WareId({required this.id, required this.username});

  factory WareId.fromJson(dynamic json) {
    if (json is String) return WareId(id: json, username: '');
    return WareId(
      id: json['_id'] as String? ?? '',
      username: json['username'] as String? ?? '',
    );
  }
}

class RunnId {
  final String id;
  final String username;

  RunnId({required this.id, required this.username});

  factory RunnId.fromJson(dynamic json) {
    if (json is String) return RunnId(id: json, username: '');
    return RunnId(
      id: json['_id'] as String? ?? '',
      username: json['username'] as String? ?? '',
    );
  }
}
