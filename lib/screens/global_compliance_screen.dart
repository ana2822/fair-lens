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
          _buildAnimatedBackground(),
          CustomScrollView(
            slivers: [
              _buildAppBar(context),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 32),
                      _buildMainMap(),
                      const SizedBox(height: 40),
                      Text('Regional Risk Breakdown', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      _buildRegulatoryGrid(),
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

  Widget _buildAnimatedBackground() {
    return Stack(
      children: [
        Positioned.fill(child: Container(color: const Color(0xFF04040C))),
        Positioned(
          top: -100, right: -100,
          child: Container(
            width: 400, height: 400,
            decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF6366F1).withValues(alpha: 0.05), border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.1))),
          ).animate(onPlay: (c) => c.repeat()).rotate(duration: 20.seconds),
        ),
        Positioned(
          bottom: -150, left: -50,
          child: Container(
            width: 300, height: 300,
            decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF8B5CF6).withValues(alpha: 0.05), border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.1))),
          ).animate(onPlay: (c) => c.repeat()).rotate(duration: 15.seconds),
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text('Regulatory Intelligence', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.w800)),
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
          child: Row(children: [
            const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 14),
            const SizedBox(width: 6),
            Text('2026 Audit Ready', style: GoogleFonts.spaceGrotesk(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
          ]),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Global AI Roadmap', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, height: 1.1))
            .animate().fadeIn().slideX(begin: -0.1),
        const SizedBox(height: 12),
        Text('FairLens maps your deployment readiness across 50+ jurisdictions using live legal mapping for the EU AI Act, India DPDP, and GDPR.',
          style: GoogleFonts.spaceGrotesk(color: Colors.white54, fontSize: 16, height: 1.5),
        ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
      ],
    );
  }

  Widget _buildMainMap() {
    return Container(
      height: 440,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            // Abstract Map Grid
            CustomPaint(painter: _GridPainter(), size: Size.infinite),
            Center(child: Icon(Icons.public_rounded, size: 400, color: Colors.white.withValues(alpha: 0.02))),
            
            // Interaction Markers
            _marker(120, 100, 'USA', 'CAID Law', const Color(0xFFF59E0B)),
            _marker(220, 130, 'EU', 'AI Act v1.0', const Color(0xFF10B981)),
            _marker(200, 240, 'Brazil', 'LGPD', const Color(0xFF10B981)),
            _marker(310, 210, 'India', 'DPDP Art. 12', const Color(0xFFEF4444)),
            _marker(420, 160, 'Japan', 'Soft Law', const Color(0xFFF59E0B)),
            _marker(400, 280, 'Australia', 'Framework', const Color(0xFF10B981)),

            Positioned(
              bottom: 24, right: 24,
              child: _mapLegend(),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _marker(double x, double y, String name, String law, Color color) {
    return Positioned(
      left: x, top: y,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 10)])),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(duration: 1.seconds, begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Column(children: [
                  Text(name, style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  Text(law, style: GoogleFonts.spaceGrotesk(color: color, fontSize: 8, fontWeight: FontWeight.w900)),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapLegend() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _legendItem('SAFE DEPLOYMENT', const Color(0xFF10B981)),
              const SizedBox(height: 8),
              _legendItem('REGULATED / CAUTION', const Color(0xFFF59E0B)),
              const SizedBox(height: 8),
              _legendItem('HIGH RISK / RESTRICTED', const Color(0xFFEF4444)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legendItem(String text, Color color) {
    return Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 10),
      Text(text, style: GoogleFonts.spaceGrotesk(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
    ]);
  }

  Widget _buildRegulatoryGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: [
        _riskCard('European Union', 'EU AI ACT (2024)', 'Biometric categorization passes all Article 10 transparency checks.', const Color(0xFF10B981), Icons.euro_symbol_rounded),
        _riskCard('India', 'DPDP ACT / ART. 14', 'Caste and Location bias detected. High Risk per Article 16 guidelines.', const Color(0xFFEF4444), Icons.location_on_rounded),
        _riskCard('United States', 'CAID / EEOC', 'Algorithmic accountability audit required for hiring modules.', const Color(0xFFF59E0B), Icons.gavel_rounded),
        _riskCard('Global South', 'GDPR ALIGNMENT', 'Compliance verified for Right to Explanation across 12 markets.', const Color(0xFF10B981), Icons.public_rounded),
      ],
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1);
  }

  Widget _riskCard(String title, String law, String desc, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.3))),
              child: Text(color == const Color(0xFF10B981) ? 'SAFE' : (color == const Color(0xFFEF4444) ? 'RISK' : 'REGULATED'), style: GoogleFonts.spaceGrotesk(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 16),
          Text(title, style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(law, style: GoogleFonts.spaceGrotesk(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 8),
          Expanded(child: Text(desc, style: GoogleFonts.spaceGrotesk(color: Colors.white54, fontSize: 12, height: 1.4))),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1.0;
    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override
  bool shouldRepaint(_) => false;
}
