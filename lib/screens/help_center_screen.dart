import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'Semua';
  String _searchQuery = '';

  final List<Map<String, String>> _faqData = [
    {
      'category': 'Layanan',
      'question': 'Berapa lama proses pengerjaan laundry?',
      'answer': 'Proses pengerjaan untuk layanan Cuci Kering dan Cuci Setrika standar adalah 2-3 hari. Sedangkan untuk layanan Cuci Express diselesaikan dalam kurun waktu 12-24 jam sejak kurir mengambil pakaian Anda.',
    },
    {
      'category': 'Layanan',
      'question': 'Bagaimana cara melacak posisi kurir?',
      'answer': 'Anda dapat melacak status pesanan secara real-time pada detail pesanan Anda. Ketika kurir dalam proses penjemputan atau pengantaran, status akan otomatis berpindah ke "Membawa ke Laundry" atau "Proses Pengantaran".',
    },
    {
      'category': 'Pembayaran',
      'question': 'Apakah tarif ongkir sudah termasuk dalam harga layanan?',
      'answer': 'Tidak, tarif ongkir dihitung secara spasial berdasarkan jarak antara lokasi penjemputan Anda dengan outlet laundry terdekat kami. Total biaya penjemputan akan otomatis terkalkulasi sebelum Anda melakukan konfirmasi pesanan.',
    },
    {
      'category': 'Pembayaran',
      'question': 'Bagaimana cara melakukan pembayaran?',
      'answer': 'Setelah pakaian ditimbang di outlet oleh kurir kami, tagihan final akan dikirimkan ke aplikasi Anda. Anda dapat membayar menggunakan pembayaran QRIS, Transfer Bank, atau E-Wallet melalui gerbang simulasi pembayaran di dalam aplikasi.',
    },
    {
      'category': 'Kendala',
      'question': 'Apa yang terjadi jika baju saya hilang atau rusak?',
      'answer': 'Keamanan pakaian Anda adalah prioritas kami. Jika terjadi kerusakan atau kehilangan yang disebabkan oleh pihak kami, kami menyediakan jaminan ganti rugi hingga 10 kali lipat dari harga tarif cuci pakaian yang rusak/hilang tersebut. Silakan hubungi admin via WhatsApp untuk klaim garansi.',
    },
    {
      'category': 'Layanan',
      'question': 'Apakah ada batas berat minimal untuk pemesanan?',
      'answer': 'Minimal pemesanan untuk laundry kiloan adalah 1 kg. Jika berat total pakaian Anda di bawah 1 kg, tagihan biaya akan tetap dihitung seharga tarif minimal 1 kg.',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label berhasil disalin ke papan klip!'),
        backgroundColor: const Color(0xFF005B71),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter FAQs based on search query and category
    final filteredFaqs = _faqData.where((faq) {
      final matchesCategory = _selectedCategory == 'Semua' || faq['category'] == _selectedCategory;
      final matchesSearch = faq['question']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          faq['answer']!.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        title: const Text(
          'Pusat Bantuan',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search Box
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 8, offset: Offset(0, 2))],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Cari pertanyaan Anda...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF2DAAC8)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Category Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Semua', 'Layanan', 'Pembayaran', 'Kendala'].map((category) {
                  final isSelected = _selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        }
                      },
                      selectedColor: const Color(0xFF005B71),
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF005B71),
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // FAQ Title
            const Text(
              'Pertanyaan Populer (FAQ)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF005B71)),
            ),
            const SizedBox(height: 12),

            // FAQ List
            filteredFaqs.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: const Center(
                      child: Text(
                        'Pertanyaan tidak ditemukan. Coba gunakan kata kunci lain.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                    ),
                  )
                : Column(
                    children: filteredFaqs.map((faq) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFE1F5FA),
                              child: Icon(Icons.help_outline, color: Color(0xFF2DAAC8)),
                            ),
                            title: Text(
                              faq['question']!,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 14),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                                child: Text(
                                  faq['answer']!,
                                  style: const TextStyle(color: Colors.black54, fontSize: 14, height: 1.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
            const SizedBox(height: 32),

            // Support Contact Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF005B71), Color(0xFF2DAAC8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Masih Butuh Bantuan?',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tim customer service kami siap melayani dan menjawab keluhan Anda 24/7.',
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 20),

                  // WhatsApp
                  _contactTile(
                    icon: Icons.chat_outlined,
                    label: 'WhatsApp Admin',
                    value: '+62 812-3456-7890',
                    onCopy: () => _copyToClipboard('+6281234567890', 'Nomor WhatsApp Admin'),
                  ),
                  const SizedBox(height: 12),

                  // Email
                  _contactTile(
                    icon: Icons.email_outlined,
                    label: 'Email Layanan',
                    value: 'support@washweswos.com',
                    onCopy: () => _copyToClipboard('support@washweswos.com', 'Alamat Email Layanan'),
                  ),
                  const SizedBox(height: 12),

                  // Hotline
                  _contactTile(
                    icon: Icons.phone_in_talk_outlined,
                    label: 'Hotline Bebas Pulsa',
                    value: '021-8899-7766',
                    onCopy: () => _copyToClipboard('021-8899-7766', 'Nomor Hotline Bebas Pulsa'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _contactTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onCopy,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(40),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(icon, color: const Color(0xFF005B71)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.white, size: 20),
            onPressed: onCopy,
          ),
        ],
      ),
    );
  }
}
