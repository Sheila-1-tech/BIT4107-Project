import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite/sqflite.dart';

import 'services/auth_service.dart';
import 'services/pharmacy_service.dart';
// Screens
import 'screens/landing_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/admin_dashboard_pro.dart';
import 'screens/cart_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/order_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/medicine_details_screen.dart';
import 'screens/prescription_upload_screen.dart';
// New SQLite and API Screens
import 'services/manage_medicines_screen.dart';
import 'services/drug_lookup_screen.dart';
import 'services/medicine_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize FFI for sqflite for web
  if (kIsWeb) {
    // Use the ffi web factory in web apps (flutter run -d chrome)
    databaseFactory = databaseFactoryFfiWeb;
  }
  await AuthService.instance.init(); // Load saved user data
  await PharmacyService.instance.init(); // Load saved medicines

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => MedicineProvider()..loadMedicines(),
        ),
      ],
      child: const PharmacyApp(),
    ),
  );
}

class PharmacyApp extends StatelessWidget {
  const PharmacyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pharmacy App',
      themeMode: ThemeMode.light,

      // 🌟 START SCREEN (FLOW BEGINS HERE)
      initialRoute: '/',

      // 🎯 ROUTES (SYSTEM FLOW)
      routes: {
        '/': (context) => SplashScreen(),
        '/landing': (context) => LandingScreen(),

        // AUTH FLOW
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),

        // USER FLOW
        '/home': (context) => HomeScreen(),
        '/medicine-details': (context) => MedicineDetailsScreen(),
        '/cart': (context) => CartScreen(),
        '/checkout': (context) => CheckoutScreen(),
        '/orders': (context) => OrderScreen(),
        '/profile': (context) => ProfileScreen(),
        '/upload-prescription': (context) => PrescriptionUploadScreen(),

        // ADMIN FLOW
        '/admin': (context) => AdminDashboard(),

        // NEW DATA MANAGEMENT & NETWORKING
        '/manage-medicines': (context) => const ManageMedicinesScreen(),
        '/drug-lookup': (context) => const DrugLookupScreen(),
      },

      // 🎨 THEME (you can improve later)
      theme: ThemeData(
        useMaterial3: true,
        colorScheme:
            ColorScheme.fromSeed(
              seedColor: const Color(0xFF1B8F4A),
              brightness: Brightness.light,
            ).copyWith(
              primary: const Color(0xFF1B8F4A),
              secondary: const Color(0xFF1F6D4A),
              surface: Colors.white,
            ),
        scaffoldBackgroundColor: const Color(0xFFF4F7F6),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF103826),
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            color: Color(0xFF103826),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 8,
          shadowColor: const Color(0xFF1B8F4A).withValues(alpha: 0.08),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFFE4ECE8), width: 1.5),
          ),
          color: Colors.white,
          surfaceTintColor: Colors.white,
        ),
        listTileTheme: ListTileThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          tileColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
          iconColor: const Color(0xFF1B8F4A),
          textColor: const Color(0xFF2D3B34),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFE4ECE8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFF1B8F4A), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1B8F4A),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
