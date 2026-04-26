import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'dart:ui';
import '../widgets/top_nav.dart';
import '../widgets/radial_particles.dart';
import '../services/dataset_service.dart';

import 'feature_detail_screen.dart';
import 'global_compliance_screen.dart';
import '../services/gemini_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _isLoading = false;
  String? _error;
  late AnimationController _pulseController;
  late AnimationController _floatController;
  late AnimationController _orbitController;
  late AnimationController _ring2Controller;
  late AnimationController _portalPulseController;
  late AnimationController _colorCycleController;
  late AnimationController _shimmerController;
  late Animation<Color?> _glowColorAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this, duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _floatController = AnimationController(
      vsync: this, duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _orbitController = AnimationController(
      vsync: this, duration: const Duration(seconds: 20),
    )..repeat();
    _ring2Controller = AnimationController(
      vsync: this, duration: const Duration(seconds: 30),
    )..repeat();
    _portalPulseController = AnimationController(
      vsync: this, duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    
    _colorCycleController = AnimationController(
      vsync: this, duration: const Duration(seconds: 12),
    )..repeat();
    
    _shimmerController = AnimationController(
      vsync: this, duration: const Duration(seconds: 4),
    )..repeat();

    _glowColorAnimation = TweenSequence<Color?>([
      TweenSequenceItem(weight: 1.0, tween: ColorTween(begin: const Color(0xFF7C3AED), end: const Color(0xFF0EA5E9))), // Violet to Cerulean
      TweenSequenceItem(weight: 1.0, tween: ColorTween(begin: const Color(0xFF0EA5E9), end: const Color(0xFF2DD4BF))), // Cerulean to Teal
      TweenSequenceItem(weight: 1.0, tween: ColorTween(begin: const Color(0xFF2DD4BF), end: const Color(0xFF7C3AED))), // Teal back to Violet
    ]).animate(_colorCycleController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatController.dispose();
    _orbitController.dispose();
    _ring2Controller.dispose();
    _portalPulseController.dispose();
    _colorCycleController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  // ── EXACT SAME LOGIC ────────────────────────────────────────
  Future<void> _pickAndAnalyze() async {
    DatasetService.pickAndAnalyze(
      context,
      setLoading: (l) {
        if (mounted) setState(() => _isLoading = l);
      },
      setError: (e) {
        if (mounted) setState(() => _error = e);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: const Color(0xFF04040C),
      body: Stack(children: [
        // Animated grid
        Positioned.fill(child: CustomPaint(painter: _GridPainter())),

        // Orbiting glow blobs
        AnimatedBuilder(animation: _orbitController, builder: (_, __) {
          final angle = _orbitController.value * 2 * math.pi;
          return Stack(children: [
            Positioned(
              left: w * 0.5 + math.cos(angle) * 180 - 200,
              top: -100 + math.sin(angle * 0.7) * 60,
              child: _glowBlob(const Color(0xFF6366F1), 400),
            ),
            Positioned(
              right: -80 + math.cos(angle + math.pi) * 80,
              bottom: -60 + math.sin(angle * 0.5) * 40,
              child: _glowBlob(const Color(0xFF8B5CF6), 350),
            ),
            Positioned(
              left: w * 0.7 + math.sin(angle * 1.3) * 60,
              top: 200 + math.cos(angle * 0.8) * 80,
              child: _glowBlob(const Color(0xFF06B6D4), 180),
            ),
          ]);
        }),

        SafeArea(child: SingleChildScrollView(
          child: Column(children: [
            const TopNav(activeItem: 'Home'),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: w > 900 ? 80 : 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 52),
                _buildHero(),
                const SizedBox(height: 56),
                _buildUploadCard(),
                if (_error != null) _buildError(),
                const SizedBox(height: 64),
                _buildStatsRow(),
                const SizedBox(height: 64),
                _buildFeatureGrid(),
                const SizedBox(height: 64),
                _buildHowItWorks(),
                const SizedBox(height: 64),
                _buildLiveTicker(),
                const SizedBox(height: 64),
                _buildSampleDatasets(),
                const SizedBox(height: 64),
                _buildApiBlock(),
                const SizedBox(height: 64),
                _buildFooter(),
                const SizedBox(height: 40),
              ]),
            ),
          ]),
        )),
        
        // 🤖 AGENTIC AUDITOR FLOATING CHAT
        _buildAgenticAuditor(),
      ]),
    );
  }

