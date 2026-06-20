import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../models/order.dart';

class CourierTrackingScreen extends StatefulWidget {
  final String orderId;
  const CourierTrackingScreen({super.key, required this.orderId});

  @override
  State<CourierTrackingScreen> createState() => _CourierTrackingScreenState();
}

class LatLngTween extends Tween<LatLng> {
  LatLngTween({required LatLng begin, required LatLng end}) : super(begin: begin, end: end);

  @override
  LatLng lerp(double t) {
    return LatLng(
      begin!.latitude + (end!.latitude - begin!.latitude) * t,
      begin!.longitude + (end!.longitude - begin!.longitude) * t,
    );
  }
}

class _CourierTrackingScreenState extends State<CourierTrackingScreen> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  
  LatLng? _courierLocation;
  LatLng? _customerLocation;
  bool _isLoading = true;
  String _distanceText = "Menghitung jarak...";
  Order? _order;

  Timer? _pollingTimer;
  List<LatLng> _routePoints = [];

  late AnimationController _animationController;
  Animation<LatLng>? _markerAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _animationController.addListener(() {
      if (_markerAnimation != null) {
        setState(() {
          _courierLocation = _markerAnimation!.value;
        });
      }
    });

    _initTracking();
    
    // Mulai polling API setiap 5 detik
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchLatestCourierLocation();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchLatestCourierLocation() async {
    if (!mounted) return;
    
    final orderProv = Provider.of<OrderProvider>(context, listen: false);
    // Background refresh (tidak mengubah status _isLoading utama)
    await orderProv.refreshCurrentOrder();
    
    if (orderProv.currentOrder != null) {
      _order = orderProv.currentOrder;
      
      if (_order!.courierLatitude != null && _order!.courierLongitude != null) {
        final newLocation = LatLng(_order!.courierLatitude!, _order!.courierLongitude!);
        
        // Hanya animasi jika titiknya benar-benar berubah
        if (_courierLocation == null || (_courierLocation!.latitude != newLocation.latitude || _courierLocation!.longitude != newLocation.longitude)) {
           _animateCourierTo(newLocation);
           if (_customerLocation != null) {
             _fetchRouteFromOSRM(newLocation, _customerLocation!);
           }
        }
      }
    }
  }

  void _animateCourierTo(LatLng newLocation) {
    if (_courierLocation == null) {
      setState(() {
        _courierLocation = newLocation;
      });
      return;
    }
    
    _markerAnimation = LatLngTween(begin: _courierLocation!, end: newLocation)
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _animationController.forward(from: 0.0);
  }

  Future<void> _fetchRouteFromOSRM(LatLng start, LatLng end) async {
    final url = Uri.parse('http://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?geometries=geojson&overview=full');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          
          // Parsing Polyline
          final geometry = route['geometry']['coordinates'] as List;
          final List<LatLng> parsedRoute = geometry.map((coord) {
            return LatLng(coord[1].toDouble(), coord[0].toDouble());
          }).toList();

          // Parsing Jarak dan ETA
          final distanceMeters = route['distance'] as num;
          final durationSeconds = route['duration'] as num;

          setState(() {
            _routePoints = parsedRoute;
            
            final distStr = distanceMeters < 1000 
                ? "${distanceMeters.toStringAsFixed(0)} m" 
                : "${(distanceMeters / 1000).toStringAsFixed(1)} km";
                
            final durMin = (durationSeconds / 60).ceil();
            _distanceText = "ETA: $durMin mnt ($distStr)";
          });
        }
      }
    } catch (e) {
      print("OSRM Routing error: $e");
    }
  }

  Future<void> _initTracking() async {
    // Ambil order dari provider
    final orderProv = Provider.of<OrderProvider>(context, listen: false);
    _order = orderProv.currentOrder?.id == widget.orderId 
        ? orderProv.currentOrder 
        : orderProv.myOrders.cast<Order?>().firstWhere(
            (o) => o?.id == widget.orderId, 
            orElse: () => null
          );

    if (_order != null) {
      // Tentukan lokasi tujuan berdasarkan status pesanan
      LatLng destination;
      
      if (_order!.status == OrderStatus.dibawa_kurir_ke_laundry || _order!.status == OrderStatus.sedang_dicuci) {
        // Jika kurir sedang membawa ke laundry, tujuannya adalah titik Laundry (bisa diatur via .env)
        final envLat = dotenv.env['LAUNDRY_LAT'] != null ? double.tryParse(dotenv.env['LAUNDRY_LAT']!) : null;
        final envLng = dotenv.env['LAUNDRY_LNG'] != null ? double.tryParse(dotenv.env['LAUNDRY_LNG']!) : null;
        destination = (envLat != null && envLng != null) 
            ? LatLng(envLat, envLng) 
            : const LatLng(-7.1286128, 112.4210956); // Fallback: Titik pusat Laundry WashWeswos
        
        // Ubah ikon customer di peta agar posisinya berada di titik laundry
        _customerLocation = destination;
      } else {
        // Jika statusnya menunggu kurir atau pengantaran, tujuannya adalah lokasi pelanggan
        if (_order!.latitude != null && _order!.longitude != null) {
          _customerLocation = LatLng(_order!.latitude!, _order!.longitude!);
        } else {
          // Fallback lokasi customer
          _customerLocation = const LatLng(-7.1186128, 112.4110956);
        }
        destination = _customerLocation!;
      }
      
      // Ambil lokasi kurir pertama kali dari state order yang ada
      if (_order!.courierLatitude != null && _order!.courierLongitude != null) {
        _courierLocation = LatLng(_order!.courierLatitude!, _order!.courierLongitude!);
      } else {
        _setDummyCourierLocation(); // Fallback sementara jika data belum siap
      }
    } else {
      _customerLocation = const LatLng(-7.1186128, 112.4110956);
      _setDummyCourierLocation();
    }

    if (_courierLocation != null && _customerLocation != null) {
      _fetchRouteFromOSRM(_courierLocation!, _customerLocation!);
    }

    setState(() {
      _isLoading = false;
    });

    // Posisikan peta untuk mencakup kedua titik setelah build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_courierLocation != null && _customerLocation != null) {
        _fitMapToBounds();
      }
    });
  }

  // Fungsi geolocator dihapus karena digantikan oleh API Polling

  void _setDummyCourierLocation() {
    // Beri sedikit jarak dari customer sebagai dummy lokasi kurir
    if (_customerLocation != null) {
      _courierLocation = LatLng(_customerLocation!.latitude - 0.01, _customerLocation!.longitude - 0.01);
    } else {
      _courierLocation = const LatLng(-7.1286128, 112.4210956);
    }
  }

  // Fungsi Kalkulasi Lurus dihapus karena sudah pakai OSRM ETA

  void _fitMapToBounds() {
    final bounds = LatLngBounds.fromPoints([_courierLocation!, _customerLocation!]);
    try {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(50.0),
        )
      );
    } catch (e) {
      // Ignored if map is not ready yet
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracking Kurir'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF005B71),
        elevation: 1,
      ),
      body: _isLoading 
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2DAAC8)),
            )
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _courierLocation ?? const LatLng(-7.1286128, 112.4210956),
                    initialZoom: 13.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.laundry_flutter',
                    ),
                    if (_routePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _routePoints,
                            color: const Color(0xFF2DAAC8),
                            strokeWidth: 5.0,
                          ),
                        ],
                      )
                    else if (_courierLocation != null && _customerLocation != null)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: [_courierLocation!, _customerLocation!],
                            color: const Color(0xFF2DAAC8).withOpacity(0.5),
                            strokeWidth: 3.0,
                            isDotted: true,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        if (_customerLocation != null)
                          Marker(
                            width: 60,
                            height: 60,
                            point: _customerLocation!,
                            child: const Column(
                              children: [
                                Icon(Icons.home, color: Color(0xFF005B71), size: 36),
                                Text("Tujuan", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        if (_courierLocation != null)
                          Marker(
                            width: 60,
                            height: 60,
                            point: _courierLocation!,
                            child: const Column(
                              children: [
                                Icon(Icons.motorcycle, color: Color(0xFF2DAAC8), size: 36),
                                Text("Kurir", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Card(
                    margin: EdgeInsets.zero,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    elevation: 10,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _order != null 
                                ? 'Menuju lokasi ${_order!.customer.name}' 
                                : 'Mencari pesanan...',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1C1F24)),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.map_outlined, color: Colors.grey, size: 20),
                              const SizedBox(width: 8),
                              Text('Jarak tersisa: $_distanceText', style: const TextStyle(color: Colors.black54, fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Membuka aplikasi telepon atau WhatsApp...')),
                              );
                            },
                            icon: const Icon(Icons.phone),
                            label: const Text('Hubungi Kurir', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2DAAC8),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
