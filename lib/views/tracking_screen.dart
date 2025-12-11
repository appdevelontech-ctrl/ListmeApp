import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../models/order_model.dart';
import '../controllers/socket_controller.dart';

const String GOOGLE_MAPS_API_KEY = 'AIzaSyCcppZWLo75ylSQvsR-bTPZLEFEEec5nrY';

class TrackingScreen extends StatefulWidget {
  final Order order;
  final LatLng initialCurrentPosition;

  const TrackingScreen({
    super.key,
    required this.order,
    required this.initialCurrentPosition,
  });

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> with SingleTickerProviderStateMixin {
  late GoogleMapController _mapController;
  late LatLng _currentPosition;
  late LatLng _startPosition;
  late LatLng _destinationPosition;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  StreamSubscription<Position>? _positionStream;
  bool _isMapReady = false;
  BitmapDescriptor? _bikeIcon;
  BitmapDescriptor? _startIcon;
  BitmapDescriptor? _destinationIcon;
  double _distance = 0.0; // In kilometers
  String _eta = 'Calculating...';
  String _riderStatus = 'Unknown'; // Moving or Stopped
  static const double _speedKmph = 20.0;
  Timer? _debounceTimer;
  LatLng? _lastSocketUpdatePosition;
  Timer? _routeThrottleTimer;
  List<NavigationStep> _navigationSteps = [];
  AnimationController? _animationController;
  LatLng? _animatedPosition;
  String _currentStreet = 'Fetching street...';
  DateTime? _lastPositionTime;
  double _lastSpeed = 0.0;

  late SocketController _socketController;

  @override
  void initState() {
    super.initState();
    print('TrackingScreen: Initializing at ${DateTime.now()}');

    _startPosition = _determineStartPosition(widget.order);
    _destinationPosition = LatLng(
      double.parse(widget.order.latitude),
      double.parse(widget.order.longitude),
    );
    _currentPosition = widget.initialCurrentPosition;
    _animatedPosition = _currentPosition;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _calculateDistanceAndETA();
    _loadNetworkIcons();

    _socketController = Provider.of<SocketController>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {

      _socketController.connectSocket();
      _socketController.setOrderId(widget.order.id);
    });

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3,
      ),
    ).listen((Position position) {
      if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 200), () {
        final newPosition = LatLng(position.latitude, position.longitude);
        if (_currentPosition != newPosition) {
          _updateRiderStatus(position);
          _animateMarkerToPosition(newPosition);
          setState(() {
            _currentPosition = newPosition;
            _calculateDistanceAndETA();
            if (_isMapReady) _updateMarkers();
            _updateCurrentStreet();
          });
          _sendSocketDataIfMoved10m(newPosition);
          _maybeRecalculateRoutes(newPosition);
        }
      });
    });
  }

  void _updateRiderStatus(Position position) {
    final now = DateTime.now();
    if (_lastPositionTime == null) {
      _lastPositionTime = now;
      _riderStatus = 'Stopped';
      return;
    }

    final timeDiff = now.difference(_lastPositionTime!).inSeconds;
    _lastPositionTime = now;

    final speed = position.speed >= 0 ? position.speed : _lastSpeed;
    _lastSpeed = speed;

    setState(() {
      _riderStatus = speed > 0.5 ? 'Moving' : 'Stopped';
    });
  }

  LatLng _determineStartPosition(Order order) {
    try {
      if (order.bussId.mId.isNotEmpty) {
        final mId = order.bussId.mId.firstWhere(
              (m) => m.latitude.isNotEmpty && m.longitude.isNotEmpty,
        );
        if (mId != null) {
          return LatLng(double.parse(mId.latitude), double.parse(mId.longitude));
        }
      }
    } catch (e) {
      // ignore parsing errors and fallback
    }
    return LatLng(
      double.parse(order.sellId.latitude),
      double.parse(order.sellId.longitude),
    );
  }

  Future<void> _loadNetworkIcons() async {
    try {
      _bikeIcon = await _getBitmapDescriptorFromUrl(
        'https://img.icons8.com/color/48/000000/motorcycle.png',
        size: 150,
      );
      _startIcon = await _getBitmapDescriptorFromUrl(
        'https://img.icons8.com/color/48/000000/home.png',
        size: 100,
      );
      _destinationIcon = await _getBitmapDescriptorFromUrl(
        'https://img.icons8.com/color/48/000000/delivery.png',
        size: 100,
      );
      if (_isMapReady) {
        _updateMarkers();
        _recalculateFullRouteImmediate();
      }
    } catch (e) {
      print('TrackingScreen: Error loading icons: $e');
      _bikeIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      _startIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      _destinationIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      if (_isMapReady) {
        _updateMarkers();
        _recalculateFullRouteImmediate();
      }
    }
  }

  Future<BitmapDescriptor> _getBitmapDescriptorFromUrl(String url, {int size = 100}) async {
    final ui.Image image = await _getImageFromUrl(url);
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final paint = Paint()..isAntiAlias = true;

    final double scale = size / math.max(image.width, image.height);
    final newWidth = image.width * scale;
    final newHeight = image.height * scale;

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, newWidth, newHeight),
      paint,
    );

    final picture = pictureRecorder.endRecording();
    final img = await picture.toImage(newWidth.toInt(), newHeight.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) throw Exception('Failed to convert image to ByteData');
    return BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
  }

  Future<ui.Image> _getImageFromUrl(String url) async {
    final Completer<ui.Image> completer = Completer<ui.Image>();
    final image = NetworkImage(url);
    image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool synchronousCall) {
        completer.complete(info.image);
      }, onError: (exception, stackTrace) {
        completer.completeError(exception, stackTrace);
      }),
    );
    return completer.future;
  }

  void _animateMarkerToPosition(LatLng newPosition) {
    final begin = _animatedPosition ?? _currentPosition;
    final animation = LatLngTween(begin: begin, end: newPosition).animate(_animationController!);
    animation.addListener(() {
      setState(() {
        _animatedPosition = animation.value;
        _updateMarkers();
      });
    });
    _animationController!.forward(from: 0);
  }

  @override
  void dispose() {
    print('TrackingScreen: Disposing at ${DateTime.now()}');
    _debounceTimer?.cancel();
    _routeThrottleTimer?.cancel();
    _animationController?.dispose();
    _mapController.dispose();
    _positionStream?.cancel();
    super.dispose();
  }

  void _sendSocketDataIfMoved10m(LatLng currentLocation) {
    if (_lastSocketUpdatePosition == null) {
      _lastSocketUpdatePosition = currentLocation;
      _socketController.sendLocationUpdate(currentLocation);
      return;
    }
    final distanceMoved = Geolocator.distanceBetween(
      _lastSocketUpdatePosition!.latitude,
      _lastSocketUpdatePosition!.longitude,
      currentLocation.latitude,
      currentLocation.longitude,
    );
    if (distanceMoved >= 10) {
      _lastSocketUpdatePosition = currentLocation;
      _socketController.sendLocationUpdate(currentLocation);
    }
  }

  void _maybeRecalculateRoutes(LatLng newPosition) {
    if (_routeThrottleTimer?.isActive ?? false) {
      return;
    }
    final last = _lastSocketUpdatePosition ?? _currentPosition;
    final moved = Geolocator.distanceBetween(
      last.latitude,
      last.longitude,
      newPosition.latitude,
      newPosition.longitude,
    );
    if (moved >= 50) {
      _recalculateFullRouteImmediate();
      _routeThrottleTimer = Timer(const Duration(seconds: 10), () {});
    } else {
      _routeThrottleTimer = Timer(const Duration(seconds: 10), () {
        _recalculateFullRouteImmediate();
      });
    }
  }

  Future<void> _recalculateFullRouteImmediate() async {
    if (!_isMapReady) return;
    try {
      final result1 = await _fetchRouteData(_currentPosition, _startPosition);
      final result2 = await _fetchRouteData(_startPosition, _destinationPosition);
      setState(() {
        _polylines = {};
        if (result1.polyline.isNotEmpty) {
          _polylines.add(Polyline(
            polylineId: const PolylineId('currentToStart'),
            points: result1.polyline,
            width: 10,
            color: Colors.blueAccent.withOpacity(0.9),
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            patterns: [PatternItem.dash(15), PatternItem.gap(8)],
          ));
        } else {
          _polylines.add(Polyline(
            polylineId: const PolylineId('currentToStart'),
            points: [_currentPosition, _startPosition],
            width: 8,
            color: Colors.blueAccent.withOpacity(0.7),
          ));
        }
        if (result2.polyline.isNotEmpty) {
          _polylines.add(Polyline(
            polylineId: const PolylineId('startToDestination'),
            points: result2.polyline,
            width: 10,
            color: Colors.black87.withOpacity(0.9),
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            patterns: [PatternItem.dash(15), PatternItem.gap(8)],
          ));
        } else {
          _polylines.add(Polyline(
            polylineId: const PolylineId('startToDestination'),
            points: [_startPosition, _destinationPosition],
            width: 8,
            color: Colors.black87.withOpacity(0.7),
          ));
        }
        _navigationSteps = result1.steps + result2.steps;
        _updateCurrentStreet();
      });
      _updateMarkers();
      _fitMapToBounds();
    } catch (e) {
      print('TrackingScreen: Error recalculating routes: $e');
    }
  }

  Future<RouteData> _fetchRouteData(LatLng origin, LatLng destination) async {
    try {
      final url =
          'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&mode=driving&key=$GOOGLE_MAPS_API_KEY';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        print('Directions API error: ${response.statusCode} ${response.body}');
        return RouteData(polyline: [], steps: []);
      }
      final data = json.decode(response.body);
      if (data['routes'] != null && data['routes'].isNotEmpty) {
        final overview = data['routes'][0]['overview_polyline']['points'];
        final polyline = _decodePolyline(overview);
        final steps = data['routes'][0]['legs'][0]['steps'] as List;
        final navigationSteps = steps.map((step) {
          final instruction = _stripHtmlTags(step['html_instructions'] as String);
          final distance = step['distance']['text'] ?? 'Unknown';
          final startLocation = LatLng(
            step['start_location']['lat'] as double,
            step['start_location']['lng'] as double,
          );
          return NavigationStep(
            instruction: instruction,
            distance: distance,
            startLocation: startLocation,
          );
        }).toList();
        return RouteData(polyline: polyline, steps: navigationSteps);
      }
      return RouteData(polyline: [], steps: []);
    } catch (e) {
      print('TrackingScreen: _fetchRouteData error: $e');
      return RouteData(polyline: [], steps: []);
    }
  }

  String _stripHtmlTags(String htmlText) {
    final RegExp exp = RegExp(r'<[^>]+>', multiLine: true);
    String cleaned = htmlText.replaceAll(exp, '');
    // Additional cleaning for common HTML entities
    cleaned = cleaned.replaceAll(RegExp(r'&nbsp;'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'&#39;'), "'");
    cleaned = cleaned.replaceAll(RegExp(r'&quot;'), '"');
    cleaned = cleaned.replaceAll(RegExp(r'&amp;'), '&');
    return cleaned.trim();
  }

  void _updateCurrentStreet() {
    if (_navigationSteps.isEmpty) {
      _currentStreet = 'Unknown street';
      return;
    }

    // Find the closest step based on current position
    NavigationStep? closestStep;
    double minDistance = double.infinity;

    for (var step in _navigationSteps) {
      final distance = Geolocator.distanceBetween(
        _currentPosition.latitude,
        _currentPosition.longitude,
        step.startLocation.latitude,
        step.startLocation.longitude,
      );
      if (distance < minDistance) {
        minDistance = distance;
        closestStep = step;
      }
    }

    setState(() {
      _currentStreet = closestStep?.instruction ?? 'Unknown street';
    });
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return poly;
  }

  void _updateMarkers() {
    setState(() {
      _markers = {
        if (_startIcon != null)
          Marker(
            markerId: const MarkerId('start'),
            position: _startPosition,
            icon: _startIcon!,
            infoWindow: const InfoWindow(title: 'Seller Location'),
          ),
        if (_bikeIcon != null)
          Marker(
            markerId: const MarkerId('current'),
            position: _animatedPosition ?? _currentPosition,
            icon: _bikeIcon!,
            infoWindow: InfoWindow(title: 'You'),
          ),
        if (_destinationIcon != null)
          Marker(
            markerId: const MarkerId('destination'),
            position: _destinationPosition,
            icon: _destinationIcon!,
            infoWindow: const InfoWindow(title: 'Order Location'),
          ),
      };
    });
  }

  void _fitMapToBounds() {
    final allPoints = <LatLng>[];
    for (final pl in _polylines) {
      allPoints.addAll(pl.points);
    }
    if (allPoints.isEmpty) {
      allPoints.addAll([_currentPosition, _startPosition, _destinationPosition]);
    }
    double minLat = allPoints.first.latitude, maxLat = allPoints.first.latitude;
    double minLng = allPoints.first.longitude, maxLng = allPoints.first.longitude;

    for (final p in allPoints) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    try {
      _mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100.0));
    } catch (e) {
      _mapController.animateCamera(CameraUpdate.newLatLngZoom(_currentPosition, 16));
    }
  }

  void _calculateDistanceAndETA() {
    final double distanceToStart = Geolocator.distanceBetween(
      _currentPosition.latitude,
      _currentPosition.longitude,
      _startPosition.latitude,
      _startPosition.longitude,
    ) / 1000;
    final double distanceToDestination = Geolocator.distanceBetween(
      _startPosition.latitude,
      _startPosition.longitude,
      _destinationPosition.latitude,
      _destinationPosition.longitude,
    ) / 1000;
    _distance = distanceToStart + distanceToDestination;

    final double timeInHours = _distance / _speedKmph;
    final int minutes = (timeInHours * 60).round();
    _eta = minutes > 0 ? '${minutes ~/ 60}h ${minutes % 60}m' : 'Arrived';
  }

  @override
  Widget build(BuildContext context) {
    final customerName = widget.order.customerName;
    print('TrackingScreen: Building UI at ${DateTime.now()}');
    return Scaffold(
      appBar: AppBar(
        title: Text('Tracking Order ${widget.order.orderId}'),
        backgroundColor: Colors.teal,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) {
              _mapController = controller;
              _isMapReady = true;
              _mapController.setMapStyle(_mapStyle);
              _updateMarkers();
              _recalculateFullRouteImmediate();
            },
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 16,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            trafficEnabled: true,
            mapType: MapType.normal,
            buildingsEnabled: true,
            indoorViewEnabled: true,
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order ID: ${widget.order.orderId}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 8),
                    Text('Customer: $customerName', style: const TextStyle(fontSize: 16)),
                    Text('Status: ${widget.order.statusText}', style: const TextStyle(fontSize: 16)),
                     const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Distance: ${_distance.toStringAsFixed(2)} km',
                            style: const TextStyle(fontSize: 16)),
                        Text('ETA: $_eta', style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Navigation',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentStreet,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_navigationSteps.isNotEmpty)
                      Text(
                        'In ${_navigationSteps.first.distance}',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      )
                    else
                      const Text('No navigation instructions available'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced map style for better visibility of streets, alleys, and landmarks
  static const String _mapStyle = '''
    [
      {
        "elementType": "geometry",
        "stylers": [{"color": "#f5f5f5"}]
      },
      {
        "elementType": "labels.text.fill",
        "stylers": [{"color": "#333333"}]
      },
      {
        "elementType": "labels.text.stroke",
        "stylers": [{"color": "#ffffff"}, {"weight": 2}]
      },
      {
        "featureType": "road",
        "elementType": "geometry",
        "stylers": [{"color": "#ffffff"}]
      },
      {
        "featureType": "road.arterial",
        "elementType": "geometry",
        "stylers": [{"color": "#e0d7f0"}, {"weight": 1.5}]
      },
      {
        "featureType": "road.highway",
        "elementType": "geometry",
        "stylers": [{"color": "#d0c0e8"}, {"weight": 2}]
      },
      {
        "featureType": "road.local",
        "elementType": "geometry",
        "stylers": [{"color": "#f0f0f0"}, {"weight": 1}]
      },
      {
        "featureType": "road.local",
        "elementType": "labels.text",
        "stylers": [{"visibility": "on"}]
      },
      {
        "featureType": "poi",
        "elementType": "geometry",
        "stylers": [{"color": "#e5e5e5"}]
      },
      {
        "featureType": "poi",
        "elementType": "labels.text",
        "stylers": [{"visibility": "on"}, {"color": "#555555"}]
      },
      {
        "featureType": "landscape",
        "elementType": "geometry",
        "stylers": [{"color": "#f0f0f0"}]
      },
      {
        "featureType": "water",
        "elementType": "geometry",
        "stylers": [{"color": "#a0d6ff"}]
      },
      {
        "featureType": "transit",
        "elementType": "geometry",
        "stylers": [{"color": "#e0e0e0"}]
      }
    ]
  ''';
}

class RouteData {
  final List<LatLng> polyline;
  final List<NavigationStep> steps;

  RouteData({required this.polyline, required this.steps});
}

class NavigationStep {
  final String instruction;
  final String distance;
  final LatLng startLocation;

  NavigationStep({
    required this.instruction,
    required this.distance,
    required this.startLocation,
  });
}

class LatLngTween extends Tween<LatLng> {
  LatLngTween({required LatLng begin, required LatLng end}) : super(begin: begin, end: end);

  @override
  LatLng lerp(double t) {
    final lat = begin!.latitude + (end!.latitude - begin!.latitude) * t;
    final lng = begin!.longitude + (end!.longitude - begin!.longitude) * t;
    return LatLng(lat, lng);
  }
}