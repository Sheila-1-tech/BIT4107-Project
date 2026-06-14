import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../Widgets/custom_button.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  VideoPlayerController? _videoController;
  Future<void>? _videoInitializeFuture;

  @override
  void initState() {
    super.initState();
    _videoInitializeFuture = _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.asset('assets/videos/intro.mp4');
      await _videoController!.initialize();
      await _videoController!.setLooping(true);
      await _videoController!.setVolume(0);
      await _videoController!.play();
      if (mounted) setState(() {});
    } catch (_) {
      _videoController = null;
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _goToLogin(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _goToRegister(BuildContext context) {
    Navigator.pushNamed(context, '/register');
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Hero Section
            SizedBox(
              height: screenSize.height,
              width: screenSize.width,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildBackground(),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.15),
                          Colors.black.withValues(alpha: 0.85),
                        ],
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 104,
                                height: 104,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF1B8F4A,
                                      ).withValues(alpha: 0.4),
                                      blurRadius: 32,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                ),
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.local_pharmacy_rounded,
                                      size: 50,
                                      color: Color(0xFF1B8F4A),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 32),
                              const Text(
                                'Welcome to\nPharmacy App',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 34,
                                  height: 1.15,
                                  letterSpacing: -0.5,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Browse medicines, manage your orders, and get trusted pharmacy care in one place.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15.5,
                                  height: 1.5,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                              const SizedBox(height: 40),
                              CustomButton(
                                label: 'Login to your account',
                                onPressed: () => _goToLogin(context),
                                height: 56,
                                borderRadius: 18,
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton(
                                onPressed: () => _goToRegister(context),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(56),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    width: 1.5,
                                  ),
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.05,
                                  ),
                                ),
                                child: const Text(
                                  'Create an account',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              // 2. Social Proof & Trust Signals
                              _buildSocialProof(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 3. Why Choose Us Section
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    children: [
                      const Text(
                        'Why Choose Us',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF123A28),
                        ),
                      ),
                      const SizedBox(height: 48),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth > 600) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildFeatureItem(
                                    Icons.local_shipping_rounded,
                                    'Fast Delivery',
                                    'Get your prescriptions at your door in 30 minutes.',
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: _buildFeatureItem(
                                    Icons.verified_rounded,
                                    'Genuine Medicines',
                                    'Sourced directly from verified manufacturers.',
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: _buildFeatureItem(
                                    Icons.support_agent_rounded,
                                    '24/7 Support',
                                    'Chat with certified pharmacists anytime.',
                                  ),
                                ),
                              ],
                            );
                          }
                          return Column(
                            children: [
                              _buildFeatureItem(
                                Icons.local_shipping_rounded,
                                'Fast Delivery',
                                'Get your prescriptions at your door in 30 minutes.',
                              ),
                              const SizedBox(height: 40),
                              _buildFeatureItem(
                                Icons.verified_rounded,
                                'Genuine Medicines',
                                'Sourced directly from verified manufacturers.',
                              ),
                              const SizedBox(height: 40),
                              _buildFeatureItem(
                                Icons.support_agent_rounded,
                                '24/7 Support',
                                'Chat with certified pharmacists anytime.',
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // 4. Footer
            Container(
              width: double.infinity,
              color: const Color(0xFF0A1F15),
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    children: [
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 24,
                        runSpacing: 16,
                        children: [
                          _buildFooterLink('Privacy Policy'),
                          _buildFooterLink('Terms of Service'),
                          _buildFooterLink('Contact Support'),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Text(
                        '© ${DateTime.now().year} Pharmacy App. All rights reserved.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialProof() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: List.generate(
            5,
            (index) =>
                const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Trusted by 10,000+ patients',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.w600,
            fontSize: 14.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(
            color: Color(0xFFEAF7EF),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 36, color: const Color(0xFF1B8F4A)),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF123A28),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14.5,
            height: 1.5,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildFooterLink(String text) {
    return InkWell(
      onTap: () {},
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.7),
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildBackground() {
    final controller = _videoController;
    final future = _videoInitializeFuture;

    if (controller == null || future == null) {
      return SizedBox.expand(
        child: Image.asset(
          'assets/images/logo.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1B8F4A), Color(0xFF0D3C24)],
                ),
              ),
            );
          },
        ),
      );
    }

    return FutureBuilder<void>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            controller.value.isInitialized) {
          return SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            ),
          );
        }

        return SizedBox.expand(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1B8F4A), Color(0xFF0D3C24)],
              ),
            ),
          ),
        );
      },
    );
  }
}
