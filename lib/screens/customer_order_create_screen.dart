import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart'; 
import '../providers/order_provider.dart';
import '../utils/order_flow_controller.dart';
import '../models/order.dart';
import '../models/service.dart';
import 'map_picker_screen.dart';
import 'order_detail_screen.dart';

class CustomerOrderCreateScreen extends StatefulWidget {
  final String? initialServiceId;
  const CustomerOrderCreateScreen({super.key, this.initialServiceId});

  @override
  State<CustomerOrderCreateScreen> createState() => _CustomerOrderCreateScreenState();
}

class _CustomerOrderCreateScreenState extends State<CustomerOrderCreateScreen> {
  final _addressController = TextEditingController(text: 'Jl. Melati No. 12, Jakarta');
  final _notesController = TextEditingController();
  String? _selectedServiceId;

  double? _selectedLatitude;
  double? _selectedLongitude;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedServiceId = widget.initialServiceId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDataLayanan();
    });
  }

  Future<void> _fetchDataLayanan() async {
    final orderProv = context.read<OrderProvider>();
    print(" Sedang mengambil data layanan langsung dari API Laravel...");
    await orderProv.loadServices();
    
    if (orderProv.services.isNotEmpty) {
      print(" Berhasil memuat ${orderProv.services.length} layanan dari backend!");
      setState(() {
        // Otomatis mengunci ke ID pertama yang datang dari backend (Misal ID '5')
        _selectedServiceId = orderProv.services.first.id;
      });
    } else {
      print(" Ambil data sukses tapi array layanan dari backend KOSONG (0 data).");
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder() async {
    if (_addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi alamat penjemputan!')),
      );
      return;
    }

    if (_selectedLatitude == null || _selectedLongitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Buka peta terlebih dahulu untuk mengunci titik koordinat GPS Anda!')),
      );
      return;
    }

    final orderProv = context.read<OrderProvider>();
    if (orderProv.services.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal! Data layanan dari database masih kosong.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
     
      Service selectedService = orderProv.services.firstWhere(
        (s) => s.id == _selectedServiceId, 
        orElse: () => orderProv.services.first
      );

      final String idLayananReal = selectedService.id;

      print("Mengirim Order Dinamis Database. ID Sah: $idLayananReal (${selectedService.name})");

      final success = await orderProv.createNewOrder(
        serviceId: idLayananReal,
        serviceName: selectedService.name,
        notes: _notesController.text.trim(),
        latitude: _selectedLatitude!,
        longitude: _selectedLongitude!,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (success) {
        OrderFlowController.status.value = OrderStatus.pending;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            contentPadding: const EdgeInsets.all(32),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Color(0xFFE8F5E9),
                  child: Icon(Icons.check_circle, size: 50, color: Color(0xFF005B71)),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Pesanan Terkonfirmasi!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1C1F24)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Mencari kurir terdekat ke lokasi Anda...',
                  style: TextStyle(color: Colors.black54, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                //sementara id 10
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // 1. Tutup popup dialog suksesnya
                      Navigator.pop(context); 

                      // Biarkan initState di DetailScreen yang mendeteksi session user login.
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OrderDetailScreen(), 
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2DAAC8),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Lacak Pesanan', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ),

              ],
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuat pesanan. Server bermasalah.')),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isSubmitting = false);
      print("Error Submit Order Screen: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProv = Provider.of<OrderProvider>(context);
    final services = orderProv.services;

    // layanan aktif 
    Service? selectedService;
    if (services.isNotEmpty) {
      selectedService = services.firstWhere(
        (s) => s.id == _selectedServiceId, 
        orElse: () => services.first
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Buat Pesanan',
          style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
               
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 12),
                          Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(color: Color(0xFF005B71), shape: BoxShape.circle),
                          ),
                          Container(width: 2, height: 40, color: Colors.grey.shade300),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'White-glove Pickup Location',
                              style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w600),
                            ),
                            TextField(
                              controller: _addressController,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                              decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const MapPickerScreen()));
                          if (result != null && result is Map<String, dynamic>) {
                            setState(() {
                              _addressController.text = result['address'];
                              _selectedLatitude = result['latitude'];
                              _selectedLongitude = result['longitude'];
                            });
                          }
                        },
                        icon: const Icon(Icons.map_outlined, color: Color(0xFF2DAAC8)),
                      ),
                    ],
                  ),
                ),
                
                const Divider(thickness: 8, color: Color(0xFFF3F4F6)),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Pilih Layanan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Color(0xFF2DAAC8)),
                        onPressed: _fetchDataLayanan, // Tombol manual check data api
                      )
                    ],
                  ),
                ),
                
                orderProv.isLoading
                    ? const SizedBox(
                        height: 130,
                        child: Center(child: CircularProgressIndicator(color: Color(0xFF005B71))),
                      )
                    : services.isEmpty
                        ? SizedBox(
                            height: 130,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.cloud_off_outlined, size: 36, color: Colors.grey),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Layanan kosong.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : SizedBox(
                            height: 130, 
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: services.length, 
                              itemBuilder: (context, index) {
                                final service = services[index];
                                final isSelected = service.id == _selectedServiceId;

                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedServiceId = service.id; 
                                    });
                                  },
                                  child: Container(
                                    width: 125,
                                    margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xFFE1F5FA) : Colors.white, 
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected ? const Color(0xFF005B71) : Colors.grey.shade300,
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),

                                    child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircleAvatar(
                                        radius: 22,
                                        backgroundColor: isSelected ? const Color(0xFF005B71) : const Color(0xFFF3F4F6),
                                        child: Icon(
                                          Icons.local_laundry_service_outlined, 
                                          size: 24, 
                                          color: isSelected ? Colors.white : const Color(0xFF2DAAC8),
                                        ),
                                      ),
                                      const SizedBox(height: 6),

                                      // NAMA LAYANAN ASLI BACKEND
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: Text(
                                          service.name, 
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                            color: isSelected ? const Color(0xFF005B71) : Colors.black87,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 2),

                                      Text(
                                        "Rp ${service.pricePerKg}/kg",
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: isSelected ? const Color(0xFF005B71) : Colors.green.shade700,
                                        ),
                                      ),
                                      // Text(
                                      //   "ID: ${service.id}", 
                                      //   style: const TextStyle(fontSize: 9, color: Colors.grey),
                                      // )
                                    ],
                                  ),

                                  ),
                                );
                              },
                            ),
                          ),

                const SizedBox(height: 8),
                const Divider(thickness: 8, color: Color(0xFFF3F4F6)),

                // CATATAN
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Catatan untuk Kurir (Opsional)',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(16)),
                        child: TextField(
                          controller: _notesController,
                          maxLines: 2,
                          decoration: const InputDecoration(hintText: 'Tolong pisahkan baju putih ya pak...', border: InputBorder.none),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 80), 
              ],
            ),
          ),
          
          //  BOTTOM BAR 
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 20, offset: const Offset(0, -5))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedService?.name ?? 'Pilih Layanan...',
                        style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const Text('Tarif menyesuaikan', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _isSubmitting || services.isEmpty ? null : _submitOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF005B71), 
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Pesan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}