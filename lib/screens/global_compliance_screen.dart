import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class GlobalComplianceScreen extends StatelessWidget {
  const GlobalComplianceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04040C),
      body: Stack(
        children: [
          _buildBackground(),
          CustomScrollView(
            slivers: [
              _buildAppBar(context),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 32),
                      _buildMapVisual(),
                      const SizedBox(height: 40),
                      _buildRegionGrid(),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [Color(0xFF0D0D1A), Color(0xFF04040C)],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text('Global Regulatory Roadmap', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold)),
      actions: [
        IconButton(onPressed: () {}, icon: const Icon(Icons.download_rounded, color: Colors.white70)),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Market Deployment Readiness', style: GoogleFonts.spaceGrotesk(
          color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold,
        )).animate().fadeIn().slideX(begin: -0.1),
        const SizedBox(height: 12),
        Text('AI deployment status mapped against 50+ jurisdictional AI laws including EU AI Act, GDPR, and Indian DPDP.',
          style: TextStyle(color: Colors.white54, fontSize: 16, height: 1.5),
        ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
      ],
    );
  }

  Widget _buildMapVisual() {
    return Container(
      height: 400,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(Icons.public_rounded, size: 300, color: Colors.white.withOpacity(0.03)),
          ),
          // Regional Markers
          _mapMarker(150, 100, 'North America', 'REGULATED', Colors.orangeAccent),
          _mapMarker(250, 120, 'European Union', 'SAFE (EU AI Act v1)', const Color(0xFF10B981)),
          _mapMarker(180, 250, 'South America', 'SAFE', const Color(0xFF10B981)),
          _mapMarker(300, 220, 'India', 'HIGH RISK (DPDP Art.12)', const Color(0xFFEF4444)),
          _mapMarker(450, 150, 'East Asia', 'REGULATED', Colors.orangeAccent),
          _mapMarker(420, 300, 'Australia', 'SAFE', const Color(0xFF10B981)),
          
          Positioned(
            bottom: 24, left: 24,
            child: _mapLegend(),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).scale();
  }

  Widget _mapMarker(double x, double y, String name, String status, Color color) {
    return Positioned(
      left: x, top: y,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
            child: Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 2000.ms),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withOpacity(0.5))),
            child: Column(
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                Text(status, style: TextStyle(color: color, fontSize: 6, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _legendItem('SAFE TO DEPLOY', const Color(0xFF10B981)),
          _legendItem('REGULATORY CAUTION', Colors.orangeAccent),
          _legendItem('HIGH RISK / BANNED', const Color(0xFFEF4444)),
        ],
      ),
    );
  }

  Widget _legendItem(String text, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildRegionGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 2.5,
      children: [
        _regionCard('European Union', 'Compliant', 'Model passes all EU AI Act biometric categorization checks.', const Color(0xFF10B981)),
        _regionCard('India', 'High Risk', 'Caste and Location bias detected above DPDP safety thresholds.', const Color(0xFFEF4444)),
        _regionCard('USA (California)', 'Regulated', 'CPRA compliance verified for automated decision-making.', Colors.orangeAccent),
        _regionCard('Brazil', 'Compliant', 'LGPD requirements for algorithmic explanation met.', const Color(0xFF10B981)),
      ],
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }

  Widget _regionCard(String region, String status, String desc, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.language_rounded, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(region, style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
