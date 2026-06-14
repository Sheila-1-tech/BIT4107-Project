import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Widgets/custom_button.dart';
import '../services/auth_service.dart';
import '../services/pharmacy_service.dart';
import '../models/prescription.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = 'John Doe';
  String _email = 'john.doe@email.com';
  String _phone = '+1 202 555 0199';
  String? _avatarUrl;

  List<Prescription> _prescriptions = [];
  late final StreamSubscription<List<Prescription>> _rxSub;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _prescriptions = PharmacyService.instance.allPrescriptions;
    _rxSub = PharmacyService.instance.prescriptionsStream.listen((list) {
      if (mounted) setState(() => _prescriptions = list);
    });
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUser = AuthService.instance.currentUser;
    if (mounted) {
      setState(() {
        _name =
            prefs.getString('profile_name') ?? currentUser?.name ?? 'John Doe';
        _email =
            prefs.getString('profile_email') ??
            currentUser?.email ??
            'john.doe@email.com';
        _phone = prefs.getString('profile_phone') ?? '+1 202 555 0199';
        _avatarUrl = prefs.getString('profile_avatar');
      });
    }
  }

  @override
  void dispose() {
    _rxSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService.instance.currentUser;
    final myApprovedRxs = _prescriptions
        .where(
          (p) =>
              p.customerName == (currentUser?.name ?? 'Guest') &&
              p.status == 'approved',
        )
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
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
                colors: [Color(0xFF173F2E), Color(0xFF1B8F4A)],
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: Colors.white.withValues(alpha: 0.16),
                  child: ClipOval(
                    child: _avatarUrl != null && _avatarUrl!.isNotEmpty
                        ? Image.network(
                            _avatarUrl!,
                            width: 84,
                            height: 84,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Image.asset(
                                  'assets/images/logo.png',
                                  width: 50,
                                ),
                          )
                        : Image.asset(
                            'assets/images/logo.png',
                            width: 50,
                            height: 50,
                            fit: BoxFit.contain,
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _email,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _phone,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: const [
                    Expanded(
                      child: _ProfileStat(label: 'Orders', value: '14'),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _ProfileStat(label: 'Rewards', value: '320'),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _ProfileStat(label: 'Support', value: '24/7'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (myApprovedRxs.isNotEmpty) ...[
            const SizedBox(height: 18),
            const _SectionTitle(title: 'Notifications'),
            const SizedBox(height: 10),
            ...myApprovedRxs.map(
              (rx) => _NotificationBanner(
                title: 'Prescription Approved',
                subtitle:
                    'Your prescription ${rx.id} has been reviewed and approved by our pharmacist!',
              ),
            ),
          ],
          const SizedBox(height: 18),
          const _SectionTitle(title: 'Account'),
          const SizedBox(height: 10),
          _SettingTile(
            icon: Icons.person_outline_rounded,
            title: 'Edit profile',
            subtitle: 'Update your personal information',
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _EditProfileScreen(
                    initialName: _name,
                    initialEmail: _email,
                    initialPhone: _phone,
                    initialAvatar: _avatarUrl,
                  ),
                ),
              );
              if (!mounted) return;
              if (result != null && result is Map<String, String?>) {
                final newName = result['name'] ?? _name;
                final newEmail = result['email'] ?? _email;
                final newPhone = result['phone'] ?? _phone;
                final newAvatar = result['avatarUrl'];

                setState(() {
                  _name = newName;
                  _email = newEmail;
                  _phone = newPhone;
                  _avatarUrl = newAvatar;
                });

                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('profile_name', newName);
                await prefs.setString('profile_email', newEmail);
                await prefs.setString('profile_phone', newPhone);
                if (newAvatar != null && newAvatar.isNotEmpty) {
                  await prefs.setString('profile_avatar', newAvatar);
                } else {
                  await prefs.remove('profile_avatar');
                }
              }
            },
          ),
          _SettingTile(
            icon: Icons.location_on_outlined,
            title: 'Delivery addresses',
            subtitle: 'Manage saved delivery locations',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const _DeliveryAddressesScreen(),
              ),
            ),
          ),
          _SettingTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Control updates and delivery alerts',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const _NotificationsScreen()),
            ),
          ),
          _SettingTile(
            icon: Icons.lock_outline_rounded,
            title: 'Privacy and security',
            subtitle: 'Password and account protection',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const _PrivacySecurityScreen()),
            ),
          ),
          const SizedBox(height: 18),
          const _SectionTitle(title: 'Orders & help'),
          const SizedBox(height: 10),
          _SettingTile(
            icon: Icons.receipt_long_outlined,
            title: 'Order history',
            subtitle: 'View previous and active orders',
            onTap: () => Navigator.pushNamed(context, '/orders'),
          ),
          _SettingTile(
            icon: Icons.support_agent_rounded,
            title: 'Help center',
            subtitle: 'Speak to pharmacist support',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const _HelpCenterScreen()),
            ),
          ),
          const SizedBox(height: 18),
          CustomButton(
            label: 'Logout',
            leading: const Icon(Icons.logout_rounded),
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFFC94A4A),
            elevation: 0,
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC94A4A),
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true && context.mounted) {
      await AuthService.instance.logout();
      if (!context.mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.88),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationBanner extends StatelessWidget {
  const _NotificationBanner({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7EF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF1B8F4A).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF1B8F4A),
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Color(0xFF123A28),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.green.shade900.withValues(alpha: 0.8),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// NEW SUB-SCREENS FOR PROFILE OPTIONS
// ============================================================================

class _EditProfileScreen extends StatefulWidget {
  const _EditProfileScreen({
    required this.initialName,
    required this.initialEmail,
    required this.initialPhone,
    this.initialAvatar,
  });

  final String initialName;
  final String initialEmail;
  final String initialPhone;
  final String? initialAvatar;

  @override
  State<_EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<_EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _avatarController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _emailController = TextEditingController(text: widget.initialEmail);
    _phoneController = TextEditingController(text: widget.initialPhone);
    _avatarController = TextEditingController(text: widget.initialAvatar ?? '');
    _avatarController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFFEAF7EF),
                  backgroundImage: _avatarController.text.isNotEmpty
                      ? NetworkImage(_avatarController.text)
                      : null,
                  child: _avatarController.text.isEmpty
                      ? Image.asset('assets/images/logo.png', width: 60)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1B8F4A),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _avatarController,
            decoration: const InputDecoration(
              labelText: 'Profile Picture URL',
              hintText: 'https://images.unsplash.com/...',
              prefixIcon: Icon(Icons.image_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(20),
        child: CustomButton(
          label: 'Save Changes',
          onPressed: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Profile updated!')));
            Navigator.pop(context, {
              'name': _nameController.text,
              'email': _emailController.text,
              'phone': _phoneController.text,
              'avatarUrl': _avatarController.text,
            });
          },
        ),
      ),
    );
  }
}

