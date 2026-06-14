import 'package:flutter/material.dart';

import '../Widgets/custom_button.dart';
import '../models/order.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/pharmacy_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _selectedPaymentMethod = 'Cash on Delivery';
  bool _isPlacingOrder = false;

  List<OrderItem> get _orderItems => PharmacyService.instance.cartItems;
  double get _subtotal => PharmacyService.instance.cartSubtotal;
  double get _deliveryFee => 299.0;
  double get _total => _subtotal + _deliveryFee;

  Future<void> _confirmOrder() async {
    setState(() => _isPlacingOrder = true);
    try {
      final user = AuthService.instance.currentUser;
      final orderUser =
          user ??
          User(id: 'guest', name: 'Guest', email: 'guest@pharmacy.local');
      await PharmacyService.instance.placeOrderForUser(orderUser);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order confirmed successfully.')),
      );
      Navigator.pushReplacementNamed(context, '/orders');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to place order: $e')));
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF173F2E), Color(0xFF1B8F4A)],
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.credit_card_rounded, color: Colors.white, size: 30),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Confirm your delivery details and choose a secure payment method.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionCard(
            title: 'Delivery address',
            child: Column(
              children: const [
                _InfoRow(
                  icon: Icons.person_outline,
                  label: 'Customer',
                  value: 'John Doe',
                ),
                SizedBox(height: 10),
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  label: 'Address',
                  value: '123 Main Street, Springfield, 560001',
                ),
                SizedBox(height: 10),
                _InfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: '+1 202 555 0199',
                ),
                SizedBox(height: 10),
                _InfoRow(
                  icon: Icons.schedule_outlined,
                  label: 'Delivery ETA',
                  value: '30-45 min',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _sectionCard(
            title: 'Payment method',
            child: Column(
              children: [
                _paymentOption('Cash on Delivery', Icons.payments_outlined),
                _paymentOption(
                  'Credit / Debit Card',
                  Icons.credit_card_outlined,
                ),
                _paymentOption(
                  'Mobile Wallet',
                  Icons.account_balance_wallet_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _sectionCard(
            title: 'Order summary',
            child: Column(
              children: [
                ..._orderItems.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item.name} x${item.quantity}',
                            style: const TextStyle(fontSize: 14.5),
                          ),
                        ),
                        Text(
                          'Ksh ${item.subtotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 24),
                _priceRow('Subtotal', _subtotal),
                const SizedBox(height: 8),
                _priceRow('Delivery fee', _deliveryFee),
                const SizedBox(height: 12),
                _priceRow('Total', _total, isTotal: true),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FBFA),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE4ECE8)),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_rounded, color: Color(0xFF1B8F4A)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your details are protected with secure checkout handling.',
                    style: TextStyle(fontSize: 13.5, height: 1.4),
                  ),
                ),
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
            label: 'Confirm order',
            leading: const Icon(Icons.check_circle_outline_rounded),
            loading: _isPlacingOrder,
            onPressed: _confirmOrder,
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE4ECE8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF123A28),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _paymentOption(String method, IconData icon) {
    final isSelected = _selectedPaymentMethod == method;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPaymentMethod = method;
          });
        },
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFEAF7EF)
                : const Color(0xFFF8FAF9),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF1B8F4A)
                  : const Color(0xFFE4ECE8),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: const Color(0xFF1B8F4A)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  method,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF123A28),
                  ),
                ),
              ),
              Icon(
                isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: isSelected
                    ? const Color(0xFF1B8F4A)
                    : const Color(0xFFB7C7BE),
              ),
            ],
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
            fontSize: isTotal ? 16 : 14.5,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
            color: const Color(0xFF123A28),
          ),
        ),
        const Spacer(),
        Text(
          'Ksh ${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isTotal ? 19 : 15,
            fontWeight: FontWeight.w800,
            color: isTotal ? const Color(0xFF1B8F4A) : const Color(0xFF123A28),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF1B8F4A)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF123A28),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
