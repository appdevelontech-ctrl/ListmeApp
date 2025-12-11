    import 'dart:async';
    import 'package:flutter/material.dart';
    import 'package:google_maps_flutter/google_maps_flutter.dart';
    import 'package:socket_io_client/socket_io_client.dart' as IO;
    import 'package:shared_preferences/shared_preferences.dart';
    import '../main.dart'; // for navigatorKey
    import 'package:provider/provider.dart';
    import 'package:audioplayers/audioplayers.dart';
    import 'order_controller.dart';

    class SocketController extends ChangeNotifier {
      IO.Socket? _socket;
      String? _orderId;
      String? _userId;
      bool _isConnected = false;
      bool _isInitialized = false;
      final AudioPlayer _audioPlayer = AudioPlayer();

      SocketController() {
        _initializeSocket();
      }

      // 🔹 Initialize Socket
      Future<void> _initializeSocket() async {
        if (_isInitialized) return;
        _isInitialized = true;

        final prefs = await SharedPreferences.getInstance();
        _userId = prefs.getString('employeeId') ?? '';
        print('🔑 SocketController initialized for user=$_userId');

        _socket = IO.io(
          'https://listmein.onrender.com',
          <String, dynamic>{
            'transports': ['websocket'],
            'autoConnect': true,
            'reconnection': true,
            'reconnectionAttempts': 9999,
            'reconnectionDelay': 2000,
          },
        );

        // ✅ Connection events
        _socket?.on('connect', (_) {
          _isConnected = true;
          print('✅ Socket connected');
          notifyListeners();
        });

        _socket?.on('disconnect', (_) {
          _isConnected = false;
          print('⚠️ Socket disconnected');
          notifyListeners();
        });

        _socket?.on('connect_error', (error) {
          _isConnected = false;
          print('❌ Socket error: $error');
        });

        _socket?.on('reconnect', (_) {
          print('♻️ Socket reconnected');
          if (_orderId != null) {
            // Resend last location (or dummy) after reconnect
            sendLocationUpdate(LatLng(0, 0));
          }
        });

        // ✅ Location confirmation event
        _socket?.on('locationUpdate', (data) {
          print('📍 Location update confirmed for order: ${data['orderId']}');
        });

        // ✅ New order event listener
        _socket?.on('new', (data) {
          print('🆕 New order received: $data');
          _showNewOrderPopup(data);
        });

        connectSocket();
      }

      // 🔹 Connect socket
      void connectSocket() {
        if (_socket != null && !(_socket?.connected ?? false)) {
          print('🔌 Connecting socket...');
          _socket?.connect();
        }
      }

      // 🔹 Disconnect socket
      void disconnectSocket() {
        if (_socket != null && (_socket?.connected ?? false)) {
          print('🔌 Disconnecting socket...');
          _socket?.disconnect();
        }
      }

      // 🔹 Force reconnect
      void reconnectSocket() {
        print('♻️ Forcing socket reconnect...');
        disconnectSocket();
        Future.delayed(const Duration(seconds: 1), () => connectSocket());
      }

      // 🔹 Set active order
      void setOrderId(String orderId) {
        _orderId = orderId;
        print('📦 Tracking order: $_orderId');
        notifyListeners();
      }

      // 🔹 Send location updates
      void sendLocationUpdate(LatLng currentLocation) {
        if (!_isConnected || _orderId == null || _userId == null) {
          print('⚠️ Cannot send location: socket disconnected or missing data');
          return;
        }

        final message = {
          "userId": _userId,
          "currentLocation": {
            "lat": currentLocation.latitude,
            "lng": currentLocation.longitude,
          },
          "type": "location",
          "orderId": _orderId,
        };

        _socket?.emit('sendMessage', message);
        print(
            '📡 Sent location → Order: $_orderId | Lat: ${currentLocation.latitude}, Lng: ${currentLocation.longitude}');
      }

      // 🔔 Show popup on new order
      Future<void> _showNewOrderPopup(dynamic data) async {
        if (navigatorKey.currentContext == null) return;

        final orderId = data['orderId']?.toString();
        if (orderId == null) return;

        try {
          await _audioPlayer.stop();
          await _audioPlayer.play(AssetSource('sounds/school-bell-310293.mp3'));
          _audioPlayer.setReleaseMode(ReleaseMode.loop);
        } catch (e) {
          print('❌ Audio error: $e');
        }

        showDialog(
          context: navigatorKey.currentContext!,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              title: const Text(
                '🆕 New Order Received!',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
              ),
              content: Text(
                'Order ID: $orderId\n'
                    'Pickup: ${data['pickupAddress'] ?? 'Unknown'}\n'
                    'Drop: ${data['dropAddress'] ?? 'Unknown'}',
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    await _audioPlayer.stop();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Reject', style: TextStyle(color: Colors.red)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () async {
                    await _audioPlayer.stop();
                    Navigator.of(context).pop();

                    try {
                      final orderController = Provider.of<OrderController>(
                        navigatorKey.currentContext!,
                        listen: false,
                      );
                      await orderController.updateOrderStatus(orderId, 2);

                      ScaffoldMessenger.of(navigatorKey.currentContext!)
                          .showSnackBar(const SnackBar(
                        content: Text('Order accepted successfully!'),
                        backgroundColor: Colors.green,
                      ));
                    } catch (e) {
                      ScaffoldMessenger.of(navigatorKey.currentContext!)
                          .showSnackBar(SnackBar(
                        content: Text('Failed to accept order: $e'),
                        backgroundColor: Colors.red,
                      ));
                    }
                  },
                  child: const Text('Accept'),
                ),
              ],
            );
          },
        );
      }

      bool get isConnected => _isConnected;

      @override
      void dispose() {
        _audioPlayer.dispose();
        _socket?.dispose();
        super.dispose();
      }
    }