// ── HERO ─────────────────────────────────────────────────────
  Widget _buildHero() {
    final screenWidth = MediaQuery.of(context).size.width;
    final portalSize = math.min(screenWidth * 0.85, 900.0);

    return SizedBox(
      width: double.infinity,
      height: portalSize * 0.9 + 200, // Explicit height for containment
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.hardEdge,
        children: [
          // ── Background Effects (Grid, Orb, Particles) ──
          Positioned(
            top: 140, // Below the badge
            child: SizedBox(
              width: portalSize,
              height: portalSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 1. Background Grid (Multi-concentric dashed rings)
                  AnimatedBuilder(
                    animation: _orbitController,
                    builder: (_, __) => Transform.rotate(
                      angle: _orbitController.value * 2 * math.pi * 0.2, // Very slow internal rotation
                      child: CustomPaint(
                        size: Size(portalSize, portalSize),
                        painter: _MultiConcentricGridPainter(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                  ),

                  // 2. Contained Particle Stream
                  RadialParticles(
                    colorAnimation: _glowColorAnimation,
                    maxRadius: portalSize * 0.48, // Fade out before edge
                  ),

                  // 3. Central Glow Orb (Nebula)
                  AnimatedBuilder(
                    animation: Listenable.merge([_portalPulseController, _colorCycleController]),
                    builder: (_, __) {
                      final t = _portalPulseController.value;
                      final baseColor = _glowColorAnimation.value ?? const Color(0xFF7C3AED);
                      
                      return Container(
                        width: portalSize * 0.45,
                        height: portalSize * 0.45,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              baseColor.withValues(alpha: 0.6 + 0.2 * t),
                              baseColor.withValues(alpha: 0.15 + 0.1 * t),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // ── Foreground Content ──
          Positioned.fill(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center, 
              children: [
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.25)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    _pulseDot(const Color(0xFF10B981)),
                    const SizedBox(width: 8),
                    Text('Google Solution Challenge 2026 • AI Fairness Platform',
                      style: GoogleFonts.spaceGrotesk(
                        color: const Color(0xFF818CF8), fontSize: 12, fontWeight: FontWeight.w500)),
                  ]),
                ).animate().fadeIn(delay: 100.ms).slideY(begin: -0.05),

                const SizedBox(height: 100), // Space to center text over the orb

                // Text Shimmer H1
                AnimatedBuilder(
                  animation: Listenable.merge([_shimmerController, _colorCycleController, _floatController]),
                  builder: (_, child) {
                    final shimmerColor = _glowColorAnimation.value ?? const Color(0xFF7C3AED);
                    final shimmerPos = _shimmerController.value; // 0 to 1
                    
                    return Transform.translate(
                      offset: Offset(0, math.sin(_floatController.value * math.pi) * 4),
                      child: ShaderMask(
                        shaderCallback: (b) => LinearGradient(
                          colors: [
                            const Color(0xFFE8E8F0),
                            const Color(0xFFFFFFFF),
                            shimmerColor.withValues(alpha: 0.9), // Shimmer highlight
                            const Color(0xFFFFFFFF),
                            const Color(0xFFC7C7D4),
                          ],
                          stops: [
                            0.0,
                            math.max(0.0, shimmerPos - 0.2),
                            shimmerPos,
                            math.min(1.0, shimmerPos + 0.2),
                            1.0,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(b),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    'Detect Hidden\nBias. Build\nFair AI.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: screenWidth > 900 ? 96 : (screenWidth > 600 ? 72 : 52),
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                      letterSpacing: -3,
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 48),

                // Sub-headline
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: math.min(screenWidth * 0.72, 600)),
                  child: Text(
                    'Upload any dataset — hiring, loans, medical or HR. FairLens uses Gemini AI to detect algorithmic bias, map legal risks and generate a debiased dataset instantly.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white.withValues(alpha: 0.48),
                      fontSize: 16, height: 1.7,
                    ),
                  ),
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 36),

                // CTAs
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  alignment: WrapAlignment.center,
                  children: [
                    _heroCTA('Upload Dataset', Icons.cloud_upload_outlined, true, _pickAndAnalyze),
                    _heroCTA('Try Sample Dataset', Icons.play_circle_outline_rounded, false, _pickAndAnalyze),
                  ]
                ).animate().fadeIn(delay: 420.ms),

                const SizedBox(height: 36),

                // Trust chips
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    _trustChip(Icons.verified_rounded, 'GDPR Article 22', const Color(0xFF10B981)),
                    _trustChip(Icons.gavel_rounded, 'Indian Law Mapped', const Color(0xFF6366F1)),
                    _trustChip(Icons.psychology_rounded, 'Gemini Powered', const Color(0xFF8B5CF6)),
                  ]
                ).animate().fadeIn(delay: 500.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroCTA(String label, IconData icon, bool primary, VoidCallback onTap) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
        decoration: BoxDecoration(
          gradient: primary ? const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]) : null,
          color: primary ? null : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: primary ? null : Border.all(color: Colors.white.withValues(alpha: 0.12)),
          boxShadow: primary ? [BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.45),
            blurRadius: 24, offset: const Offset(0, 8),
          )] : null,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 17, color: primary ? Colors.white : Colors.white60),
          const SizedBox(width: 9),
          Text(label, style: GoogleFonts.spaceGrotesk(
            color: primary ? Colors.white : Colors.white60,
            fontSize: 15, fontWeight: FontWeight.w700)),
        ]),
      ),
    );

  Widget _trustChip(IconData icon, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 6),
      Text(label, style: GoogleFonts.spaceGrotesk(
        color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    ]),
  );

  // ── UPLOAD CARD ──────────────────────────────────────────────
  Widget _buildUploadCard() {
    return _Tilt3DCard(
      child: GestureDetector(
        onTap: _isLoading ? null : _pickAndAnalyze,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (_, __) => Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 52, horizontal: 40),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Color.lerp(
                  const Color(0xFF6366F1).withValues(alpha: 0.3),
                  const Color(0xFF8B5CF6).withValues(alpha: 0.6),
                  _pulseController.value,
                )!,
                width: 1.5,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF6366F1).withValues(alpha: 0.06),
                  const Color(0xFF8B5CF6).withValues(alpha: 0.04),
                  Colors.black.withValues(alpha: 0.3),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(
                    alpha: 0.06 + 0.1 * _pulseController.value),
                  blurRadius: 60, spreadRadius: 10,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: _isLoading ? _buildLoadingState() : _buildIdleUpload(),
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 550.ms).scale(begin: const Offset(0.96, 0.96));
  }

  Widget _buildLoadingState() => Column(children: [
    SizedBox(
      width: 52, height: 52,
      child: Stack(alignment: Alignment.center, children: [
        const CircularProgressIndicator(
          color: Color(0xFF6366F1), strokeWidth: 2.5),
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withValues(alpha: 0.15),
            shape: BoxShape.circle),
          child: const Icon(Icons.analytics_rounded,
            color: Color(0xFF818CF8), size: 16),
        ),
      ]),
    ),
    const SizedBox(height: 20),
    Text('Scanning for bias patterns...', style: GoogleFonts.spaceGrotesk(
      color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600)),
    const SizedBox(height: 8),
    Text('Running 12+ fairness checks with Gemini AI',
      style: GoogleFonts.spaceGrotesk(color: Colors.white38, fontSize: 13)),
    const SizedBox(height: 20),
    SizedBox(width: 260, child: ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        backgroundColor: Colors.white.withValues(alpha: 0.06),
        valueColor: const AlwaysStoppedAnimation(Color(0xFF6366F1)),
        minHeight: 3,
      ),
    )),
  ]);

  Widget _buildIdleUpload() => Column(children: [
    // Animated upload icon
    AnimatedBuilder(
      animation: _floatController,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, math.sin(_floatController.value * math.pi) * 5),
        child: child,
      ),
      child: Container(
        width: 72, height: 72,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.4),
            blurRadius: 28, spreadRadius: 4,
          )],
        ),
        child: const Icon(Icons.upload_file_rounded, color: Colors.white, size: 34),
      ),
    ),
    const SizedBox(height: 22),
    Text('Drop your CSV dataset here',
      style: GoogleFonts.spaceGrotesk(
        color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
    const SizedBox(height: 10),
    Text('Supports hiring, loan, medical, HR & education datasets',
      style: GoogleFonts.spaceGrotesk(color: Colors.white38, fontSize: 14)),
    const SizedBox(height: 28),

    // Format hints
    Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 10, children: [
      _uploadHint(Icons.table_chart_rounded, 'CSV Format'),
      _uploadHint(Icons.speed_rounded, '< 2 seconds'),
      _uploadHint(Icons.lock_outline_rounded, 'Never stored'),
      _uploadHint(Icons.psychology_rounded, 'Gemini AI'),
    ]),
    const SizedBox(height: 28),

    // Big CTA
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(
          color: const Color(0xFF6366F1).withValues(alpha: 0.4),
          blurRadius: 24, offset: const Offset(0, 6),
        )],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.folder_open_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Text('Choose CSV File', style: GoogleFonts.spaceGrotesk(
          color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
      ]),
    ),
  ]);

  Widget _uploadHint(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: const Color(0xFF818CF8)),
      const SizedBox(width: 6),
      Text(label, style: GoogleFonts.spaceGrotesk(
        color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w500)),
    ]),
  );

  // ── ERROR ─────────────────────────────────────────────────
  Widget _buildError() => Container(
    margin: const EdgeInsets.only(top: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFEF4444).withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.25)),
    ),
    child: Row(children: [
      const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 18),
      const SizedBox(width: 10),
      Expanded(child: Text(_error!, style: GoogleFonts.spaceGrotesk(
        color: const Color(0xFFEF4444), fontSize: 13))),
    ]),
  );

  // ── STATS ROW ────────────────────────────────────────────────
  Widget _buildStatsRow() {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final stats = [
      ('500K+', 'Datasets Analyzed', const Color(0xFF6366F1), Icons.dataset_rounded),
      ('98.4%', 'Detection Accuracy', const Color(0xFF10B981), Icons.verified_rounded),
      ('12+', 'Bias Categories', const Color(0xFF8B5CF6), Icons.category_rounded),
      ('4', 'Laws Mapped', const Color(0xFFF59E0B), Icons.gavel_rounded),
    ];
    
    final cards = stats.asMap().entries.map((e) {
      final s = e.value;
      return Container(
        margin: EdgeInsets.only(
          left: (isDesktop && e.key != 0) ? 12 : 0,
          bottom: (!isDesktop) ? 12 : 0,
        ),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: s.$3.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: s.$3.withValues(alpha: 0.18)),
          boxShadow: [BoxShadow(
            color: s.$3.withValues(alpha: 0.06),
            blurRadius: 20, spreadRadius: 1,
          )],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: s.$3.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(s.$4, color: s.$3, size: 18),
          ),
          const SizedBox(height: 14),
          Text(s.$1, style: GoogleFonts.spaceGrotesk(
            color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          Text(s.$2, style: GoogleFonts.spaceGrotesk(
            color: Colors.white38, fontSize: 12)),
        ]),
      );
    }).toList();

    return isDesktop 
      ? Row(children: cards.map((c) => Expanded(child: c)).toList()).animate().fadeIn(delay: 150.ms)
      : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: cards).animate().fadeIn(delay: 150.ms);
  }

  // ── FEATURE GRID ─────────────────────────────────────────────
  Widget _buildFeatureGrid() {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final features = [
      (
        const Color(0xFF6366F1), Icons.manage_search_rounded, '🔍',
        'Bias Detection',
        'Detects 12+ bias types across gender, age, caste, race, location and more from any CSV dataset.',
        ['Gender', 'Age', 'Caste', 'Location'],
        '82% avg bias score in hiring',
      ),
      (
        const Color(0xFF8B5CF6), Icons.gavel_rounded, '⚖️',
        'Legal Risk Mapping',
        'Maps every bias finding to specific Indian laws, GDPR Article 22 and the EU AI Act automatically.',
        ['Equal Rem. Act', 'Art.14-16', 'GDPR Art.22'],
        '4 laws checked per column',
      ),
      (
        const Color(0xFF06B6D4), Icons.psychology_rounded, '🤖',
        'Gemini AI Insights',
        'Get plain-English explanations written by Gemini — what the bias means and how it affects people.',
        ['Executive summary', 'Legal risk', 'Action steps'],
        'Powered by Gemini 1.5 Flash',
      ),
      (
        const Color(0xFF10B981), Icons.insert_chart_rounded, '📊',
        'Visual Analytics',
        'Interactive bar charts, bias heatmaps, group comparison charts and feature importance maps.',
        ['Bar charts', 'Heatmaps', 'Group rates'],
        'fl_chart powered visuals',
      ),
      (
        const Color(0xFFF59E0B), Icons.auto_fix_high_rounded, '🛠️',
        'Auto Bias Fix',
        'Removes or anonymizes high-risk columns. Download a cleaned, debiased CSV dataset instantly.',
        ['Remove cols', 'Anonymize', 'Download CSV'],
        'Up to 68% bias reduction',
      ),
      (
        const Color(0xFFEF4444), Icons.picture_as_pdf_rounded, '📄',
        'PDF Report Export',
        'Generates a shareable HTML/PDF report with full bias analysis, charts and AI recommendations.',
        ['Full report', 'Charts', 'Shareable link'],
        'One-click export',
      ),
    ];

    if (!isDesktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionLabel('Capabilities'),
          const SizedBox(height: 20),
          ...features.asMap().entries.map((e) {
            final f = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _simpleFeatureCard(f.$1, f.$2, f.$4, f.$5, f.$6, e.key, f.$7),
            );
          }),
        ],
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionLabel('Capabilities'),
      const SizedBox(height: 20),
      Row(children: features.sublist(0, 3).asMap().entries.map((e) {
        final f = e.value;
        return Expanded(child: Padding(
          padding: EdgeInsets.only(left: e.key == 0 ? 0 : 12),
          child: _simpleFeatureCard(f.$1, f.$2, f.$4, f.$5, f.$6, e.key, f.$7),
        ));
      }).toList()),
      const SizedBox(height: 12),
      Row(children: features.sublist(3, 6).asMap().entries.map((e) {
        final f = e.value;
        return Expanded(child: Padding(
          padding: EdgeInsets.only(left: e.key == 0 ? 0 : 12),
          child: _simpleFeatureCard(f.$1, f.$2, f.$4, f.$5, f.$6, e.key + 3, f.$7),
        ));
      }).toList()),
    ]);
  }

  Widget _simpleFeatureCard(Color color, IconData icon, String title,
      String desc, List<String> tags, int index, String technical) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FeatureDetailScreen(
              feature: FeatureDetail(
                title: title,
                description: desc,
                icon: icon,
                color: color,
                highlights: tags.map((t) => 'Advanced $t protection and auditing system.').toList(),
                technicalDetail: technical,
              ),
            ),
          ),
        );
      },
      child: Container(
        height: 190,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withValues(alpha: 0.08), const Color(0xFF0D0D1A)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Text('ACTIVE', style: TextStyle(
                  color: color, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
              ),
            ]),
            const SizedBox(height: 14),
            Text(title, style: GoogleFonts.spaceGrotesk(
              color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Expanded(child: Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white38, fontSize: 11, height: 1.5))),
            const SizedBox(height: 10),
            Row(children: tags.take(2).map((t) => Container(
              margin: const EdgeInsets.only(right: 5),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Text(t, style: TextStyle(
              color: color, fontSize: 9, fontWeight: FontWeight.w600)),
          )).toList()),
        ],
      ),
    ),
    ).animate().fadeIn(delay: Duration(milliseconds: 80 * index));
  }

  // ── HOW IT WORKS ─────────────────────────────────────────────
  Widget _buildHowItWorks() {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final steps = [
      (const Color(0xFF6366F1), Icons.upload_file_rounded, '01', 'Upload Your CSV',
        'Drop any dataset — hiring data, loan applications, medical records, HR reviews or education data. Any CSV works.',
        '< 5MB recommended'),
      (const Color(0xFF8B5CF6), Icons.analytics_rounded, '02', 'FairLens Scans',
        'Our engine checks every column against 12+ bias types using statistical fairness metrics like Disparate Impact and Statistical Parity.',
        '~1.2s average'),
      (const Color(0xFF06B6D4), Icons.psychology_rounded, '03', 'Gemini Explains',
        'Gemini AI writes a plain-English executive report — what the bias means, who it affects and which laws are violated.',
        'Powered by Gemini 1.5'),
      (const Color(0xFF10B981), Icons.download_done_rounded, '04', 'Fix & Export',
        'Download a debiased CSV with high-risk columns removed or anonymized. Export a shareable PDF report.',
        'One click'),
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionLabel('How It Works'),
      const SizedBox(height: 24),
      if (isDesktop)
        Row(crossAxisAlignment: CrossAxisAlignment.start,
          children: steps.asMap().entries.map((e) {
            final s = e.value;
            final isLast = e.key == steps.length - 1;
            return Expanded(child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _StepCard(
                  color: s.$1,
                  icon: s.$2,
                  number: s.$3,
                  title: s.$4,
                  desc: s.$5,
                  metric: s.$6,
                  index: e.key,
                )),
                if (!isLast) Padding(
                  padding: const EdgeInsets.only(top: 28),
                  child: Icon(Icons.arrow_forward_rounded,
                    color: Colors.white.withValues(alpha: 0.12), size: 22),
                ),
              ],
            ));
          }).toList(),
        )
      else
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: steps.asMap().entries.map((e) {
            final s = e.value;
            final isLast = e.key == steps.length - 1;
            return Column(
              children: [
                _StepCard(
                  color: s.$1,
                  icon: s.$2,
                  number: s.$3,
                  title: s.$4,
                  desc: s.$5,
                  metric: s.$6,
                  index: e.key,
                ),
                if (!isLast) Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Icon(Icons.arrow_downward_rounded,
                    color: Colors.white.withValues(alpha: 0.12), size: 22),
                ),
              ],
            );
          }).toList(),
        ),
    ]);
  }

  // ── LIVE TICKER ──────────────────────────────────────────────
  Widget _buildLiveTicker() {
    final events = [
      ('hiring_q3_2024.csv', '72/100', const Color(0xFFEF4444), 'CRITICAL'),
      ('loan_applications.csv', '41/100', const Color(0xFFF59E0B), 'HIGH'),
      ('medical_records.csv', '28/100', const Color(0xFFF59E0B), 'MEDIUM'),
      ('hr_reviews_2024.csv', '14/100', const Color(0xFF10B981), 'LOW'),
      ('admissions_data.csv', '63/100', const Color(0xFFEF4444), 'CRITICAL'),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionLabel('Recent Analyses'),
      const SizedBox(height: 16),
      Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Column(children: events.asMap().entries.map((e) {
          final item = e.value;
          final isLast = e.key == events.length - 1;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              border: isLast ? null : Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
            ),
            child: Row(children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: item.$3.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(Icons.insert_drive_file_rounded, color: item.$3, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(child: Text(item.$1, style: GoogleFonts.spaceGrotesk(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
              Text(item.$2, style: GoogleFonts.spaceGrotesk(
                color: item.$3, fontSize: 15,
                fontWeight: FontWeight.w800)),
              const SizedBox(width: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: item.$3.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: item.$3.withValues(alpha: 0.25)),
                ),
                child: Text(item.$4, style: TextStyle(
                  color: item.$3, fontSize: 10,
                  fontWeight: FontWeight.w800, letterSpacing: 1)),
              ),
            ]),
          );
        }).toList()),
      ),
    ]).animate().fadeIn(delay: 100.ms);
  }

  // ── SAMPLE DATASETS ──────────────────────────────────────────
  Widget _buildSampleDatasets() {
    final samples = [
      ('👩\u200d💼', 'Hiring Dataset', 'Gender & age bias in tech hiring', const Color(0xFF6366F1), '72/100'),
      ('🏦', 'Loan Dataset', 'Caste & location bias in approvals', const Color(0xFF8B5CF6), '58/100'),
      ('🏥', 'Medical Dataset', 'Race bias in diagnosis rates', const Color(0xFF10B981), '34/100'),
      ('🎓', 'Education Dataset', 'Socioeconomic bias in admissions', const Color(0xFFF59E0B), '47/100'),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionLabel('Try a Sample Dataset'),
      const SizedBox(height: 18),
      LayoutBuilder(builder: (context, constraints) {
        final cols = constraints.maxWidth < 500 ? 1 : constraints.maxWidth < 800 ? 2 : 4;
        return GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: cols == 1 ? 2.5 : cols == 2 ? 1.6 : 1.3,
          children: samples.map((s) => GestureDetector(
            onTap: _pickAndAnalyze,
            child: _SampleCard(
              emoji: s.$1, title: s.$2,
              desc: s.$3, color: s.$4, score: s.$5,
            ),
          )).toList(),
        );
      }),
    ]);
  }

  // ── API BLOCK ─────────────────────────────────────────────
  Widget _buildApiBlock() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionLabel('Developer API'),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.2)),
          boxShadow: [BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.05),
            blurRadius: 30, spreadRadius: 2,
          )],
        ),
        child: LayoutBuilder(builder: (ctx, box) {
          final isWide = box.maxWidth > 560;

          final leftCol = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Integrate FairLens into\nyour CI/CD pipeline',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.3)),
            const SizedBox(height: 10),
            Text('Automatically reject biased models before deployment.\nWorks with any ML framework.',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white38, fontSize: 14, height: 1.6)),
            const SizedBox(height: 22),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _trustChip(Icons.bolt_rounded, 'REST API', const Color(0xFF6366F1)),
              _trustChip(Icons.code_rounded, 'Python SDK', const Color(0xFF10B981)),
              _trustChip(Icons.webhook_rounded, 'Webhooks', const Color(0xFF8B5CF6)),
            ]),
          ]);
          final rightCol = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6)),
                child: Text('POST', style: GoogleFonts.spaceMono(
                  color: const Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 11)),
              ),
              const SizedBox(width: 10),
              Flexible(child: Text('api.fairlens.dev/v1/analyze',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.spaceMono(color: Colors.white54, fontSize: 12))),
            ]),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Text(
'''{
  "dataset_url": "s3://data/hiring.csv",
  "domain": "hiring",
  "auto_fix": true,
  "notify_webhook": "https://..."
}''',
                style: GoogleFonts.spaceMono(
                  color: const Color(0xFF818CF8), fontSize: 12, height: 1.6)),
            ),
          ]);
          return isWide
            ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [leftCol])),
                const SizedBox(width: 32),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [rightCol])),
              ])
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                leftCol, const SizedBox(height: 24), rightCol,
              ]);
        }),

      ),
    ]).animate().fadeIn(delay: 100.ms);
  }

  // ── FOOTER ───────────────────────────────────────────────────
  Widget _buildFooter() {
    return Column(children: [
      Container(height: 1, color: Colors.white.withValues(alpha: 0.07)),
      const SizedBox(height: 30),
      LayoutBuilder(builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        final brand = Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(Icons.lens_blur_rounded, color: Colors.white, size: 15),
          ),
          const SizedBox(width: 8),
          Text('FairLens', style: GoogleFonts.spaceGrotesk(
            color: Colors.white54, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(width: 12),
          Flexible(child: Text('Built for Google Solution Challenge 2026',
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.spaceGrotesk(color: Colors.white24, fontSize: 12))),
        ]);
        final links = Wrap(spacing: 20, runSpacing: 8, children: [
          _footerLink('GitHub'),
          _footerLink('Docs'),
          _footerLink('About'),
          _footerLink('Privacy'),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GlobalComplianceScreen())),
            child: _footerLink('Roadmap')
          ),
        ]);
        return isWide
          ? Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Flexible(child: brand), links])
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [brand, const SizedBox(height: 16), links]);
      }),
    ]);
  }

  Widget _footerLink(String t) => Text(t, style: GoogleFonts.spaceGrotesk(
    color: Colors.white30, fontSize: 12));

  Widget _buildAgenticAuditor() {
    return const Positioned(
      bottom: 32, right: 32,
      child: _AgenticAuditorWidget(),
    );
  }

  // ── HELPERS ──────────────────────────────────────────────────
  Widget _sectionLabel(String text) => Row(children: [
    Container(
      width: 3, height: 16,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter),
        borderRadius: BorderRadius.circular(2),
      ),
    ),
    const SizedBox(width: 10),
    Text(text.toUpperCase(), style: GoogleFonts.spaceGrotesk(
      color: Colors.white38, fontSize: 11,
      fontWeight: FontWeight.w700, letterSpacing: 2.5)),
  ]);

  Widget _glowBlob(Color color, double size) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.0)]),
    ),
  );

  Widget _pulseDot(Color color) => AnimatedBuilder(
    animation: _pulseController,
    builder: (_, __) => Container(
      width: 7, height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(
          color: color.withValues(alpha: 0.4 + 0.4 * _pulseController.value),
          blurRadius: 6 + 4 * _pulseController.value,
        )],
      ),
    ),
  );
}

