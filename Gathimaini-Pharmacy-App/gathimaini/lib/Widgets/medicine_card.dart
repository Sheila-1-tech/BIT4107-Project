import 'package:flutter/material.dart';
import 'custom_button.dart';

class MedicineCard extends StatelessWidget {
  const MedicineCard({
    super.key,
    required this.name,
    required this.subtitle,
    required this.price,
    required this.rating,
    this.stockLabel = 'In stock',
    this.categoryLabel,
    this.imageAsset,
    this.icon = Icons.medication_liquid_rounded,
    this.isFavorite = false,
    this.onTap,
    this.onAdd,
    this.onFavorite,
  });

  final String name;
  final String subtitle;
  final double price;
  final double rating;
  final String stockLabel;
  final String? categoryLabel;
  final String? imageAsset;
  final IconData icon;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;
  final VoidCallback? onFavorite;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: const Color(0xFFE8EFEB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    height: 132,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFF4FBF6), Color(0xFFE2F5EA)],
                      ),
                    ),
                    child: Center(child: _buildImage(imageAsset)),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        stockLabel,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1B8F4A),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      onPressed: onFavorite,
                      icon: Icon(
                        isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isFavorite
                            ? Colors.redAccent
                            : const Color(0xFF1B8F4A),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (categoryLabel != null) ...[
                      Text(
                        categoryLabel!,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6B7B74),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF143828),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        Text(
                          'Ksh ${price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1B8F4A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        label: 'Add to cart',
                        leading: const Icon(
                          Icons.add_shopping_cart_rounded,
                          size: 18,
                        ),
                        height: 42,
                        borderRadius: 16,
                        onPressed: onAdd,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String? source) {
    if (source == null || source.trim().isEmpty) {
      return Icon(icon, size: 54, color: const Color(0xFF1B8F4A));
    }

    final value = source.trim();
    final isNetworkImage =
        value.startsWith('http://') || value.startsWith('https://');

    if (isNetworkImage) {
      return Padding(
        padding: const EdgeInsets.all(18),
        child: Image.network(
          value,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Icon(icon, size: 54, color: const Color(0xFF1B8F4A));
          },
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Image.asset(
        value,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(icon, size: 54, color: const Color(0xFF1B8F4A));
        },
      ),
    );
  }
}
