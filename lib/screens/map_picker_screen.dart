import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart'; 
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
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

      if (position.latitude >= -11.0 && position.latitude <= 6.0 &&
          position.longitude >= 95.0 && position.longitude <= 141.0) {
        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });
        _getAddressFromLatLng(position.latitude, position.longitude);
      } else {
        setState(() {
          _selectedLocation = const LatLng(-7.1286128, 112.4210956);
          _isLoadingLocation = false;
        });
        _getAddressFromLatLng(-7.1286128, 112.4210956);
      }
    } catch (e) {
      setState(() {
        _selectedLocation = const LatLng(-7.1286128, 112.4210956);
        _isLoadingLocation = false;
      });
      _getAddressFromLatLng(-7.1286128, 112.4210956);
    }
  }

  Future<void> _getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _addressText = "${place.street}, ${place.subLocality}, ${place.locality}";
          // Optionally fill search bar with current locality/street
        });
      }
    } catch (e) {
      setState(() {
        _addressText = "Lokasi terkunci. Alamat silakan konfirmasi manual.";
      });
    }
  }

  Future<void> _searchAddress(String query) async {
    if (query.trim().isEmpty) return;
    
    // Tampilkan loading di text alamat bawah sementara mencari
    setState(() {
      _addressText = "Mencari lokasi '$query'...";
    });

    try {
      // Menggunakan OpenStreetMap Nominatim API agar jauh lebih akurat (terutama di iOS/Apple Maps yang sering meleset di Indonesia)
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1&countrycodes=id');
      final response = await http.get(url, headers: {'User-Agent': 'LaundryApp/1.0'});
      
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          final newCenter = LatLng(lat, lon);
          
          _mapController.move(newCenter, 16.0);
          setState(() {
            _selectedLocation = newCenter;
          });
          
          _getAddressFromLatLng(lat, lon);
          return;
        }
      }

      // Fallback ke geocoding bawaan jika Nominatim gagal
      List<Location> locations = await locationFromAddress("$query, Indonesia");
      if (locations.isNotEmpty) {
        final loc = locations.first;
        final newCenter = LatLng(loc.latitude, loc.longitude);
        
        _mapController.move(newCenter, 16.0);
        setState(() {
          _selectedLocation = newCenter;
        });
        
        _getAddressFromLatLng(loc.latitude, loc.longitude);
      } else {
        throw Exception("Not found");
      }
    } catch (e) {
      setState(() {
        _addressText = "Alamat tidak ditemukan. Geser peta manual.";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alamat tidak ditemukan, silakan coba nama kota/kabupaten spesifik.')),
      );
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
                        
                        // Tampilkan teks loading sementara saat menggeser peta
                        if (_addressText != "Mencari alamat...") {
                          setState(() {
                            _addressText = "Mencari alamat...";
                          });
                        }

                        // Debounce pemanggilan API geocoding agar tidak terkena rate limit
                        _debounceTimer?.cancel();
                        _debounceTimer = Timer(const Duration(milliseconds: 800), () {
                          _getAddressFromLatLng(center.latitude, center.longitude);
                        });
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
                
                // KOLOM PENCARIAN (SEARCH BAR)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: _searchAddress,
                      decoration: InputDecoration(
                        hintText: 'Ketik nama jalan atau tempat...',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF005B71)),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                          },
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
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