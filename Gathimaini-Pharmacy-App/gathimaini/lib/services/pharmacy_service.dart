import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/medicine.dart';
import '../models/order.dart';
import '../models/prescription.dart';
import '../models/user.dart';
import '../services/database_helper.dart';

/// In-memory pharmacy service providing medicine data, cart management,
/// and basic order placement logic.
class PharmacyService {
  PharmacyService._private();
  static final PharmacyService instance = PharmacyService._private();

  List<Medicine> _medicines = [];
  List<Prescription> _prescriptions = [];
  List<Order> _orders = [];

  /// Loads medicines from local storage or sets up defaults.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final ordersJson = prefs.getString('orders_data');
    if (ordersJson != null) {
      final List<dynamic> decoded = jsonDecode(ordersJson) as List<dynamic>;
      _orders = decoded
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final rxJson = prefs.getString('prescriptions_data');
    if (rxJson != null) {
      final List<dynamic> decoded = jsonDecode(rxJson) as List<dynamic>;
      _prescriptions = decoded
          .map((e) => Prescription.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final cartJson = prefs.getString('cart_data');
    if (cartJson != null) {
      try {
        final Map<String, dynamic> decoded =
            jsonDecode(cartJson) as Map<String, dynamic>;
        _cart.clear();
        decoded.forEach((k, v) => _cart[k] = v as int);
      } catch (_) {}
    }

    try {
      _medicines = await DatabaseHelper.instance.getAllMedicines();
      if (_medicines.isEmpty) {
        final defaultMedicines = <Medicine>[
          const Medicine(
            id: 'med_001',
            name: 'Paracetamol 500mg',
            description: 'Pain reliever and fever reducer.',
            price: 399.0,
            rating: 4.5,
            category: 'Pain relief',
            imageUrl:
                'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?q=80&w=400&auto=format&fit=crop',
            stockQuantity: 100,
          ),
          const Medicine(
            id: 'med_002',
            name: 'Amoxicillin 250mg',
            description: 'Antibiotic for bacterial infections.',
            price: 1250.0,
            rating: 4.2,
            category: 'Antibiotics',
            imageUrl:
                'https://images.unsplash.com/photo-1628771065518-0d82f1938462?q=80&w=400&auto=format&fit=crop',
            stockQuantity: 50,
          ),
          const Medicine(
            id: 'med_003',
            name: 'Cetirizine 10mg',
            description: 'Allergy relief (antihistamine).',
            price: 625.0,
            rating: 4.1,
            category: 'Allergy',
            imageUrl:
                'https://images.unsplash.com/photo-1550572017-edb9bdf7c558?q=80&w=400&auto=format&fit=crop',
            stockQuantity: 75,
          ),
        ];

        for (final m in defaultMedicines) {
          await DatabaseHelper.instance.insertMedicine(m);
        }
        _medicines = await DatabaseHelper.instance.getAllMedicines();
      }

      await _ensureSpecialOfferMedicines();
      _emitMedicines();
    } catch (e) {
      print('Error initializing SQLite DB in PharmacyService: $e');
    }
  }

  Future<void> _savePrescriptions() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(
      _prescriptions.map((p) => p.toJson()).toList(),
    );
    await prefs.setString('prescriptions_data', encoded);
  }

  Future<void> _saveOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_orders.map((o) => o.toJson()).toList());
    await prefs.setString('orders_data', encoded);
  }

  Future<void> _ensureSpecialOfferMedicines() async {
    const specials = <Medicine>[
      Medicine(
        id: 'special_wellness_pack',
        name: 'Wellness Pack',
        description: 'Essential vitamins + hydration support',
        price: 1890.0,
        rating: 4.7,
        category: 'Special offer',
        stockQuantity: 20,
        imageUrl:
            'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?q=80&w=400&auto=format&fit=crop',
      ),
      Medicine(
        id: 'special_family_first_aid_kit',
        name: 'Family First Aid Kit',
        description: 'Everyday care bundle for home and travel',
        price: 2420.0,
        rating: 4.8,
        category: 'Limited time',
        stockQuantity: 15,
        imageUrl:
            'https://images.unsplash.com/photo-1603398938378-e54eab446dde?q=80&w=400&auto=format&fit=crop',
      ),
    ];

    for (final special in specials) {
      final exists = _medicines.any((m) => m.id == special.id);
      if (!exists) {
        await DatabaseHelper.instance.insertMedicine(special);
        _medicines.add(special);
      }
    }
  }

  List<Medicine> get allMedicines => List.unmodifiable(_medicines);

  // --- Cart (medicineId -> quantity) ---
  final Map<String, int> _cart = <String, int>{};

  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cart_data', jsonEncode(_cart));
  }

  /// Returns a list of `OrderItem` representing the current cart contents.
  List<OrderItem> get cartItems {
    final List<OrderItem> items = [];
    for (final entry in _cart.entries) {
      final med = _medicines.firstWhere(
        (m) => m.id == entry.key,
        orElse: () => throw StateError('Medicine not found: ${entry.key}'),
      );
      items.add(
        OrderItem(
          medicineId: med.id,
          name: med.name,
          unitPrice: med.price,
          quantity: entry.value,
        ),
      );
    }
    return items;
  }

  double get cartSubtotal {
    return cartItems.fold(0.0, (s, it) => s + it.subtotal);
  }

  bool isInCart(String medicineId) => _cart.containsKey(medicineId);

  void addToCart(String medicineId, {int quantity = 1}) {
    if (quantity <= 0) return;
    _cart.update(medicineId, (q) => q + quantity, ifAbsent: () => quantity);
    _saveCart();
  }

  void updateCartQuantity(String medicineId, int quantity) {
    if (quantity <= 0) {
      _cart.remove(medicineId);
    } else {
      _cart[medicineId] = quantity;
    }
    _saveCart();
  }

  void removeFromCart(String medicineId) {
    _cart.remove(medicineId);
    _saveCart();
  }

  void clearCart() {
    _cart.clear();
    _saveCart();
  }

  // --- Orders ---
  final StreamController<List<Order>> _ordersController =
      StreamController<List<Order>>.broadcast();

  Stream<List<Order>> get ordersStream => _ordersController.stream;

  List<Order> get allOrders => List.unmodifiable(_orders);

  List<Order> get pendingOrders => _orders
      .where(
        (o) =>
            o.status == OrderStatus.placed ||
            o.status == OrderStatus.processing,
      )
      .toList(growable: false);

  void _emitOrders() {
    try {
      _ordersController.add(List.unmodifiable(_orders));
    } catch (_) {}
  }

  List<Order> ordersForUser(String userId) =>
      _orders.where((o) => o.userId == userId).toList(growable: false);

  /// Places an order for the current cart on behalf of [user]. Returns the created [Order].
  Future<Order> placeOrderForUser(User user) async {
    if (_cart.isEmpty) {
      throw StateError('Cart is empty');
    }

    await Future.delayed(const Duration(milliseconds: 600));

    final items = cartItems;
    final subtotal = items.fold(0.0, (s, it) => s + it.subtotal);
    const deliveryFee = 299.0;
    final total = subtotal + deliveryFee;

    final order = Order(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: user.id,
      items: items,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      total: total,
      status: OrderStatus.placed,
      createdAt: DateTime.now(),
      deliveryAt: null,
    );

    _orders.insert(0, order);
    await _saveOrders();
    _emitOrders();
    clearCart();

    return order;
  }

  Future<void> updateOrderStatus(String id, OrderStatus status) async {
    final idx = _orders.indexWhere((o) => o.id == id);
    if (idx == -1) return;

    final old = _orders[idx];
    _orders[idx] = old.copyWith(
      status: status,
      deliveryAt: status == OrderStatus.delivered
          ? DateTime.now()
          : old.deliveryAt,
    );
    await _saveOrders();
    _emitOrders();
  }

  // ---------------------------
  // Product CRUD for admin
  // ---------------------------

  final StreamController<List<Medicine>> _medicinesController =
      StreamController<List<Medicine>>.broadcast();

  /// Broadcast stream that emits the current list of medicines when changed.
  Stream<List<Medicine>> get medicinesStream => _medicinesController.stream;

  void _emitMedicines() {
    try {
      _medicinesController.add(List.unmodifiable(_medicines));
    } catch (_) {}
  }

  /// Adds a new medicine. If id already exists an exception is thrown.
  Future<void> addMedicine(Medicine medicine) async {
    if (_medicines.any((m) => m.id == medicine.id)) {
      throw StateError('Medicine with id ${medicine.id} already exists');
    }
    await DatabaseHelper.instance.insertMedicine(medicine);
    _medicines.insert(0, medicine);
    _emitMedicines();
  }

  /// Updates an existing medicine. Throws if not found.
  Future<void> updateMedicine(Medicine medicine) async {
    final idx = _medicines.indexWhere((m) => m.id == medicine.id);
    if (idx == -1) throw StateError('Medicine not found: ${medicine.id}');
    await DatabaseHelper.instance.updateMedicine(medicine);
    _medicines[idx] = medicine;
    _emitMedicines();
  }

  /// Convenience: update price only.
  Future<void> updateMedicinePrice(String id, double price) async {
    final idx = _medicines.indexWhere((m) => m.id == id);
    if (idx == -1) throw StateError('Medicine not found: $id');
    final old = _medicines[idx];
    final updated = Medicine(
      id: old.id,
      name: old.name,
      description: old.description,
      price: price,
      rating: old.rating,
      category: old.category,
      imageUrl: old.imageUrl,
      stockQuantity: old.stockQuantity,
    );
    await DatabaseHelper.instance.updateMedicine(updated);
    _medicines[idx] = updated;
    _emitMedicines();
  }

  /// Convenience: update image URL/path only (accepts null to clear).
  Future<void> updateMedicineImage(String id, String? imageUrl) async {
    final idx = _medicines.indexWhere((m) => m.id == id);
    if (idx == -1) throw StateError('Medicine not found: $id');
    final old = _medicines[idx];
    final updated = Medicine(
      id: old.id,
      name: old.name,
      description: old.description,
      price: old.price,
      rating: old.rating,
      category: old.category,
      imageUrl: imageUrl,
      stockQuantity: old.stockQuantity,
    );
    await DatabaseHelper.instance.updateMedicine(updated);
    _medicines[idx] = updated;
    _emitMedicines();
  }

  /// Removes a medicine by id.
  Future<void> deleteMedicine(String id) async {
    await DatabaseHelper.instance.deleteMedicine(id);
    _medicines.removeWhere((m) => m.id == id);
    _emitMedicines();
  }

  // ---------------------------
  // Prescription Management
  // ---------------------------

  final StreamController<List<Prescription>> _prescriptionsController =
      StreamController<List<Prescription>>.broadcast();

  Stream<List<Prescription>> get prescriptionsStream =>
      _prescriptionsController.stream;

  List<Prescription> get allPrescriptions => List.unmodifiable(_prescriptions);

  void _emitPrescriptions() {
    try {
      _prescriptionsController.add(List.unmodifiable(_prescriptions));
    } catch (_) {}
  }

  List<Prescription> get pendingPrescriptions =>
      _prescriptions.where((p) => p.status == 'pending').toList();

  Future<void> addPrescription(Prescription p) async {
    _prescriptions.insert(0, p);
    await _savePrescriptions();
    _emitPrescriptions();
  }

  Future<void> updatePrescriptionStatus(String id, String status) async {
    final idx = _prescriptions.indexWhere((p) => p.id == id);
    if (idx != -1) {
      final old = _prescriptions[idx];
      _prescriptions[idx] = Prescription(
        id: old.id,
        customerName: old.customerName,
        date: old.date,
        fileUrl: old.fileUrl,
        notes: old.notes,
        status: status,
        isDocument: old.isDocument,
      );
      await _savePrescriptions();
      _emitPrescriptions();
    }
  }

  /// Call this when the app disposes.
  void dispose() {
    _medicinesController.close();
    _prescriptionsController.close();
    _ordersController.close();
  }
}
