import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/order_model.dart';
import '../controllers/order_controller.dart';
import '../main.dart';


class NotificationService {
  static final _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: DarwinInitializationSettings(),
    );
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse :(NotificationResponse? response) async {
        final payload = response?.payload;
        if (payload != null) {
          print('NotificationService: Notification tapped with payload: $payload');
          navigatorKey.currentState?.pushNamed('/order_details', arguments: payload);
        }
      },
    );
  }

  static Future<void> showNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'order_channel',
      'Order Notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);
    await _notificationsPlugin.show(
      message.messageId.hashCode,
      message.notification?.title ?? 'New Order',
      message.notification?.body ?? 'A new order has been received.',
      platformChannelSpecifics,
      payload: message.data['orderId'],
    );
  }

  static Future<void> showSocketOrderNotification(Order order) async {
    if (!['Place', 'new', '1', 'pending'].contains(order.status)) {
      print('NotificationService: Skipping notification for order ${order.id} (status: ${order.status})');
      return;
    }
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'order_channel',
      'Order Notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);
    final notificationBody =
        'Order ID: ${order.orderId}\n'
        'Customer Name: ${order.customerName}\n';

    await _notificationsPlugin.show(
      order.id.hashCode,
      'New Order Received',
     notificationBody,
      platformChannelSpecifics,
      payload: order.id,
    );
    print('NotificationService: Local notification shown for order ${order.id}');
  }
}