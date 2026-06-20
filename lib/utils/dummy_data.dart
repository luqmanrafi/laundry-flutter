import '../models/user.dart';
import '../models/service.dart';
import '../models/order.dart';
import '../models/invoice.dart';

final dummyUsers = [
  User(id: 'u1', name: 'Andi', email: 'andi@mail.com', role: UserRole.pelanggan, avatarUrl: null),
  User(id: 'u2', name: 'Budi', email: 'budi@mail.com', role: UserRole.kurir, avatarUrl: null),
];

List<Service> dummyServices = [
  Service(id: 's1', name: 'Cuci Ekspres', description: 'Selesai 6 jam', pricePerKg: 12000),
  Service(id: 's2', name: 'Cuci Kering', description: 'Cuci + Kering', pricePerKg: 9000),
  Service(id: 's3', name: 'Cuci Setrika', description: 'Cuci + Setrika', pricePerKg: 10000),
  Service(id: 's4', name: 'Setrika Saja', description: 'Setrika saja', pricePerKg: 7000),
];

final dummyOrders = [
  Order(
    id: 'o1',
    customer: dummyUsers[0],
    courier: dummyUsers[1],
    service: dummyServices[0],
    pickupDate: DateTime.now().add(const Duration(days: 1)),
    pickupAddress: 'Jl. Mawar No. 1',
    weight: 3.5,
    // KUNCI EMAS: Ubah dari .pickup ke status baru sesuai database Laravel backend
    status: OrderStatus.dibawa_kurir_ke_laundry, 
    invoice: Invoice(
      id: 'i1',
      orderId: 'o1',
      weight: 3.5,
      pricePerKg: 12000,
      totalPrice: 42000,
      createdAt: DateTime.now(),
    ),
  ),
  Order(
    id: 'o2',
    customer: dummyUsers[0],
    courier: dummyUsers[1],
    service: dummyServices[2],
    pickupDate: DateTime.now().add(const Duration(days: 2)),
    pickupAddress: 'Jl. Melati No. 2',
    weight: null,
    status: OrderStatus.pending,
    invoice: null,
  ),
];