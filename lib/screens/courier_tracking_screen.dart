import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CourierTrackingScreen extends StatefulWidget {
  final String orderId;
  const CourierTrackingScreen({super.key, required this.orderId});

  @override
  State<CourierTrackingScreen> createState() => _CourierTrackingScreenState();
}

class _CourierTrackingScreenState extends State<CourierTrackingScreen> {
  GoogleMapController? _mapController;
  final LatLng _courierLocation = const LatLng(-6.205000, 106.820000); // Dummy courier location
  final LatLng _userLocation = const LatLng(-6.200000, 106.816666); // Dummy user location

  @override
  Widget build(BuildContext context) {
    final markers = {
      Marker(
        markerId: const MarkerId('courier'),
        position: _courierLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Kurir Anda'),
      ),
      Marker(
        markerId: const MarkerId('user'),
        position: _userLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Lokasi Anda'),
      ),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Tracking Kurir')),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _courierLocation,
              zoom: 14,
            ),
            markers: markers,
            onMapCreated: (controller) => _mapController = controller,
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
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Kurir Budi sedang menuju lokasi Anda', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    const Text('Estimasi tiba: 10 Menit', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                       
                      },
                      icon: const Icon(Icons.phone),
                      label: const Text('Hubungi Kurir'),
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
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
