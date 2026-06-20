import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'map_picker_screen.dart';

class SavedAddress {
  final String id;
  final String label;
  final String address;
  final double latitude;
  final double longitude;

  SavedAddress({
    required this.id,
    required this.label,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
      };

  factory SavedAddress.fromJson(Map<String, dynamic> json) => SavedAddress(
        id: json['id']?.toString() ?? '',
        label: json['label']?.toString() ?? '',
        address: json['address']?.toString() ?? '',
        latitude: double.tryParse(json['latitude']?.toString() ?? '0.0') ?? 0.0,
        longitude: double.tryParse(json['longitude']?.toString() ?? '0.0') ?? 0.0,
      );
}

class SavedAddressesScreen extends StatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  List<SavedAddress> _addresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson = prefs.getStringList('saved_addresses') ?? [];
      
      // Fallback default addresses if empty
      if (listJson.isEmpty) {
        _addresses = [
          SavedAddress(
            id: '1',
            label: 'Rumah',
            address: 'Jl. Melati No. 12, Kel. Sukodadi, Kec. Sukodadi, Lamongan',
            latitude: -7.0934,
            longitude: 112.3164,
          ),
          SavedAddress(
            id: '2',
            label: 'Kantor',
            address: 'Grand Slipi Tower Lt. 42, Palmerah, Jakarta Barat',
            latitude: -6.2001,
            longitude: 106.7990,
          ),
        ];
        await _saveAddresses();
      } else {
        _addresses = listJson
            .map((item) => SavedAddress.fromJson(jsonDecode(item)))
            .toList();
      }
    } catch (e) {
      print("Error loading addresses: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAddresses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson = _addresses
          .map((item) => jsonEncode(item.toJson()))
          .toList();
      await prefs.setStringList('saved_addresses', listJson);
    } catch (e) {
      print("Error saving addresses: $e");
    }
  }

  Future<void> _deleteAddress(String id) async {
    setState(() {
      _addresses.removeWhere((item) => item.id == id);
    });
    await _saveAddresses();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alamat berhasil dihapus.'),
          backgroundColor: Color(0xFF005B71),
        ),
      );
    }
  }

  Future<void> _addOrEditAddress({SavedAddress? existing}) async {
    final isEdit = existing != null;
    final labelController = TextEditingController(text: existing?.label ?? '');
    final addressController = TextEditingController(text: existing?.address ?? '');
    double selectedLat = existing?.latitude ?? -7.0934;
    double selectedLng = existing?.longitude ?? 112.3164;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEdit ? 'Ubah Alamat' : 'Tambah Alamat Baru',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF005B71)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Label Alamat (e.g. Rumah, Kantor)
                  const Text('Label Alamat', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: labelController,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: 'Misal: Rumah, Kantor, Kos',
                      filled: true,
                      fillColor: const Color(0xFFF4F7F5),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Alamat Lengkap
                  const Text('Alamat Lengkap', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: addressController,
                    maxLines: 2,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: 'Klik pilih lokasi di peta atau isi manual...',
                      filled: true,
                      fillColor: const Color(0xFFF4F7F5),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tombol Buka Peta
                  OutlinedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MapPickerScreen()),
                      );
                      if (result != null && result is Map<String, dynamic>) {
                        setModalState(() {
                          addressController.text = result['address'];
                          selectedLat = result['latitude'];
                          selectedLng = result['longitude'];
                        });
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF2DAAC8), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.map_outlined, color: Color(0xFF2DAAC8)),
                    label: const Text(
                      'Pilih Lokasi dari Peta',
                      style: TextStyle(color: Color(0xFF2DAAC8), fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tombol Simpan
                  ElevatedButton(
                    onPressed: () {
                      if (labelController.text.trim().isEmpty || addressController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Tolong lengkapi label dan alamat!')),
                        );
                        return;
                      }

                      setState(() {
                        if (isEdit) {
                          final index = _addresses.indexWhere((item) => item.id == existing.id);
                          if (index != -1) {
                            _addresses[index] = SavedAddress(
                              id: existing.id,
                              label: labelController.text.trim(),
                              address: addressController.text.trim(),
                              latitude: selectedLat,
                              longitude: selectedLng,
                            );
                          }
                        } else {
                          _addresses.add(
                            SavedAddress(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              label: labelController.text.trim(),
                              address: addressController.text.trim(),
                              latitude: selectedLat,
                              longitude: selectedLng,
                            ),
                          );
                        }
                      });

                      _saveAddresses();
                      Navigator.pop(context);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isEdit ? 'Alamat berhasil diperbarui.' : 'Alamat baru berhasil ditambahkan.'),
                          backgroundColor: const Color(0xFF005B71),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF005B71),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Simpan Alamat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        title: const Text(
          'Alamat Tersimpan',
          style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF005B71)),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF005B71),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF005B71)))
          : _addresses.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_off_outlined, size: 80, color: Colors.grey.shade400),
                        const SizedBox(height: 24),
                        const Text(
                          'Belum Ada Alamat',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF005B71)),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tambahkan alamat penjemputan favorit Anda untuk mempercepat pemesanan laundry.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _addresses.length,
                  itemBuilder: (context, index) {
                    final item = _addresses[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 8, offset: Offset(0, 2))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2DAAC8).withAlpha(30),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  item.label,
                                  style: const TextStyle(
                                    color: Color(0xFF2DAAC8),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: Colors.grey, size: 22),
                                    onPressed: () => _addOrEditAddress(existing: item),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Hapus Alamat?'),
                                          content: Text('Apakah Anda yakin ingin menghapus alamat "${item.label}"?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                _deleteAddress(item.id);
                                              },
                                              child: const Text('Hapus', style: TextStyle(color: Colors.redAccent)),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on_outlined, color: Color(0xFF005B71), size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.address,
                                  style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF005B71),
        foregroundColor: Colors.white,
        onPressed: () => _addOrEditAddress(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Alamat', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
