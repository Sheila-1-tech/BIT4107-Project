import 'package:flutter/material.dart';

import '../Widgets/custom_button.dart';
import '../models/medicine.dart';
import '../services/pharmacy_service.dart';

class MedicineDetailsScreen extends StatefulWidget {
  const MedicineDetailsScreen({super.key});

  @override
  State<MedicineDetailsScreen> createState() => _MedicineDetailsScreenState();
}

class _MedicineDetailsScreenState extends State<MedicineDetailsScreen> {
  int _quantity = 1;
  bool _isFavorite = false;

  @override
  Widget build(BuildContext context) {
    final medicine = ModalRoute.of(context)?.settings.arguments as Medicine?;
    final medicineName = medicine?.name ?? 'Paracetamol 500mg';
    final description =
        medicine?.description ??
        'Trusted relief for fever, headache, and body aches.';
    final price = medicine?.price ?? 699.00;
    final imageUrl = medicine?.imageUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine details'),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isFavorite = !_isFavorite;
              });
            },
            icon: Icon(
              _isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
            ),
            color: _isFavorite ? Colors.redAccent : const Color(0xFF1B8F4A),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.share_outlined)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEFFAF2), Color(0xFFDDEFE4)],
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 280,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Center(
                    child:
                        imageUrl != null &&
                            (imageUrl.startsWith('http://') ||
                                imageUrl.startsWith('https://'))
                        ? Image.network(
                            imageUrl,
                            width: 160,
                            height: 160,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.broken_image_rounded,
                                size: 72,
                                color: Color(0xFF1B8F4A),
                              );
                            },
                          )
                        : Image.asset(
                            'assets/images/logo.png',
                            width: 160,
                            height: 160,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.local_pharmacy_rounded,
                                size: 72,
                                color: Color(0xFF1B8F4A),
                              );
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: const [
                    Expanded(
                      child: _InfoPill(
                        icon: Icons.verified_rounded,
                        label: 'Genuine',
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _InfoPill(
                        icon: Icons.local_shipping_rounded,
                        label: 'Fast delivery',
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _InfoPill(
                        icon: Icons.medical_information_rounded,
                        label: 'Pharmacist approved',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicineName,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF123A28),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14.5,
                        height: 1.45,
                        color: Color(0xFF5C6F65),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Ksh ${price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B8F4A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F4EA),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'In stock',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B8F4A),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          _sectionCard(
            title: 'Product details',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: const [
                    _DetailChip(label: '500mg tablet'),
                    _DetailChip(label: 'For pain & fever'),
                    _DetailChip(label: '24 tablets'),
                    _DetailChip(label: 'Adults & kids over 12'),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Paracetamol is commonly used to reduce fever and relieve mild to moderate pain. It is one of the most trusted over-the-counter medicines for everyday care.',
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.55,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionCard(
            title: 'Dosage & usage',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bullet('Adults: 1 tablet every 6-8 hours as needed'),
                _bullet('Do not exceed 4 tablets in 24 hours'),
                _bullet('Take after food with water'),
                const SizedBox(height: 10),
                Text(
                  'Always follow doctor or pharmacist guidance before use.',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionCard(
            title: 'Pharmacist note',
            child: Text(
              'This is a dependable first-choice product for mild symptoms. If pain persists, consult your pharmacist or doctor for further guidance.',
              style: TextStyle(
                fontSize: 14.5,
                height: 1.5,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          const SizedBox(height: 18),
          _sectionCard(
            title: 'Quantity',
            child: Row(
              children: [
                _QuantityButton(icon: Icons.remove, onTap: _decreaseQuantity),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '$_quantity',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF123A28),
                    ),
                  ),
                ),
                _QuantityButton(icon: Icons.add, onTap: _increaseQuantity),
                const Spacer(),
                Text(
                  'Ksh ${(price * _quantity).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B8F4A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 54,
                child: CustomButton(
                  label: 'Add to cart',
                  leading: const Icon(Icons.add_shopping_cart_rounded),
                  onPressed: () {
                    if (medicine != null) {
                      PharmacyService.instance.addToCart(
                        medicine.id,
                        quantity: _quantity,
                      );
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$medicineName added to cart.')),
                    );
                    Navigator.pushNamed(context, '/cart');
                  },
                  backgroundColor: const Color(0xFFE9F6EE),
                  foregroundColor: const Color(0xFF1B8F4A),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 54,
                child: CustomButton(
                  label: 'Buy now',
                  leading: const Icon(Icons.flash_on_rounded),
                  onPressed: () => Navigator.pushNamed(context, '/checkout'),
                  borderRadius: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _increaseQuantity() {
    setState(() {
      _quantity += 1;
    });
  }

  void _decreaseQuantity() {
    if (_quantity == 1) return;
    setState(() {
      _quantity -= 1;
    });
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE4ECE8)),
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

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 3),
            child: Icon(
              Icons.check_circle_rounded,
              size: 18,
              color: Color(0xFF1B8F4A),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14.5,
                height: 1.45,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF1B8F4A)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF29503F),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7F2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1B8F4A),
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFEAF7EF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: const Color(0xFF1B8F4A)),
      ),
    );
  }
}
