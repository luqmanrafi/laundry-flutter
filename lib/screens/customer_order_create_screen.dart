import 'package:flutter/material.dart';
import '../utils/order_flow_controller.dart';
import '../models/order.dart';
import '../models/service.dart';
import '../utils/dummy_data.dart';

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
  DateTime? _pickupDate;
  TimeOfDay? _pickupTime;

  @override
  void initState() {
    super.initState();
    _selectedServiceId = widget.initialServiceId ?? dummyServices.first.id;
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF005B71), 
              onPrimary: Colors.white, 
              onSurface: Colors.black, 
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() {
        _pickupDate = date;
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF005B71), 
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      setState(() {
        _pickupTime = time;
      });
    }
  }

  void _submitOrder() {
    if (_pickupDate == null || _pickupTime == null || _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi alamat dan jadwal penjemputan!')),
      );
      return;
    }

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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); 
                  Navigator.pushReplacementNamed(context, '/detail_pesanan');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2DAAC8),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Lacak Pesanan', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForService(String icon) {
    switch (icon) {
      case 'bolt': return Icons.water_drop_outlined;
      case 'iron': return Icons.iron;
      case 'local_laundry_service': default: return Icons.local_laundry_service_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    Service selectedService = dummyServices.firstWhere(
      (s) => s.id == _selectedServiceId, 
      orElse: () => dummyServices.first
    );

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
                // === LOKASI PENJEMPUTAN ===
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
                            decoration: const BoxDecoration(
                              color: Color(0xFF005B71),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 2,
                            height: 40,
                            color: Colors.grey.shade300,
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Lokasi Penjemputan',
                              style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w600),
                            ),
                            TextField(
                              controller: _addressController,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                              decoration: const InputDecoration(
                                hintText: 'Masukkan alamat penjemputan',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.map_outlined, color: Color(0xFF2DAAC8)),
                      ),
                    ],
                  ),
                ),
                
                const Divider(thickness: 8, color: Color(0xFFF3F4F6)),

                // === LAYANAN ===
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: const Text(
                    'Pilih Layanan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: dummyServices.length,
                    itemBuilder: (context, index) {
                      final service = dummyServices[index];
                      final isSelected = service.id == _selectedServiceId;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedServiceId = service.id;
                          });
                        },
                        child: Container(
                          width: 110,
                          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF005B71) : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _iconForService(service.icon),
                                color: isSelected ? const Color(0xFF005B71) : Colors.grey.shade600,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                service.name,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: isSelected ? const Color(0xFF005B71) : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 8),
                const Divider(thickness: 8, color: Color(0xFFF3F4F6)),

                // === WAKTU JEMPUT ===
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: const Text(
                    'Jadwal Penjemputan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  leading: const Icon(Icons.calendar_today_rounded, color: Color(0xFF2DAAC8)),
                  title: Text(
                    _pickupDate != null 
                        ? "${_pickupDate!.day}/${_pickupDate!.month}/${_pickupDate!.year}"
                        : 'Pilih Tanggal',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _selectDate,
                ),
                const Divider(height: 1, indent: 60),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  leading: const Icon(Icons.access_time_rounded, color: Color(0xFF2DAAC8)),
                  title: Text(
                    _pickupTime != null 
                        ? "${_pickupTime!.hour.toString().padLeft(2, '0')}:${_pickupTime!.minute.toString().padLeft(2, '0')}"
                        : 'Pilih Waktu',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _selectTime,
                ),

                const Divider(thickness: 8, color: Color(0xFFF3F4F6)),

                // === CATATAN ===
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
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TextField(
                          controller: _notesController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            hintText: 'Tolong pisahkan baju putih ya pak...',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 80), // Pad for bottom sheet
              ],
            ),
          ),
          
          // === STICKY BOTTOM BAR ===
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedService.name,
                        style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const Text(
                        'Tarif menyesuaikan',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _submitOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF005B71), // Grab often uses their primary dark green
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    minimumSize: Size.zero, // Override theme's Size.fromHeight(56) which causes infinite width
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('Pesan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
