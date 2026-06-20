import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart'; 
import '../providers/order_provider.dart';
import '../models/service.dart';
import '../models/order.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'order_detail_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  String _currentAddress = 'Mencari lokasi...';
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();

    _fetchCurrentLocation();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadServices();
     
      final auth = context.read<AuthProvider>();
      print("======= DEBUG PRINT AUTH DATA USER =======");
      print("Isi auth.currentUser: ${auth.currentUser?.name}");
      print("==========================================");
    });
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _currentAddress = 'GPS mati';
          _isLoadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _currentAddress = 'Akses ditolak';
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _currentAddress = 'Akses ditolak permanen';
          _isLoadingLocation = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        
        // Deteksi jika ini adalah lokasi default emulator (di luar Indonesia)
        if (place.isoCountryCode != 'ID' && place.country?.toLowerCase() != 'indonesia') {
          print("Posisi simulator/perangkat di luar Indonesia. Menggunakan lokasi default.");
          setState(() {
            _currentAddress = 'Jl. Veteran No. 190, Lamongan';
            _isLoadingLocation = false;
          });
          return;
        }

        setState(() {
          _currentAddress = '${place.street ?? place.name}, ${place.locality ?? place.subAdministrativeArea}';
          _isLoadingLocation = false;
        });
      } else {
        setState(() {
          _currentAddress = 'Lokasi tidak ditemukan';
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      print("Error fetching location in Home: $e");
      setState(() {
        _currentAddress = 'Gagal memuat lokasi';
        _isLoadingLocation = false;
      });
    }
  }

  String getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  String _getActiveOrderText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Mencari kurir terdekat...\nMenunggu konfirmasi kurir.';
      case OrderStatus.kurir_menuju_lokasi:
        return 'Kurir menuju lokasi penjemputan\nMohon bersiap.';
      case OrderStatus.dibawa_kurir_ke_laundry:
        return 'Kurir membawa pakaian ke laundry\nSedang dalam perjalanan.';
      case OrderStatus.sedang_dicuci:
        return 'Pakaian Anda sedang dicuci\nMenunggu proses selesai.';
      case OrderStatus.siap_dikirim:
        return 'Pakaian siap dikirim kembali\nMenunggu kurir mengambil pakaian.';
      case OrderStatus.proses_pengantaran:
        return 'Kurir sedang mengantar pakaian\nEstimasi tiba 10 menit lagi.';
      case OrderStatus.selesai:
        return 'Pesanan telah selesai!\nTerima kasih atas pesanan Anda.';
      case OrderStatus.cancelled:
        return 'Pesanan dibatalkan.\nSilakan pesan kembali.';
      default:
        return 'Memproses pesanan Anda...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProv = Provider.of<AuthProvider>(context);
    final orderProv = Provider.of<OrderProvider>(context);
    final listLayanan = orderProv.services;

    final String namaUserLogin = authProv.currentUser?.name ?? 'Nama Pengguna';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), 
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/profile'),
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: const Color(0xFF005B71),
                        child: Text(
                          namaUserLogin.isNotEmpty ? namaUserLogin.substring(0, 1).toUpperCase() : 'U',
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            getGreeting(), 
                            style: const TextStyle(color: Colors.black54, fontSize: 14),
                          ),
                          Text(
                            namaUserLogin, 
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 25),

                // LOCATION BAR
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: Color(0xFF2DAAC8)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _currentAddress, 
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_isLoadingLocation)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2DAAC8)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),


                if (orderProv.currentOrder != null)
                  Container(
                    width: double.infinity,
                    clipBehavior: Clip.antiAlias, 
                    decoration: BoxDecoration(
                    color: const Color(0xFFE1F5FA),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Stack( 
                    children: [
                      
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Pesanan Aktif', 
                              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF004D61), fontSize: 16)),
                            const SizedBox(height: 6),
                            Text(_getActiveOrderText(orderProv.currentOrder!.status), 
                              style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/detail_pesanan');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white, 
                                foregroundColor: const Color(0xFF2DAAC8), 
                                elevation: 0, 
                                side: const BorderSide(color: Color(0xFF2DAAC8), width: 1.5),
                                minimumSize: const Size(100, 32), 
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text(
                                'Lihat Detail', 
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            )
                          ],
                        ),
                      ),

                      Positioned(
                        right: 15, 
                        bottom: 10, 
                        child: Image.asset(
                          'assets/images/kurir.png', 
                          height: 110, 
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 25),

                const Text(
                  'Layanan Laundry', 
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF004D61)),
                ),
                const SizedBox(height: 16),

                orderProv.isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(color: Color(0xFF005B71)),
                        ),
                      )
                    : listLayanan.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                            child: const Center(
                              child: Text(
                                'Gagal memuat layanan.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                              ),
                            ),
                          )
                        : GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 1.2,
                            ),
                            itemCount: listLayanan.length,
                            itemBuilder: (context, index) {
                              final Service layanan = listLayanan[index];
                              return _buildDynamicCategoryCard(context, layanan);
                            },
                          ),

                const SizedBox(height: 100), 
              ],
            ),
          ),
        ),
      ),

      // FLOATING ACTION BUTTON
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2DAAC8),
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        elevation: 6,
        onPressed: () => Navigator.pushNamed(context, '/order_create'),
        child: const Icon(Icons.add, size: 32),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 10,
        color: Colors.white,
        elevation: 20,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(icon: const Icon(Icons.home, color: Color(0xFF005B71)), onPressed: () {}),
              IconButton(icon: const Icon(Icons.receipt_long, color: Colors.grey), 
                onPressed: () => Navigator.pushNamed(context, '/order_list')),
              const SizedBox(width: 40), 
              IconButton(icon: const Icon(Icons.notifications_none, color: Colors.grey), 
                onPressed: () => Navigator.pushNamed(context, '/notifications')),
              IconButton(icon: const Icon(Icons.person_outline, color: Colors.grey), 
                onPressed: () => Navigator.pushNamed(context, '/profile')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicCategoryCard(BuildContext context, Service layanan) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/order_create', arguments: layanan.id);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 20,
              backgroundColor: Color(0xFFE1F5FA),
              child: Icon(Icons.local_laundry_service_outlined, color: Color(0xFF005B71), size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              layanan.name, 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Rp ${layanan.pricePerKg}/kg',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.green.shade700),
                ),
                const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.black38),
              ],
            )
          ],
        ),
      ),
    );
  }
}