class _Address {
  String title;
  String details;
  IconData icon;
  bool isDefault;

  _Address({
    required this.title,
    required this.details,
    required this.icon,
    required this.isDefault,
  });
}

class _DeliveryAddressesScreen extends StatefulWidget {
  const _DeliveryAddressesScreen();

  @override
  State<_DeliveryAddressesScreen> createState() =>
      _DeliveryAddressesScreenState();
}

class _DeliveryAddressesScreenState extends State<_DeliveryAddressesScreen> {
  final List<_Address> _addresses = [
    _Address(
      title: 'Home',
      details: '123 Main Street, Springfield, 560001\nApt 4B',
      icon: Icons.home_rounded,
      isDefault: true,
    ),
    _Address(
      title: 'Work',
      details: '88 Tech Park Way, Floor 3\nSpringfield, 560012',
      icon: Icons.work_rounded,
      isDefault: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery Addresses')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: _addresses.map((addr) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildAddressCard(
              addr.title,
              addr.details,
              addr.icon,
              addr.isDefault,
            ),
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final newAddress = await Navigator.push<_Address>(
            context,
            MaterialPageRoute(builder: (_) => const _AddAddressScreen()),
          );
          if (newAddress != null && mounted) {
            setState(() {
              if (newAddress.isDefault) {
                for (var a in _addresses) {
                  a.isDefault = false;
                }
              }
              _addresses.add(newAddress);
            });
          }
        },
        icon: const Icon(Icons.add_location_alt_rounded),
        label: const Text('Add Address'),
        backgroundColor: const Color(0xFF1B8F4A),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildAddressCard(
    String title,
    String address,
    IconData icon,
    bool isDefault,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDefault ? const Color(0xFF1B8F4A) : const Color(0xFFE4ECE8),
          width: isDefault ? 2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF1B8F4A), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    if (isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF7EF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Default',
                          style: TextStyle(
                            color: Color(0xFF1B8F4A),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  address,
                  style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.edit_outlined, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _AddAddressScreen extends StatefulWidget {
  const _AddAddressScreen();

  @override
  State<_AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<_AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _detailsController = TextEditingController();
  bool _isDefault = false;

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Address')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Address Title (e.g. Home, Work)',
                prefixIcon: Icon(Icons.label_outline_rounded),
              ),
              validator: (val) => (val == null || val.trim().isEmpty)
                  ? 'Please enter a title'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _detailsController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Full Address',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              validator: (val) => (val == null || val.trim().isEmpty)
                  ? 'Please enter the address details'
                  : null,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Set as default address'),
              value: _isDefault,
              activeColor: const Color(0xFF1B8F4A),
              onChanged: (val) => setState(() => _isDefault = val),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(20),
        child: CustomButton(
          label: 'Save Address',
          onPressed: () {
            if (_formKey.currentState?.validate() == true) {
              final title = _titleController.text.trim();
              IconData icon = Icons.location_on_rounded;
              if (title.toLowerCase().contains('home'))
                icon = Icons.home_rounded;
              else if (title.toLowerCase().contains('work'))
                icon = Icons.work_rounded;

              Navigator.pop(
                context,
                _Address(
                  title: title,
                  details: _detailsController.text.trim(),
                  icon: icon,
                  isDefault: _isDefault,
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

class _NotificationsScreen extends StatefulWidget {
  const _NotificationsScreen();
  @override
  State<_NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<_NotificationsScreen> {
  bool _orderUpdates = true;
  bool _promotions = false;
  bool _restock = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          SwitchListTile(
            title: const Text(
              'Order Updates',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Get notified when your order status changes.',
            ),
            activeThumbColor: const Color(0xFF1B8F4A),
            value: _orderUpdates,
            onChanged: (val) => setState(() => _orderUpdates = val),
          ),
          SwitchListTile(
            title: const Text(
              'Promotions & Offers',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('Receive coupons and special discounts.'),
            activeThumbColor: const Color(0xFF1B8F4A),
            value: _promotions,
            onChanged: (val) => setState(() => _promotions = val),
          ),
          SwitchListTile(
            title: const Text(
              'Restock Alerts',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('Know when your favorite medicines are back.'),
            activeThumbColor: const Color(0xFF1B8F4A),
            value: _restock,
            onChanged: (val) => setState(() => _restock = val),
          ),
        ],
      ),
    );
  }
}

class _PrivacySecurityScreen extends StatelessWidget {
  const _PrivacySecurityScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Security')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ListTile(
            leading: const Icon(Icons.password_rounded),
            title: const Text('Change Password'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.fingerprint_rounded),
            title: const Text('Biometric Login'),
            trailing: Switch(
              value: true,
              activeThumbColor: const Color(0xFF1B8F4A),
              onChanged: (val) {},
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(
              Icons.delete_forever_rounded,
              color: Colors.redAccent,
            ),
            title: const Text(
              'Delete Account',
              style: TextStyle(color: Colors.redAccent),
            ),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _HelpCenterScreen extends StatelessWidget {
  const _HelpCenterScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help Center')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CustomButton(
            label: 'Chat with AI Assistant',
            leading: const Icon(Icons.smart_toy_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const _AIChatScreen()),
              );
            },
          ),
          const SizedBox(height: 32),
          const Text(
            'Frequently Asked Questions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          const ExpansionTile(
            title: Text(
              'How long does delivery take?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Most orders are delivered within 30-45 minutes in active zones.',
                ),
              ),
            ],
          ),
          const ExpansionTile(
            title: Text(
              'Can I return medicines?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'For safety reasons, opened medicines cannot be returned unless damaged during transit.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// AI CHATBOT INTERFACE
// ============================================================================

class _ChatMessage {
  const _ChatMessage({required this.text, required this.isUser});
  final String text;
  final bool isUser;
}

class _AIChatScreen extends StatefulWidget {
  const _AIChatScreen();

  @override
  State<_AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<_AIChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      text:
          'Hello! I am your AI Health Assistant. How can I help you today?\n\n(Disclaimer: I provide general health info, not professional medical advice. Always consult a doctor for serious issues.)',
      isUser: false,
    ),
  ];
  bool _isTyping = false;

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      // Insert new messages at the beginning of the list for reverse scrolling
      _messages.insert(0, _ChatMessage(text: text, isUser: true));
      _controller.clear();
      _isTyping = true;
    });

    // Simulate an AI network delay
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.insert(
          0,
          _ChatMessage(
            text:
                'I understand you are asking about "$text". Because I am a simulated AI, I recommend discussing this with our human pharmacist. Is there anything else I can help you find?',
            isUser: false,
          ),
        );
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.smart_toy_outlined, color: Color(0xFF1B8F4A)),
            SizedBox(width: 8),
            Text('AI Assistant'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              reverse: true, // Makes the list scroll from bottom to top
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildChatBubble(msg);
              },
            ),
          ),
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'AI is typing...',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildChatBubble(_ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: msg.isUser ? const Color(0xFF1B8F4A) : const Color(0xFFEAF7EF),
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: msg.isUser
                ? const Radius.circular(4)
                : const Radius.circular(20),
            bottomLeft: !msg.isUser
                ? const Radius.circular(4)
                : const Radius.circular(20),
          ),
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            color: msg.isUser ? Colors.white : const Color(0xFF123A28),
            fontSize: 14.5,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Type a health question...',
                ),
              ),
            ),
            const SizedBox(width: 10),
            InkWell(
              onTap: _sendMessage,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: Color(0xFF1B8F4A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: Color(0xFF123A28),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFE4ECE8)),
        ),
        onTap: onTap,
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF7EF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: const Color(0xFF1B8F4A), size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
