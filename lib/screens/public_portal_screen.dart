import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class PublicPortalScreen extends StatelessWidget {
  const PublicPortalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04040C),
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                color: const Color(0xFF06B6D4).withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          CustomScrollView(
            slivers: [
              _buildAppBar(context),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 32),
                      _buildTrustMetrics(),
                      const SizedBox(height: 32),
                      _buildTransparencyLog(),
                      const SizedBox(height: 32),
                      _buildCertificateSection(),
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

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: const Color(0xFF0D0D1A).withValues(alpha: 0.8),
      floating: true,
      pinned: true,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          const Icon(Icons.public_rounded, color: Color(0xFF06B6D4), size: 20),
          const SizedBox(width: 12),
          Text('Public Transparency Portal', style: GoogleFonts.spaceGrotesk(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18,
          )),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 16),
          label: Text('VERIFIED BY CITIZENS', style: GoogleFonts.spaceGrotesk(
            color: const Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold,
          )),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Institutional Accountability Dashboard', style: GoogleFonts.spaceGrotesk(
          color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold,
        )).animate().fadeIn().slideX(begin: -0.1),
        const SizedBox(height: 12),
        Text(
          'Real-time transparency into how AI systems are making decisions. We believe in algorithmic accountability and public trust.',
          style: GoogleFonts.inter(color: Colors.white54, fontSize: 16, height: 1.5),
        ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
      ],
    );
  }

  Widget _buildTrustMetrics() {
    return Row(
      children: [
        _metricCard('Public Fairness', '92%', 'Trust Score', const Color(0xFF10B981)),
        const SizedBox(width: 16),
        _metricCard('Audit Frequency', 'Daily', 'Automated', const Color(0xFF8B5CF6)),
        const SizedBox(width: 16),
        _metricCard('Citizen Reports', '0', 'Resolved', const Color(0xFF06B6D4)),
      ],
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _metricCard(String label, String value, String sub, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.spaceGrotesk(color: Colors.white60, fontSize: 12)),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.spaceGrotesk(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(sub, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildTransparencyLog() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Immutable Decision Log', style: GoogleFonts.spaceGrotesk(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold,
              )),
              TextButton(onPressed: () {}, child: const Text('Download CSV')),
            ],
          ),
          const SizedBox(height: 16),
          _logEntry('2024-04-24', 'Scholarship Batch #4902', '98% Fairness Pass', true),
          _logEntry('2024-04-23', 'Scholarship Batch #4891', '94% Fairness Pass', true),
          _logEntry('2024-04-22', 'Model Retraining Event', 'Safety Protocol Updated', true),
          _logEntry('2024-04-21', 'Public Audit Triggered', 'Manual Review Completed', true),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }

  Widget _logEntry(String date, String event, String status, bool pass) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Text(date, style: GoogleFonts.jetBrainsMono(color: Colors.white24, fontSize: 12)),
          const SizedBox(width: 16),
          Expanded(child: Text(event, style: const TextStyle(color: Colors.white70))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (pass ? const Color(0xFF10B981) : Colors.red).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(status, style: TextStyle(
              color: pass ? const Color(0xFF10B981) : Colors.red,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificateSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF10B981).withValues(alpha: 0.1), Colors.transparent],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium_rounded, color: Color(0xFF10B981), size: 48),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Fairness Certificate 2024', style: GoogleFonts.spaceGrotesk(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold,
                )),
                const SizedBox(height: 8),
                const Text(
                  'This system has been independently verified to meet the highest standards of algorithmic fairness.',
                  style: TextStyle(color: Colors.white60, fontSize: 14, height: 1.4),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Verify Signature'),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }
}
