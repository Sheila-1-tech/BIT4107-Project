import 'package:flutter/material.dart';

import '../Widgets/custom_button.dart';
import '../models/order.dart';
import '../services/pharmacy_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<OrderItem> get _cartItems => PharmacyService.instance.cartItems;
  double get _subtotal => PharmacyService.instance.cartSubtotal;
  double get _deliveryFee => 299.0;
  double get _total => _subtotal + _deliveryFee;

  void _increaseQuantity(int index) {
    final item = _cartItems[index];
    setState(() {
      PharmacyService.instance.updateCartQuantity(item.medicineId, item.quantity + 1);
    });
  }

  void _decreaseQuantity(int index) {
    final item = _cartItems[index];
    setState(() {
      if (item.quantity > 1) {
        PharmacyService.instance.updateCartQuantity(item.medicineId, item.quantity - 1);
      }
    });
  }

  void _removeItem(int index) {
    final item = _cartItems[index];
    final removedItem = _cartItems[index].name;
    setState(() {
      PharmacyService.instance.removeFromCart(item.medicineId);
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$removedItem removed from cart.')));
  }

  void _goToCheckout() {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Your cart is empty.')));
      return;
    }
    Navigator.pushNamed(context, '/checkout');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your cart'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.receipt_long_rounded),
          ),
        ],
      ),
      body: _cartItems.isEmpty
          ? _buildEmptyCart()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFF4FBF6), Color(0xFFE3F4EA)],
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.shopping_cart_checkout_rounded,
                        color: Color(0xFF1B8F4A),
                        size: 30,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Review your medicines, adjust quantities, and continue to a smooth checkout.',
                          style: TextStyle(
                            fontSize: 14.5,
                            height: 1.45,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF234236),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...List.generate(_cartItems.length, (index) {
                  final item = _cartItems[index];
                  final medicines = PharmacyService.instance.allMedicines.where((m) => m.id == item.medicineId).toList();
                  final subtitle = medicines.isNotEmpty ? (medicines.first.category ?? 'Pharmacy item') : 'Pharmacy item';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE4ECE8)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFF4FBF6), Color(0xFFE3F4EA)],
                            ),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Icon(
                            Icons.medication_liquid_rounded,
                            color: Color(0xFF1B8F4A),
                            size: 34,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF123A28),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          subtitle,
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _removeItem(index),
                                    color: const Color(0xFFC94A4A),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      _QuantityButton(
                                        icon: Icons.remove,
                                        onTap: () => _decreaseQuantity(index),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        child: Text(
                                          item.quantity.toString(),
                                          style: const TextStyle(
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      _QuantityButton(
                                        icon: Icons.add,
                                        onTap: () => _increaseQuantity(index),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Ksh ${(item.unitPrice * item.quantity).toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF1B8F4A),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Ksh ${item.unitPrice.toStringAsFixed(2)} each',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0xFFE4ECE8)),
                  ),
                  child: Column(
                    children: [
                      _priceRow('Subtotal', _subtotal),
                      const SizedBox(height: 10),
                      _priceRow('Delivery fee', _deliveryFee),
                      const Divider(height: 28),
                      _priceRow('Total', _total, isTotal: true),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: SizedBox(
          height: 54,
          child: CustomButton(
            label: 'Proceed to checkout',
            leading: const Icon(Icons.lock_outline_rounded),
            onPressed: _goToCheckout,
          ),
        ),
      ),
    );
  }

  Widget _priceRow(String label, double value, {bool isTotal = false}) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16.5 : 14.5,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
            color: const Color(0xFF123A28),
          ),
        ),
        const Spacer(),
        Text(
          'Ksh ${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isTotal ? 20 : 15,
            fontWeight: FontWeight.w800,
            color: isTotal ? const Color(0xFF1B8F4A) : const Color(0xFF123A28),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFFE4ECE8)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFF4FBF6), Color(0xFFE3F4EA)],
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(
                  Icons.shopping_cart_outlined,
                  size: 42,
                  color: Color(0xFF1B8F4A),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Your cart is empty',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF123A28),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Browse trusted medicines and wellness products from the home screen.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.45,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 18),
              CustomButton(
                label: 'Browse medicines',
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFEAF7EF),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF1B8F4A)),
      ),
    );
  }
}
