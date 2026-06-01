import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart'; 

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  // Kita pakai LatLng resmi dari latlong2 untuk State posisi kita
  LatLng _selectedLocation = const LatLng(-7.0934, 112.3164); 
  bool _isLoadingLocation = true;
  String _addressText = "Sedang mengunci posisi GPS HP..."; 
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _isLoadingLocation = false;
        _addressText = "GPS HP mati. Tolong aktifkan GPS kamu, bosku.";
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _isLoadingLocation = false;
          _addressText = "Izin lokasi ditolak.";
        });
        return;
      }
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );

      // JALAN NINJA: Langsung set koordinat GPS ke State utama
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });

      // Ambil teks alamatnya
      _getAddressFromLatLng(position.latitude, position.longitude);
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
        _addressText = "Gagal mengunci GPS. Silakan geser manual.";
      });
    }
  }

  Future<void> _getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _addressText = "${place.street}, ${place.subLocality}, ${place.locality}";
        });
      }
    } catch (e) {
      setState(() {
        _addressText = "Lokasi terkunci. Alamat silakan konfirmasi manual.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Lokasi Pickup'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      // Trik Pengaman: Peta baru dibangun ketika loading GPS selesai,
      // sehingga initialCenter di bawah dijamin langsung bernilai lokasi Sukodadi aslimu!
      body: _isLoadingLocation 
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF005B71)),
                  SizedBox(height: 16),
                  Text("Mengunci Koordinat GPS...", style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            )
          : Stack(
              children: [
                // PETA OPENSTREETMAP
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialZoom: 16.0,
                    // DI SINI KUNCINYA: Otomatis terbuka di lokasi GPS barumu tanpa controller.move!
                    initialCenter: _selectedLocation,
                    onPositionChanged: (camera, hasGesture) {
                      final center = camera.center;
                      if (center != null) {
                        _selectedLocation = center;
                      }
                    },
                    onMapReady: () {
                      // Ambil alamat posisi saat ini begitu map siap
                      _getAddressFromLatLng(_selectedLocation.latitude, _selectedLocation.longitude);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.laundry_flutter',
                    ),
                  ],
                ),
                
                // PIN TENGAH LAYAR
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 40), 
                    child: Icon(Icons.location_pin, size: 48, color: Color(0xFF005B71)),
                  ),
                ),
                
                // PANEL DETAIL ALAMAT DI BAWAH
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))
                      ]
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Lokasi Penjemputan:',
                          style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _addressText,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context, {
                              'address': _addressText,
                              'latitude': _selectedLocation.latitude,
                              'longitude': _selectedLocation.longitude,
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF005B71),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Konfirmasi Lokasi', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}