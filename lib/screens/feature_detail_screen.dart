import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';

class FeatureDetail {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> highlights;
  final String technicalDetail;

  FeatureDetail({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.highlights,
    required this.technicalDetail,
  });
}

class FeatureDetailScreen extends StatelessWidget {
  final FeatureDetail feature;

  const FeatureDetailScreen({super.key, required this.feature});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04040C),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [feature.color.withValues(alpha: 0.4), Colors.transparent],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Center(
                    child: Icon(feature.icon, color: feature.color, size: 80)
                        .animate(onPlay: (c) => c.repeat())
                        .shimmer(duration: 2.seconds, color: Colors.white24)
                        .scale(duration: 1.seconds, curve: Curves.easeOut),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feature.title,
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn().slideX(),
                  const SizedBox(height: 16),
                  Text(
                    feature.description,
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white70,
                      fontSize: 18,
                      height: 1.6,
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 40),
                  
                  Text(
                    'Key Capabilities',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...feature.highlights.map((h) => _buildHighlightItem(h)),
                  
                  const SizedBox(height: 48),
                  
                  _buildTechnicalCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: feature.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check, color: feature.color, size: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.spaceGrotesk(color: Colors.white70, fontSize: 16),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideX();
  }

  Widget _buildTechnicalCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.terminal_rounded, color: feature.color, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Technical Architecture',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                feature.technicalDetail,
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white54,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 600.ms);
  }
}
