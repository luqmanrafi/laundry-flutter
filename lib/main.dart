import 'dart:ui';
import 'package:flutter/material.dart';
import 'screens/signup_screen.dart';
import 'screens/login_screen.dart';
import 'screens/customer_home_screen.dart';
import 'screens/courier_home_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/order_list_screen.dart';
import 'screens/order_detail_screen.dart';
import 'screens/invoice_create_screen.dart';
import 'screens/weight_input_screen.dart';
import 'screens/customer_order_detail_screen.dart';
import 'screens/customer_order_create_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/notification_screen.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/order_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }
}

Future<void> main() async {
  // 1. WAJIB: Inisialisasi binding Flutter untuk proses async
  WidgetsFlutterBinding.ensureInitialized();

  // 2. WAJIB: Load file .env sebelum app dijalankan
  try {
    await dotenv.load(fileName: ".env");
    print("Berhasil memuat .env");
  } catch (e) {
    print("Gagal memuat .env: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: const WashWeswosApp(),
    ),
  );
}

// void main() {
//   runApp(
//     MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => AuthProvider()),
//         ChangeNotifierProvider(create: (_) => OrderProvider()),
//       ],
//       child: const WashWeswosApp(),
//     ),
//   );
// }

class WashWeswosApp extends StatelessWidget {
  const WashWeswosApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF005B71);
    const accent = Color(0xFF2DAAC8);

    return MaterialApp(
      scrollBehavior: AppScrollBehavior(),
      debugShowCheckedModeBanner: false,
      title: 'WashWeswos Laundry',
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: primary,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          secondary: accent,
          surface: Colors.white,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA), // Very light clean background
        fontFamily: 'Montserrat',
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            side: BorderSide(color: Colors.grey.shade200, width: 1.5),
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Color(0xFFF6F8FB),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          foregroundColor: Color(0xFF1C1F24),
          titleTextStyle: TextStyle(
            color: Color(0xFF1C1F24),
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFE4E6EA),
          hintStyle: const TextStyle(color: Color(0xFF7B7D81)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: accent, width: 1.5),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            minimumSize: const Size(88, 56), // Use a fixed minimum height but allow width to shrink
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      initialRoute: '/welcome',
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/signup': (context) => const SignupScreen(),
        '/login': (context) => const LoginScreen(),
        '/customer_home': (context) => const CustomerHomeScreen(),
        '/courier_home': (context) => const CourierHomeScreen(),
        '/order_list': (context) => const OrderListScreen(),
        '/order_detail': (context) => const OrderDetailScreen(),
        '/invoice_create': (context) => const InvoiceCreateScreen(),
        '/weight_input': (context) => const WeightInputScreen(),
        '/detail_pesanan': (context) => const CustomerOrderDetailScreen(),
        '/order_create': (context) => const CustomerOrderCreateScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/notifications': (context) => const NotificationScreen(),
      },
    );
  }
}
