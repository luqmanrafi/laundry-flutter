import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart'; 
import '../providers/order_provider.dart';
import '../models/service.dart';
import 'order_detail_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadServices();
     
      final auth = context.read<AuthProvider>();
      print("======= DEBUG PRINT AUTH DATA USER =======");
      print("Isi auth.user: ${(auth as dynamic).user}");
      try {
        print("Coba panggil nama langsung: ${(auth as dynamic).name}");
        print("Coba panggil nama via user: ${(auth as dynamic).user?.name}");
      } catch(e) {
        print("Error pas nyoba ngeprint nama: $e");
      }
      print("==========================================");
    });
  }

  String getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
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
                
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Color(0xFF005B71),
                      child: Icon(Icons.person_rounded, color: Colors.white, size: 32),
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
                    children: const [
                      Icon(Icons.location_on_outlined, color: Color(0xFF2DAAC8)),
                      SizedBox(width: 12),
                      Text('Jl. Raya Basuki Rahmat', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),


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
                            const Text('Kurir menuju lokasi Anda\nEstimasi tiba 10 menit lagi', 
                              style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.4)),
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