// ════════════════════════════════════════════════════════════
//  AGENTIC AUDITOR — floating AI chat assistant
// ════════════════════════════════════════════════════════════
class _AgenticAuditorWidget extends StatefulWidget {
  const _AgenticAuditorWidget();
  @override
  State<_AgenticAuditorWidget> createState() => _AgenticAuditorWidgetState();
}

class _AgenticAuditorWidgetState extends State<_AgenticAuditorWidget>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  bool _isLoading = false;

  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<Map<String, String>> _messages = [
    {'role': 'model', 'text': 'Hi! I\'m your Agentic Auditor — ask me anything about AI fairness, bias types, or legal compliance.'},
  ];

  late AnimationController _pulseCtrl;
  Timer? _idleTimer;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Idle collapse: collapse after 30 s of inactivity ──────
  void _resetIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(seconds: 30), () {
      if (mounted) setState(() => _isExpanded = false);
    });
  }

  void _open() {
    setState(() => _isExpanded = true);
    _resetIdleTimer();
    _scrollToBottom();
  }

  // ── Send message ──────────────────────────────────────────
  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _isLoading) return;
    _inputCtrl.clear();
    _resetIdleTimer();
    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
    });
    _scrollToBottom();

    final reply = await GeminiService.chatGeneral(
      text,
      List<Map<String, String>>.from(
        _messages.sublist(0, _messages.length - 1),
      ),
    );

    if (mounted) {
      setState(() {
        _messages.add({'role': 'model', 'text': reply});
        _isLoading = false;
      });
      _scrollToBottom();
      _resetIdleTimer();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return _isExpanded ? _buildPanel() : _buildFab();
  }

  // Collapsed FAB ───────────────────────────────────────────
  Widget _buildFab() {
    return GestureDetector(
      onTap: _open,
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, __) => Container(
          width: 58, height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            boxShadow: [BoxShadow(
              color: const Color(0xFF8B5CF6).withValues(
                  alpha: 0.3 + 0.35 * _pulseCtrl.value),
              blurRadius: 16 + 14 * _pulseCtrl.value,
              spreadRadius: 2,
            )],
          ),
          child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 28),
        ),
      ),
    ).animate().fadeIn(delay: 1000.ms).scale(begin: const Offset(0.5, 0.5));
  }

  // Expanded panel ──────────────────────────────────────────
  Widget _buildPanel() {
    return Container(
      width: 320, height: 460,
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.5), width: 1.5),
        boxShadow: [BoxShadow(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
          blurRadius: 40, spreadRadius: -5,
        )],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildMessages()),
            _buildInput(),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.15);
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
        border: Border(
          bottom: BorderSide(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                boxShadow: [BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(
                      alpha: 0.3 + 0.2 * _pulseCtrl.value),
                  blurRadius: 8 + 4 * _pulseCtrl.value,
                )],
              ),
              child: const Icon(Icons.psychology_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Agentic Auditor',
                    style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                Text('AI Fairness Assistant',
                    style: GoogleFonts.spaceGrotesk(
                        color: Colors.white38, fontSize: 10)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              _idleTimer?.cancel();
              setState(() => _isExpanded = false);
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: Colors.white54, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (_, i) {
        // Typing indicator
        if (i == _messages.length) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (j) {
                    final phase = ((_pulseCtrl.value + j / 3.0) % 1.0);
                    final opacity = phase < 0.5 ? phase * 2 : (1 - phase) * 2;
                    return Container(
                      width: 6, height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF8B5CF6)
                            .withValues(alpha: 0.3 + 0.7 * opacity),
                      ),
                    );
                  }),
                ),
              ),
            ),
          );
        }

        final msg = _messages[i];
        final isUser = msg['role'] == 'user';
        return Align(
          alignment:
              isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            constraints: const BoxConstraints(maxWidth: 244),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              gradient: isUser
                  ? const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)])
                  : null,
              color: isUser
                  ? null
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(14),
                topRight: const Radius.circular(14),
                bottomLeft: Radius.circular(isUser ? 14 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 14),
              ),
            ),
            child: Text(
              msg['text'] ?? '',
              style: GoogleFonts.spaceGrotesk(
                color: isUser ? Colors.white : Colors.white70,
                fontSize: 12, height: 1.5,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: TextField(
                controller: _inputCtrl,
                onTap: _resetIdleTimer,
                onSubmitted: (_) => _send(),
                style: GoogleFonts.spaceGrotesk(
                    color: Colors.white, fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Ask about AI fairness...',
                  hintStyle: GoogleFonts.spaceGrotesk(
                      color: Colors.white24, fontSize: 12),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _send,
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(
                    color: const Color(0xFF6366F1).withValues(
                        alpha: 0.3 + 0.2 * _pulseCtrl.value),
                    blurRadius: 10,
                  )],
                ),
                child: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  FEATURE CARD — filled with content
// ══════════════════════════════════════════════════════════════
class _FeatureCard extends StatefulWidget {
  final int index;
  final Color color;
  final IconData iconData;
  final String emoji;
  final String title;
  final String desc;
  final List<String> tags;
  final String metric;

  const _FeatureCard({
    required this.index, required this.color, required this.iconData,
    required this.emoji, required this.title, required this.desc,
    required this.tags, required this.metric,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          // ignore: deprecated_member_use
          ..translate(0.0, _hover ? -8.0 : 0.0, _hover ? 10.0 : 0.0),
        decoration: BoxDecoration(
          color: _hover
              ? widget.color.withValues(alpha: 0.08)
              : const Color(0xFF0A0A18),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _hover
                ? widget.color.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.07),
            width: _hover ? 1.5 : 1,
          ),
          boxShadow: _hover ? [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.2),
              blurRadius: 32, spreadRadius: 2, offset: const Offset(0, 10)),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 20, offset: const Offset(0, 8)),
          ] : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top row: big icon + LIVE badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: widget.color.withValues(alpha: 0.3)),
                    ),
                    child: Icon(widget.iconData, color: widget.color, size: 26),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: widget.color.withValues(alpha: 0.25)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        width: 5, height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.color,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text('LIVE', style: TextStyle(
                        color: widget.color, fontSize: 9,
                        fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                    ]),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Title
              Text(widget.title, style: GoogleFonts.spaceGrotesk(
                color: Colors.white, fontSize: 15,
                fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),

              // Description — 2 lines max
              Text(widget.desc,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 11.5, height: 1.55)),
              const SizedBox(height: 14),

              // Tags row
              Wrap(spacing: 5, runSpacing: 5,
                children: widget.tags.take(3).map((t) =>
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: widget.color.withValues(alpha: 0.2)),
                    ),
                    child: Text(t, style: TextStyle(
                      color: widget.color.withValues(alpha: 0.9),
                      fontSize: 10, fontWeight: FontWeight.w600)),
                  )
                ).toList()),
              const SizedBox(height: 14),

              // Bottom metric bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: widget.color.withValues(alpha: 0.12)),
                ),
                child: Row(children: [
                  Container(
                    width: 7, height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.color,
                      boxShadow: [BoxShadow(
                        color: widget.color.withValues(alpha: 0.5),
                        blurRadius: 6)],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(child: Text(widget.metric,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white54, fontSize: 11))),
                ]),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(delay: Duration(milliseconds: 80 * widget.index))
           .slideY(begin: 0.06, delay: Duration(milliseconds: 80 * widget.index)),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  STEP CARD
