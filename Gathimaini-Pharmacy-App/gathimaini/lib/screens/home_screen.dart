import 'dart:async';

import 'package:flutter/material.dart';

import '../models/medicine.dart';
import '../services/pharmacy_service.dart';
import '../Widgets/category_card.dart';
import '../Widgets/medicine_card.dart';
import '../Widgets/promo_banner.dart';
import '../Widgets/section_header.dart';
import '../Widgets/trust_badge.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final PageController _bannerController = PageController(
    viewportFraction: 0.9,
  );

  int _selectedNavIndex = 0;
  int _currentBannerIndex =
      0; // Track the current banner for the PageView dots.
  String? _selectedCategory; // Holds the currently selected product category.

  String _searchQuery = ''; // The current text in the search bar.
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<Medicine> _medicines = [];
  late final StreamSubscription<List<Medicine>> _medSub;

  final List<_PromoData> _banners = const [
    _PromoData(
      title: 'Fast delivery\nfor urgent essentials',
      subtitle: 'Order trusted pharmacy items and get them delivered quickly.',
      ctaLabel: 'Deliver today',
      icon: Icons.local_shipping_outlined,
      colors: [Color(0xFF1F9B58), Color(0xFF12673A)],
    ),
    _PromoData(
      title: 'Genuine medicine\nfrom reliable sources',
      subtitle:
          'Quality-assured products with a clean and simple checkout flow.',
      ctaLabel: 'Shop safely',
      icon: Icons.verified_outlined,
      colors: [Color(0xFF2E7BFF), Color(0xFF184AA8)],
    ),
    _PromoData(
      title: 'Wellness deals\nfor the whole family',
      subtitle:
          'Discover vitamins, baby care, skincare, and daily wellbeing picks.',
      ctaLabel: 'See offers',
      icon: Icons.favorite_outline_rounded,
      colors: [Color(0xFFDA6A43), Color(0xFF9B3F2C)],
    ),
  ];

  final List<_CategoryData> _categories = const [
    _CategoryData(
      label: 'Pain Relief',
      icon: Icons.healing_outlined,
      color: Color(0xFF1B8F4A),
    ),
    _CategoryData(
      label: 'Vitamins',
      icon: Icons.spa_outlined,
      color: Color(0xFF3A7BE0),
    ),
    _CategoryData(
      label: 'Baby Care',
      icon: Icons.child_care_outlined,
      color: Color(0xFFCB7A2D),
    ),
    _CategoryData(
      label: 'Skincare',
      icon: Icons.face_retouching_natural_outlined,
      color: Color(0xFFE05A92),
    ),
    _CategoryData(
      label: 'Supplements',
      icon: Icons.monitor_heart_outlined,
      color: Color(0xFF7B61FF),
    ),
    _CategoryData(
      label: 'First Aid',
      icon: Icons.medical_services_outlined,
      color: Color(0xFF17886B),
    ),
  ];

  final List<_MedicineData> _specialOffers = const [
    _MedicineData(
      id: 'special_wellness_pack',
      name: 'Wellness Pack',
      subtitle: 'Essential vitamins + hydration support',
      price: 1890.0,
      rating: 4.7,
      stockLabel: '18% off',
      categoryLabel: 'Special offer',
      // PASTE YOUR OWN INTERNET IMAGE LINK BELOW:
      imageUrl:
          'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?q=80&w=400&auto=format&fit=crop',
    ),
    _MedicineData(
      id: 'special_family_first_aid_kit',
      name: 'Family First Aid Kit',
      subtitle: 'Everyday care bundle for home and travel',
      price: 2420.0,
      rating: 4.8,
      stockLabel: 'Limited deal',
      categoryLabel: 'Limited time',
      // PASTE YOUR OWN INTERNET IMAGE LINK BELOW:
      imageUrl:
          'https://images.unsplash.com/photo-1603398938378-e54eab446dde?q=80&w=400&auto=format&fit=crop',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _medicines = PharmacyService.instance.allMedicines;
    _medSub = PharmacyService.instance.medicinesStream.listen((list) {
      if (!mounted) return;
      setState(() => _medicines = list);
    });
  }

  @override
  void dispose() {
    _medSub.cancel();
    _scrollController.dispose();
    _bannerController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _handleNavTap(int index) {
    setState(() {
      _selectedNavIndex = index;
    });

    switch (index) {
      case 1:
        _scrollToTop();
        _searchFocusNode.requestFocus();
        break;
      case 2:
        Navigator.pushNamed(context, '/cart');
        break;
      case 3:
        Navigator.pushNamed(context, '/orders');
        break;
      case 4:
        Navigator.pushNamed(context, '/profile');
        break;
      default:
        _scrollToTop();
    }
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  String _timeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning'; // Before 12 PM
    if (hour < 17) return 'Good afternoon'; // 12 PM to 5 PM
    return 'Good evening'; // After 5 PM
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchQuery.trim().toLowerCase();
    final isSearching = query.isNotEmpty;
    final selectedCategory = _selectedCategory?.trim().toLowerCase();
    final filteredMedicines = _medicines.where((m) {
      if (query.isEmpty) return true;
      return m.name.toLowerCase().contains(query) ||
          (m.category ?? '').toLowerCase().contains(query) ||
          m.description.toLowerCase().contains(query);
    }).toList();
    final categoryMedicines =
        selectedCategory == null || selectedCategory.isEmpty
        ? <Medicine>[]
        : _medicines.where((medicine) {
            final category = (medicine.category ?? '').trim().toLowerCase();
            return category == selectedCategory ||
                category.contains(selectedCategory) ||
                selectedCategory.contains(category);
          }).toList();

    // Dynamic layout calculation to prevent pixel overflow on small phones
    final screenWidth = MediaQuery.of(context).size.width;
    final gridAspectRatio = screenWidth < 380 ? 0.48 : 0.55;

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 82,
        titleSpacing: 16,
        title: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFE3F4EA),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 34,
                  height: 34,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.local_pharmacy_rounded,
                      size: 22,
                      color: Color(0xFF1B8F4A),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${_timeGreeting()}, Sheila 👋',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF123A28),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Trusted medicine & wellness products',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF60756A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none_rounded),
              color: const Color(0xFF1B8F4A),
            ),
          ),
        ],
      ),
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        children: [
          _buildHeroPanel(),
          const SizedBox(height: 18),
          TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search medicines, supplements, or wellness products',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Color(0xFF1B8F4A),
              ),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                        });
                        FocusScope.of(context).unfocus();
                      },
                    ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Color(0xFFE4ECE8)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Color(0xFFE4ECE8)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(
                  color: Color(0xFF1B8F4A),
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          if (isSearching) ...[
            SectionHeader(
              title: 'Search results',
              subtitle: 'Showing results for "$_searchQuery"',
            ),
            const SizedBox(height: 14),
            if (filteredMedicines.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('No medicines found matching your search.'),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: gridAspectRatio,
                ),
                itemCount: filteredMedicines.length,
                itemBuilder: (context, index) {
                  final medicine = filteredMedicines[index];
                  return MedicineCard(
                    name: medicine.name,
                    subtitle: medicine.description,
                    price: medicine.price,
                    rating: medicine.rating,
                    stockLabel: 'In stock',
                    categoryLabel: medicine.category ?? 'General',
                    imageAsset: medicine.imageUrl ?? 'assets/images/logo.png',
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/medicine-details',
                      arguments: medicine,
                    ),
                    onAdd: () {
                      PharmacyService.instance.addToCart(medicine.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${medicine.name} added to cart'),
                        ),
                      );
                    },
                    onFavorite: () {},
                  );
                },
              ),
          ] else ...[
            _buildPrescriptionCard(),
            const SizedBox(height: 24),
            SectionHeader(
              title: 'Top offers',
              subtitle:
                  'Fast, genuine, and professionally curated pharmacy deals.',
              actionLabel: 'View all',
              onActionTap: () {},
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 230,
              child: PageView.builder(
                controller: _bannerController,
                itemCount: _banners.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentBannerIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final banner = _banners[index];
                  return PromoBannerCard(
                    title: banner.title,
                    subtitle: banner.subtitle,
                    ctaLabel: banner.ctaLabel,
                    icon: banner.icon,
                    backgroundColors: banner.colors,
                    assetImage: 'assets/images/logo.png',
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            _buildBannerDots(),
            const SizedBox(height: 24),
            SectionHeader(
              title: 'Shop by category',
              subtitle: 'Quick access to your most common pharmacy needs.',
              actionLabel: 'Clear',
              onActionTap: () {
                setState(() {
                  _selectedCategory = null;
                });
                _scrollToTop();
              },
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 132,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length, // Category cards
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return CategoryCard(
                    label: category.label,
                    icon: category.icon,
                    color: category.color,
                    onTap: () {
                      setState(() {
                        _selectedCategory = category.label;
                        _searchQuery = '';
                        _searchController.clear();
                      });
                      _scrollToTop();
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            if (_selectedCategory != null &&
                _selectedCategory!.trim().isNotEmpty) ...[
              SectionHeader(
                title: '${_selectedCategory!} medicines',
                subtitle: categoryMedicines.isEmpty
                    ? 'No items are currently tagged with this category.'
                    : 'Showing medicines and drugs available in this category.',
                actionLabel: 'Back to categories',
                onActionTap: () {
                  setState(() {
                    _selectedCategory = null;
                  });
                },
              ),
              const SizedBox(height: 14),
              if (categoryMedicines.isEmpty)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE4ECE8)),
                  ),
                  child: const Text(
                    'No medicines found in this category yet.',
                    style: TextStyle(fontSize: 14.5, height: 1.4),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: gridAspectRatio,
                  ),
                  itemCount: categoryMedicines.length,
                  itemBuilder: (context, index) {
                    final medicine = categoryMedicines[index];
                    return MedicineCard(
                      name: medicine.name,
                      subtitle: medicine.description,
                      price: medicine.price,
                      rating: medicine.rating,
                      stockLabel: 'In stock',
                      categoryLabel: medicine.category ?? 'General',
                      imageAsset: medicine.imageUrl ?? 'assets/images/logo.png',
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/medicine-details',
                        arguments: medicine,
                      ),
                      onAdd: () {
                        PharmacyService.instance.addToCart(medicine.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${medicine.name} added to cart'),
                          ),
                        );
                      },
                      onFavorite: () {},
                    );
                  },
                ),
              const SizedBox(height: 24),
            ],
            SectionHeader(
              title: 'Popular medicines',
              subtitle: 'High-trust products chosen for everyday care.',
              actionLabel: 'See more',
              onActionTap: () {},
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 380,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _medicines.length, // Popular medicines
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final medicine = _medicines[index];
                  return SizedBox(
                    width: 220,
                    child: MedicineCard(
                      name: medicine.name,
                      subtitle: medicine.description,
                      price: medicine.price,
                      rating: medicine.rating,
                      stockLabel: 'In stock',
                      categoryLabel: medicine.category ?? 'General',
                      imageAsset: medicine.imageUrl ?? 'assets/images/logo.png',
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/medicine-details',
                        arguments: medicine,
                      ),
                      onAdd: () {
                        PharmacyService.instance.addToCart(medicine.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${medicine.name} added to cart'),
                          ),
                        );
                      },
                      onFavorite: () {},
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            SectionHeader(
              title: 'Wellness corner',
              subtitle:
                  'Balanced care, supplements, and family-friendly support.',
              actionLabel: 'Explore',
              onActionTap: () {},
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF6FBF8), Color(0xFFE3F5EA)],
                ),
                border: Border.all(color: const Color(0xFFD9ECE2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(
                      Icons.health_and_safety_outlined,
                      size: 36,
                      color: Color(0xFF1B8F4A),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily wellness, simplified',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF123A28),
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Discover products that support immunity, energy, hydration, and care at home.',
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.45,
                            color: Color(0xFF586B62),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SectionHeader(
              title: 'Special offers',
              subtitle: 'Premium bundles and time-limited savings.',
              actionLabel: 'Shop deals',
              onActionTap: () {},
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 380,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _specialOffers.length, // Special offers
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final offer = _specialOffers[index];
                  return SizedBox(
                    width: 230,
                    child: MedicineCard(
                      name: offer.name,
                      subtitle: offer.subtitle,
                      price: offer.price,
                      rating: offer.rating,
                      stockLabel: offer.stockLabel,
                      categoryLabel: offer.categoryLabel,
                      imageAsset: offer.imageUrl ?? 'assets/images/logo.png',
                      onTap: () {
                        final tempMedicine = Medicine(
                          id: offer.id,
                          name: offer.name,
                          description: offer.subtitle,
                          price: offer.price,
                          rating: offer.rating,
                          category: offer.categoryLabel,
                          imageUrl: offer.imageUrl,
                        );
                        Navigator.pushNamed(
                          context,
                          '/medicine-details',
                          arguments: tempMedicine,
                        );
                      },
                      onAdd: () {
                        PharmacyService.instance.addToCart(offer.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${offer.name} added to cart'),
                          ),
                        );
                      },
                      onFavorite: () {},
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            SectionHeader(
              title: 'Why customers trust us',
              subtitle:
                  'A clean, dependable pharmacy experience built around care.',
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: const [
                TrustBadge(
                  label: 'Genuine products',
                  icon: Icons.verified_rounded,
                ),
                TrustBadge(
                  label: 'Fast delivery',
                  icon: Icons.local_shipping_rounded,
                ),
                TrustBadge(
                  label: 'Pharmacist support',
                  icon: Icons.support_agent_rounded,
                ),
                TrustBadge(label: 'Secure payment', icon: Icons.lock_rounded),
              ],
            ),
          ],
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedNavIndex,
        onDestinationSelected: _handleNavTap,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE3F4EA),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_rounded),
            selectedIcon: Icon(Icons.search_rounded),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart_rounded),
            label: 'Cart',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHeroPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF173F2E), Color(0xFF1B8F4A), Color(0xFF4CB874)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B8F4A).withValues(alpha: 0.26),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Open today • 8AM - 9PM',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Health care\nmade simple',
                  style: TextStyle(
                    fontSize: 30,
                    height: 1.0,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Order trusted medicine, wellness products, and pharmacy essentials in a clean, premium experience.',
                  style: TextStyle(
                    fontSize: 13.8,
                    height: 1.5,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.local_pharmacy_rounded,
                    size: 34,
                    color: Color(0xFFFFFFFF),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7EF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFCAEAD4)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.document_scanner_outlined,
              color: Color(0xFF1B8F4A),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Have a prescription?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF123A28),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Upload it and let our pharmacists prepare your order.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF345242),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/upload-prescription');
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: const Text('Upload'),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_banners.length, (index) {
        final isActive = index == _currentBannerIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF1B8F4A) : const Color(0xFFD5E4DA),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _PromoData {
  const _PromoData({
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.icon,
    required this.colors,
  });

  final String title;
  final String subtitle;
  final String ctaLabel;
  final IconData icon;
  final List<Color> colors;
}

class _CategoryData {
  const _CategoryData({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}

class _MedicineData {
  const _MedicineData({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.price,
    required this.rating,
    required this.stockLabel,
    required this.categoryLabel,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String subtitle;
  final double price;
  final double rating;
  final String stockLabel;
  final String categoryLabel;
  final String? imageUrl;
}
