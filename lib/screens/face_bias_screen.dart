import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'dart:math';
import 'dart:typed_data';

class FaceBiasScreen extends StatefulWidget {
  const FaceBiasScreen({super.key});
  @override
  State<FaceBiasScreen> createState() => _FaceBiasScreenState();
}

class _FaceBiasScreenState extends State<FaceBiasScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool _showResults = false;
  bool _showAlert = false;
  Uint8List? _imageBytes;
  String? _imageName;
  
  // Advanced Simulation Data
  int _biasScore = 0;
  String _severity = 'Safe';
  bool _showHeatmap = false;
  bool _isStressTesting = false;
  double _robustnessScore = 94.0;
  
  final List<String> _biometricFlags = [
    'Emotion Recognition (EU AI Act Restricted)',
    'Biometric Categorization (High Risk)',
    'Demographic Skew: Darker Skin Tones',
  ];

  void _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _imageBytes = result.files.first.bytes;
        _imageName = result.files.first.name;
        _showResults = false;
        _showAlert = false;
        _showHeatmap = false;
      });
    }
  }

  void _analyzeImage() async {
    if (_imageBytes == null) return;
    
    setState(() {
      _isLoading = true;
      _showResults = false;
      _showAlert = false;
    });

    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _biasScore = 68 + Random().nextInt(20);
      _severity = _biasScore >= 80 ? 'Critical' : 'High';
      _showResults = true;
      _showHeatmap = true;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _biasScore >= 60) {
        setState(() => _showAlert = true);
      }
    });
  }

  void _runStressTest() async {
    setState(() => _isStressTesting = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isStressTesting = false;
      _robustnessScore = 42.0; // Simulated drop
      _biasScore += 12;
      _severity = 'Critical';
    });
  }

  Color _getSeverityColor() {
    if (_biasScore >= 80) return const Color(0xFFEF4444);
    if (_biasScore >= 60) return const Color(0xFFF59E0B);
    if (_biasScore >= 30) return const Color(0xFF3B82F6);
    return const Color(0xFF10B981);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04040C),
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF04040C), Color(0xFF0D0D1A)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          
          CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 40),
                      if (!_showResults) _buildUploadSection(),
                      if (_showResults) _buildAdvancedDashboard(),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (_showAlert)
            Positioned(
              top: 80, left: 24, right: 24,
              child: _buildAlertBanner().animate().slideY(begin: -2.0, curve: Curves.easeOutBack),
            ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (_showResults)
          TextButton.icon(
            onPressed: _runStressTest,
            icon: Icon(_isStressTesting ? Icons.hourglass_empty : Icons.bolt, color: Colors.yellowAccent, size: 18),
            label: Text(_isStressTesting ? 'STRESS TESTING...' : 'RUN STRESS TEST', 
              style: GoogleFonts.spaceGrotesk(color: Colors.yellowAccent, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text('Biometric Bias Auditor', style: GoogleFonts.spaceGrotesk(
          color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900,
        )).animate().fadeIn().slideY(begin: -0.2),
        const SizedBox(height: 12),
        Text('Detect algorithmic exclusion in facial recognition & vision models.',
          style: GoogleFonts.spaceGrotesk(color: Colors.white54, fontSize: 16),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 100.ms),
      ],
    );
  }

  Widget _buildUploadSection() {
    return _Tilt3DCard(
      child: GestureDetector(
        onTap: _isLoading ? null : _pickImage,
        child: Container(
          width: double.infinity,
          height: 350,
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D1A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.1), blurRadius: 40)
            ],
          ),
          child: _imageBytes == null 
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.face_retouching_natural, size: 64, color: Color(0xFF818CF8)),
                  const SizedBox(height: 24),
                  Text('Upload Visual Asset', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('PNG, JPG or WEBP for Fairness Audit', style: TextStyle(color: Colors.white24, fontSize: 12)),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(borderRadius: BorderRadius.circular(24), child: Image.memory(_imageBytes!, fit: BoxFit.cover)),
                  if (_isLoading)
                    Container(
                      color: Colors.black54,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(color: Color(0xFF8B5CF6)),
                            const SizedBox(height: 20),
                            Text('Scanning Biometric Landmarks...', style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
        ),
      ),
    );
  }

  Widget _buildAdvancedDashboard() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _buildHeatmapPreview()),
            const SizedBox(width: 24),
            Expanded(flex: 2, child: _buildQuickStats()),
          ],
        ),
        const SizedBox(height: 24),
        _buildComplianceModule(),
        const SizedBox(height: 24),
        _buildAdversarialReport(),
      ],
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildHeatmapPreview() {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _getSeverityColor().withOpacity(0.5)),
        image: DecorationImage(image: MemoryImage(_imageBytes!), fit: BoxFit.cover),
      ),
      child: Stack(
        children: [
          if (_showHeatmap)
            Opacity(
              opacity: 0.6,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.2),
                    radius: 0.8,
                    colors: [Colors.red.withOpacity(0.8), Colors.orange.withOpacity(0.4), Colors.transparent],
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 20, left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
              child: Text('AI ATTENTION HEATMAP', style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
          _buildLandmarkOverlay(),
        ],
      ),
    );
  }

  Widget _buildLandmarkOverlay() {
    return CustomPaint(
      painter: _LandmarkPainter(Random().nextInt(100)),
      size: Size.infinite,
    );
  }

  Widget _buildQuickStats() {
    return Column(
      children: [
        _statBox('BIAS SCORE', '$_biasScore%', _getSeverityColor()),
        const SizedBox(height: 16),
        _statBox('ROBUSTNESS', '${_robustnessScore.toInt()}%', _robustnessScore > 60 ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: const Color(0xFF0D0D1A), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Inclusion Gaps', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _gapItem('Darker Tones', -18),
              _gapItem('Female Faces', -12),
              _gapItem('Older Age', -4),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statBox(String label, String val, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.3))),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.jetBrainsMono(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(val, style: GoogleFonts.spaceGrotesk(color: color, fontSize: 32, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _gapItem(String label, int val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          Text('$val%', style: TextStyle(color: val < 0 ? const Color(0xFFEF4444) : Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildComplianceModule() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFF0D0D1A), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.gavel_rounded, color: Color(0xFF3B82F6)),
              const SizedBox(width: 12),
              Text('EU AI Act Compliance Analysis', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          ..._biometricFlags.map((flag) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                const Icon(Icons.report_problem_rounded, color: Color(0xFFEF4444), size: 16),
                const SizedBox(width: 12),
                Text(flag, style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildAdversarialReport() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('System Robustness & Adversarial Noise', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('How vulnerable is this model to input manipulation or lighting shifts?', style: TextStyle(color: Colors.white38, fontSize: 13)),
          const SizedBox(height: 20),
          LinearProgressIndicator(value: _robustnessScore / 100, color: _robustnessScore > 50 ? const Color(0xFF10B981) : const Color(0xFFEF4444), backgroundColor: Colors.white10),
        ],
      ),
    );
  }

  Widget _buildAlertBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFF991B1B)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFFEF4444).withOpacity(0.3), blurRadius: 20)],
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('CRITICAL BIOMETRIC SKEW', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const Text('Model reliability drops below 70% for specific demographic subsets.', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          IconButton(onPressed: () => setState(() => _showAlert = false), icon: const Icon(Icons.close, color: Colors.white)),
        ],
      ),
    );
  }
}

class _LandmarkPainter extends CustomPainter {
  final int seed;
  _LandmarkPainter(this.seed);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF06B6D4).withOpacity(0.5)..style = PaintingStyle.fill;
    final r = Random(seed);
    for (int i = 0; i < 40; i++) {
      canvas.drawCircle(Offset(size.width * (0.3 + r.nextDouble() * 0.4), size.height * (0.2 + r.nextDouble() * 0.4)), 2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _Tilt3DCard extends StatefulWidget {
  final Widget child;
  const _Tilt3DCard({required this.child});
  @override
  State<_Tilt3DCard> createState() => _Tilt3DCardState();
}

class _Tilt3DCardState extends State<_Tilt3DCard> {
  double x = 0.0, y = 0.0;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (e) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        final size = box.size;
        final pos = box.globalToLocal(e.position);
        setState(() {
          x = (pos.dy - size.height / 2) / (size.height / 2);
          y = (pos.dx - size.width / 2) / (size.width / 2);
        });
      },
      onExit: (_) => setState(() { x = 0; y = 0; }),
      child: Transform(
        transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateX(-x * 0.05)..rotateY(y * 0.05),
        alignment: FractionalOffset.center,
        child: widget.child,
      ),
    );
  }
}
