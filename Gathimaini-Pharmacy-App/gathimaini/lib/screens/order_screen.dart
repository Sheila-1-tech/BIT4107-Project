import 'package:flutter/material.dart';

import '../models/order.dart';
import '../services/auth_service.dart';
import '../services/pharmacy_service.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  List<Order> _orders = [];

  @override
  void initState() {
    super.initState();
    final user = AuthService.instance.currentUser;
    if (user != null) {
      _orders = PharmacyService.instance.ordersForUser(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order history')),
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
                Icon(Icons.receipt_long_rounded, color: Colors.white, size: 30),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Track every order from placement to delivery in a clean timeline view.',
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
          ..._orders.map(
            (order) => Container(
              margin: const EdgeInsets.only(bottom: 14),
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'ORD-${order.id.substring(order.id.length > 5 ? order.id.length - 5 : 0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF123A28),
                          ),
                        ),
                      ),
                      _statusChip(order.status),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    order.createdAt.toLocal().toString().split(' ')[0],
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    order.items.map((i) => i.name).join(', '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2A3D34),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Total: Ksh ${order.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B8F4A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Order progress',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF123A28),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _OrderTimeline(currentStep: _getStepFromStatus(order.status)),
                ],
              ),
            ),
          ),
          if (_orders.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40.0),
              child: Center(
                child: Text(
                  'No orders found.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }

  int _getStepFromStatus(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return 1;
      case OrderStatus.processing:
        return 2;
      case OrderStatus.outForDelivery:
        return 3;
      case OrderStatus.delivered:
        return 4;
      case OrderStatus.cancelled:
        return 0;
    }
  }

  Widget _statusChip(OrderStatus status) {
    late final String label;
    late final Color bgColor;
    late final Color textColor;

    switch (status) {
      case OrderStatus.processing:
        label = 'Processing';
        bgColor = const Color(0xFFFFF3D9);
        textColor = const Color(0xFF9A6B00);
        break;
      case OrderStatus.outForDelivery:
        label = 'Out for delivery';
        bgColor = const Color(0xFFE7F1FF);
        textColor = const Color(0xFF0F5BB3);
        break;
      case OrderStatus.delivered:
        label = 'Delivered';
        bgColor = const Color(0xFFE7F8EE);
        textColor = const Color(0xFF1E7A45);
        break;
      case OrderStatus.cancelled:
        label = 'Cancelled';
        bgColor = const Color(0xFFFCE8E8);
        textColor = const Color(0xFFB53C3C);
        break;
      case OrderStatus.placed:
        label = 'Placed';
        bgColor = const Color(0xFFEAF7EF);
        textColor = const Color(0xFF1B8F4A);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
      ),
    );
  }
}

class _OrderTimeline extends StatelessWidget {
  const _OrderTimeline({required this.currentStep});

  final int currentStep;

  static const List<String> _steps = [
    'Placed',
    'Processing',
    'Out for delivery',
    'Delivered',
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 11,
          left: 32,
          right: 32,
          child: Row(
            children: List.generate(_steps.length - 1, (index) {
              final stepNumber = index + 1;
              return Expanded(
                child: Container(
                  height: 2,
                  color: stepNumber < currentStep
                      ? const Color(0xFF1C8E4A)
                      : const Color(0xFFDCE5E0),
                ),
              );
            }),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(_steps.length, (index) {
            final stepNumber = index + 1;
            final isCompleted = stepNumber <= currentStep;

            return Expanded(
              child: Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? const Color(0xFF1B8F4A)
                          : const Color(0xFFE2E8E5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCompleted ? Icons.check_rounded : Icons.circle,
                      size: isCompleted ? 14 : 8,
                      color: isCompleted
                          ? Colors.white
                          : const Color(0xFF97A6A0),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _steps[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isCompleted
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isCompleted
                          ? const Color(0xFF1A6D3F)
                          : const Color(0xFF7E8C87),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}