// ══════════════════════════════════════════════════════════════
class _StepCard extends StatefulWidget {
  final Color color;
  final IconData icon;
  final String number, title, desc, metric;
  final int index;
  const _StepCard({
    required this.color, required this.icon, required this.number,
    required this.title, required this.desc, required this.metric,
    required this.index,
  });
  @override
  State<_StepCard> createState() => _StepCardState();
}

class _StepCardState extends State<_StepCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.all(20),
        transform: Matrix4.identity()
          // ignore: deprecated_member_use
          ..translate(0.0, _hover ? -5.0 : 0.0),
        decoration: BoxDecoration(
          color: _hover
              ? widget.color.withValues(alpha: 0.07)
              : const Color(0xFF0A0A18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hover
                ? widget.color.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.06)),
          boxShadow: _hover ? [BoxShadow(
            color: widget.color.withValues(alpha: 0.15),
            blurRadius: 24, spreadRadius: 1, offset: const Offset(0, 8),
          )] : [],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(widget.icon, color: widget.color, size: 20),
            ),
            const Spacer(),
            Text(widget.number, style: TextStyle(
              color: widget.color.withValues(alpha: 0.3),
              fontSize: 28, fontWeight: FontWeight.w900,
              fontFamily: GoogleFonts.spaceGrotesk().fontFamily)),
          ]),
          const SizedBox(height: 14),
          Text(widget.title, style: GoogleFonts.spaceGrotesk(
            color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(widget.desc, style: GoogleFonts.spaceGrotesk(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 11, height: 1.6)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(widget.metric, style: TextStyle(
              color: widget.color, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ]),
      ).animate().fadeIn(
        delay: Duration(milliseconds: 100 * widget.index))
       .slideY(begin: 0.05, delay: Duration(milliseconds: 100 * widget.index)),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  SAMPLE CARD
// ══════════════════════════════════════════════════════════════
class _SampleCard extends StatefulWidget {
  final String emoji, title, desc, score;
  final Color color;
  const _SampleCard({
    required this.emoji, required this.title, required this.desc,
    required this.color, required this.score,
  });
  @override
  State<_SampleCard> createState() => _SampleCardState();
}

class _SampleCardState extends State<_SampleCard> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()
          // ignore: deprecated_member_use
          ..translate(0.0, _hover ? -6.0 : 0.0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _hover
              ? widget.color.withValues(alpha: 0.09)
              : widget.color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _hover
                ? widget.color.withValues(alpha: 0.35)
                : widget.color.withValues(alpha: 0.15)),
          boxShadow: _hover ? [BoxShadow(
            color: widget.color.withValues(alpha: 0.18),
            blurRadius: 20, offset: const Offset(0, 6),
          )] : [],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(widget.emoji, style: const TextStyle(fontSize: 22)),
            Text(widget.score, style: TextStyle(
              color: widget.color, fontSize: 15,
              fontWeight: FontWeight.w900,
              fontFamily: GoogleFonts.spaceGrotesk().fontFamily)),
          ]),
          const SizedBox(height: 10),
          Text(widget.title, style: GoogleFonts.spaceGrotesk(
            color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          Text(widget.desc, style: GoogleFonts.spaceGrotesk(
            color: Colors.white38, fontSize: 11, height: 1.4)),
          const Spacer(),
          Row(children: [
            Icon(Icons.play_arrow_rounded, color: widget.color, size: 14),
            const SizedBox(width: 4),
            Text('Try this sample', style: TextStyle(
              color: widget.color, fontSize: 11, fontWeight: FontWeight.w600)),
          ]),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  3D TILT CARD
// ══════════════════════════════════════════════════════════════
class _Tilt3DCard extends StatefulWidget {
  final Widget child;
  const _Tilt3DCard({required this.child});
  @override
  State<_Tilt3DCard> createState() => _Tilt3DCardState();
}

class _Tilt3DCardState extends State<_Tilt3DCard> {
  double _x = 0, _y = 0;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (e) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        final size = box.size;
        final pos = box.globalToLocal(e.position);
        setState(() {
          _x = (pos.dy - size.height / 2) / (size.height / 2);
          _y = (pos.dx - size.width / 2) / (size.width / 2);
        });
      },
      onExit: (_) => setState(() { _x = 0; _y = 0; }),
      child: Transform(
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(-_x * 0.05)
          ..rotateY(_y * 0.05),
        alignment: FractionalOffset.center,
        child: widget.child,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  GRID PAINTER
// ══════════════════════════════════════════════════════════════
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..strokeWidth = 0.5;
    const spacing = 48.0;
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

// ══════════════════════════════════════════════════════════════
//  DASHED RING PAINTER — Black Hole portal rings
//  Draws a dashed ellipse at the full size of the widget.
//  dashLength / gapLength mirror SVG stroke-dasharray.
// ══════════════════════════════════════════════════════════════
class _DashedRingPainter extends CustomPainter {
  final double dashLength;
  final double gapLength;
  final Color color;
  final double strokeWidth;

  const _DashedRingPainter({
    required this.dashLength,
    required this.gapLength,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rx = size.width / 2;
    final ry = size.height / 2;
    final center = Offset(rx, ry);
    final circumference = 2 * math.pi * ((3 * (rx + ry) - math.sqrt((3 * rx + ry) * (rx + 3 * ry))) / 10 + math.sqrt(rx * ry));
    final totalPattern = dashLength + gapLength;
    final steps = (circumference / totalPattern).floor();

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < steps; i++) {
      final startAngle = (i * totalPattern / circumference) * 2 * math.pi;
      final sweepAngle = (dashLength / circumference) * 2 * math.pi;
      canvas.drawArc(
        Rect.fromCenter(center: center, width: size.width, height: size.height),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedRingPainter old) =>
      old.dashLength != dashLength ||
      old.gapLength != gapLength ||
      old.color != color ||
      old.strokeWidth != strokeWidth;
}

// ══════════════════════════════════════════════════════════════
//  MULTI-CONCENTRIC GRID PAINTER
// ══════════════════════════════════════════════════════════════
class _MultiConcentricGridPainter extends CustomPainter {
  final Color color;

  _MultiConcentricGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final maxRadius = size.width / 2;
    const spacing = 30.0; // Distance between rings
    
    for (double r = spacing; r <= maxRadius; r += spacing) {
      final circumference = 2 * math.pi * r;
      // Dash length and gap vary slightly based on radius to look dynamic
      final dashLength = 3.0 + (r * 0.015); 
      final gapLength = 6.0 + (r * 0.03);
      final steps = (circumference / (dashLength + gapLength)).floor();
      if (steps <= 0) continue;
      final actualPatternLength = circumference / steps;

      for (int i = 0; i < steps; i++) {
        final startAngle = (i * actualPatternLength / circumference) * 2 * math.pi;
        final sweepAngle = (dashLength / circumference) * 2 * math.pi;
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: r),
          startAngle,
          sweepAngle,
          false,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MultiConcentricGridPainter old) => color != old.color;
}

