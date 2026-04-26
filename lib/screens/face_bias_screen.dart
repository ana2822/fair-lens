import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../widgets/top_nav.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/vision_service.dart';

class FaceBiasScreen extends StatefulWidget {
  const FaceBiasScreen({super.key});
  @override
  State<FaceBiasScreen> createState() => _FaceBiasScreenState();
}

class _FaceBiasScreenState extends State<FaceBiasScreen> {
  // ── State ─────────────────────────────────────────────────────
  int _step = 0; // 0=setup, 1=upload, 2=running, 3=results

  final _groupANameCtrl = TextEditingController(text: 'Lighter Skin Tones');
  final _groupBNameCtrl = TextEditingController(text: 'Darker Skin Tones');

  List<({Uint8List bytes, String name})> _groupAImages = [];
  List<({Uint8List bytes, String name})> _groupBImages = [];

  int _progressDone = 0;
  int _progressTotal = 0;

  FaceAuditResult? _result;
  String? _error;

  // ── Image Picking ─────────────────────────────────────────────
  Future<void> _pickImages(bool isGroupA) async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );
    if (picked == null) return;
    final imgs = picked.files
        .where((f) => f.bytes != null)
        .map((f) => (bytes: f.bytes!, name: f.name))
        .toList();
    setState(() {
      if (isGroupA) {
        _groupAImages = imgs;
      } else {
        _groupBImages = imgs;
      }
    });
  }

  // ── Run Analysis ──────────────────────────────────────────────
  Future<void> _runAnalysis() async {
    setState(() { _step = 2; _progressDone = 0; _progressTotal = _groupAImages.length + _groupBImages.length; _error = null; });

    try {
      final statsA = await VisionService.analyzeGroup(
        _groupAImages, _groupANameCtrl.text,
        (done, total) => setState(() => _progressDone = done),
      );
      final statsB = await VisionService.analyzeGroup(
        _groupBImages, _groupBNameCtrl.text,
        (done, total) => setState(() => _progressDone = _groupAImages.length + done),
      );
      final audit = VisionService.computeAudit(statsA, statsB);
      setState(() { _result = audit; _step = 3; });
    } catch (e) {
      setState(() { _error = e.toString(); _step = 1; });
    }
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04040C),
      appBar: const TopNav(activeItem: 'Tools'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                Text('Biometric Bias Auditor', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold)),
                const Spacer(),
                if (!VisionService.hasApiKey)
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                    ),
                    child: Text('ADD VISION_KEY TO .env', style: GoogleFonts.jetBrainsMono(color: const Color(0xFFF59E0B), fontSize: 9, fontWeight: FontWeight.bold)),
                  )
                else
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                    ),
                    child: Text('VISION API CONNECTED', style: GoogleFonts.jetBrainsMono(color: const Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),

        child: [
          _buildSetupStep(),
          _buildUploadStep(),
          _buildRunningStep(),
          _buildResultsStep(),
        ][_step],
      ),
          ),
        ],
      ),
    );

  }

  // ── Step 0: Setup ─────────────────────────────────────────────
  Widget _buildSetupStep() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _heading('How This Works'),
      const SizedBox(height: 12),
      _infoCard(
        'Real Detection, Real Math',
        'Upload photos for two demographic groups. FairLens sends each image to '
        'Google Cloud Vision API, gets the real face detection confidence score, '
        'then computes Disparate Impact Ratio across groups — the same metric used '
        'in the Gender Shades academic audit by Buolamwini & Gebru (2018).',
        const Color(0xFF6366F1),
        Icons.science_rounded,
      ),
      const SizedBox(height: 16),
      _infoCard(
        'What Google Vision Returns (Real)',
        '• detectionConfidence — how certain it found a face (0–1)\n'
        '• landmarkingConfidence — accuracy of eye/nose/mouth mapping (0–1)\n'
        '• faceDetected — whether any face was found at all\n\n'
        'Bias = disparity in these scores across demographic groups.',
        const Color(0xFF10B981),
        Icons.data_object_rounded,
      ),
      const SizedBox(height: 32),
      Text('Name Your Groups', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      _textField(_groupANameCtrl, 'Group A label (e.g. "Female Faces")', const Color(0xFF6366F1)),
      const SizedBox(height: 12),
      _textField(_groupBNameCtrl, 'Group B label (e.g. "Male Faces")', const Color(0xFF8B5CF6)),
      const SizedBox(height: 32),
      _primaryButton('Next: Upload Images →', () => setState(() => _step = 1)),
    ]).animate().fadeIn();
  }

  // ── Step 1: Upload ────────────────────────────────────────────
  Widget _buildUploadStep() {
    final canRun = _groupAImages.isNotEmpty && _groupBImages.isNotEmpty;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _heading('Upload Image Sets'),
      const SizedBox(height: 8),
      const Text('Upload at least 3–5 images per group for meaningful statistics.',
        style: TextStyle(color: Colors.white38, fontSize: 13)),
      const SizedBox(height: 24),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: _uploadSlot(_groupANameCtrl.text, _groupAImages, const Color(0xFF6366F1), () => _pickImages(true))),
        const SizedBox(width: 16),
        Expanded(child: _uploadSlot(_groupBNameCtrl.text, _groupBImages, const Color(0xFF8B5CF6), () => _pickImages(false))),
      ]),
      if (_error != null) ...[
        const SizedBox(height: 16),
        _errorCard(_error!),
      ],
      const SizedBox(height: 24),
      Row(children: [
        _secondaryButton('← Back', () => setState(() => _step = 0)),
        const SizedBox(width: 12),
        Expanded(child: _primaryButton(
          canRun ? 'Run Bias Audit →' : 'Upload images for both groups',
          canRun ? _runAnalysis : null,
        )),
      ]),
    ]).animate().fadeIn();
  }

  Widget _uploadSlot(String label, List images, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.group_rounded, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))),
          ]),
          const SizedBox(height: 16),
          if (images.isEmpty) ...[
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.2), style: BorderStyle.solid),
              ),
              child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.upload_file_rounded, color: color.withValues(alpha: 0.6), size: 28),
                const SizedBox(height: 8),
                Text('Tap to select images', style: TextStyle(color: color.withValues(alpha: 0.6), fontSize: 12)),
              ])),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Icon(Icons.check_circle_rounded, color: color, size: 18),
                const SizedBox(width: 8),
                Text('${images.length} image${images.length == 1 ? "" : "s"} selected',
                  style: GoogleFonts.spaceGrotesk(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
              ]),
            ),
            const SizedBox(height: 8),
            ...images.take(3).map((img) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• ${img.name}', style: const TextStyle(color: Colors.white38, fontSize: 11), overflow: TextOverflow.ellipsis),
            )),
            if (images.length > 3)
              Text('  +${images.length - 3} more', style: TextStyle(color: color.withValues(alpha: 0.5), fontSize: 11)),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.3))),
            child: Text(images.isEmpty ? 'Choose Images' : 'Change Images', style: GoogleFonts.spaceGrotesk(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ]),
      ),
    );
  }

  // ── Step 2: Running ───────────────────────────────────────────
  Widget _buildRunningStep() {
    final progress = _progressTotal > 0 ? _progressDone / _progressTotal : 0.0;
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const SizedBox(height: 60),
      Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D1A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
        ),
        child: Column(children: [
          const Icon(Icons.remove_red_eye_outlined, color: Color(0xFF818CF8), size: 48),
          const SizedBox(height: 20),
          Text('Calling Google Vision API', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Analyzing image $_progressDone of $_progressTotal', style: const TextStyle(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              color: const Color(0xFF6366F1),
            ),
          ),
          const SizedBox(height: 16),
          Text('${(progress * 100).toInt()}%', style: GoogleFonts.spaceGrotesk(color: const Color(0xFF818CF8), fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Each image is sent to Google Cloud Vision — no data stored.', style: TextStyle(color: Colors.white24, fontSize: 11)),
        ]),
      ),
    ]).animate().fadeIn();
  }

  // ── Step 3: Results ───────────────────────────────────────────
  Widget _buildResultsStep() {
    final r = _result;
    if (r == null) return const SizedBox();

    final verdictColor = r.verdict == 'BIASED'
        ? const Color(0xFFEF4444)
        : r.verdict == 'BORDERLINE'
            ? const Color(0xFFF59E0B)
            : const Color(0xFF10B981);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _heading('Audit Results'),
      const SizedBox(height: 8),
      const Text('Computed from real Google Vision API detectionConfidence scores.',
        style: TextStyle(color: Colors.white38, fontSize: 12)),
      const SizedBox(height: 24),

      // Verdict banner
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: verdictColor.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: verdictColor.withValues(alpha: 0.3)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(r.verdict == 'BIASED' ? Icons.dangerous_rounded : r.verdict == 'BORDERLINE' ? Icons.warning_amber_rounded : Icons.verified_rounded, color: verdictColor, size: 24),
            const SizedBox(width: 12),
            Text(r.verdict, style: GoogleFonts.spaceGrotesk(color: verdictColor, fontSize: 22, fontWeight: FontWeight.w900)),
            const Spacer(),
            _badge(r.verdict, verdictColor),
          ]),
          const SizedBox(height: 12),
          Text(r.verdictDetail, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),
        ]),
      ),
      const SizedBox(height: 24),

      // Core metric
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: const Color(0xFF0D0D1A), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.08))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Disparate Impact Ratio', style: GoogleFonts.spaceGrotesk(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 4),
          Text(r.disparateImpactRatio.toStringAsFixed(3), style: GoogleFonts.spaceGrotesk(color: verdictColor, fontSize: 40, fontWeight: FontWeight.w900)),
          Text('Formula: min(detection_rate) / max(detection_rate)  |  Threshold: ≥0.80', style: GoogleFonts.jetBrainsMono(color: Colors.white24, fontSize: 10)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: r.disparateImpactRatio.clamp(0, 1), minHeight: 6, backgroundColor: Colors.white.withValues(alpha: 0.05), color: verdictColor),
          ),
        ]),
      ),
      const SizedBox(height: 16),

      // Group comparison
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: _groupCard(r.groupA, const Color(0xFF6366F1))),
        const SizedBox(width: 16),
        Expanded(child: _groupCard(r.groupB, const Color(0xFF8B5CF6))),
      ]),
      const SizedBox(height: 24),

      // Methodology note
      _infoCard(
        'Methodology',
        'Detection Rate = faces found / images uploaded.\n'
        'Detection Confidence = Vision API\'s raw confidence score (0–1).\n'
        'Disparate Impact Ratio < 0.8 violates the EEOC four-fifths rule.\n\n'
        'Aligned with: Gender Shades (MIT, 2018), NIST FRVT (2019), EU AI Act Annex III.',
        const Color(0xFF818CF8),
        Icons.info_outline_rounded,
      ),
      const SizedBox(height: 24),

      // Restart
      _primaryButton('Run Another Audit', () => setState(() {
        _step = 0; _result = null; _groupAImages = []; _groupBImages = [];
      })),
    ]).animate().fadeIn();
  }

  Widget _groupCard(GroupBiasStats g, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(g.groupName, style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _statRow('Images', '${g.totalImages}', color),
        _statRow('Faces Found', '${g.detectedFaces}', color),
        _statRow('Detection Rate', '${(g.detectionRate * 100).toStringAsFixed(1)}%', color),
        _statRow('Avg Confidence', '${(g.avgDetectionConfidence * 100).toStringAsFixed(1)}%', color),
        _statRow('Landmark Conf.', '${(g.avgLandmarkConfidence * 100).toStringAsFixed(1)}%', color),
      ]),
    );
  }

  Widget _statRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        Text(value, style: GoogleFonts.jetBrainsMono(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  // ── Shared Widgets ────────────────────────────────────────────
  Widget _heading(String text) => Text(text, style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900));

  Widget _infoCard(String title, String body, Color color, IconData icon) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.2))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Text(title, style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 10),
      Text(body, style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.5)),
    ]),
  );

  Widget _errorCard(String msg) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3))),
    child: Row(children: [
      const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 18),
      const SizedBox(width: 10),
      Expanded(child: Text(msg, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12))),
    ]),
  );

  Widget _textField(TextEditingController ctrl, String hint, Color color) => TextField(
    controller: ctrl,
    style: GoogleFonts.spaceGrotesk(color: Colors.white),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white24),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.03),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: color.withValues(alpha: 0.3))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: color.withValues(alpha: 0.2))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: color)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  );

  Widget _primaryButton(String label, VoidCallback? onTap) => SizedBox(
    width: double.infinity,
    height: 50,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: onTap != null ? const Color(0xFF6366F1) : Colors.white12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: Text(label, style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold)),
    ),
  );

  Widget _secondaryButton(String label, VoidCallback onTap) => OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      side: const BorderSide(color: Colors.white12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    ),
    child: Text(label, style: const TextStyle(color: Colors.white54)),
  );

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withValues(alpha: 0.3))),
    child: Text(label, style: GoogleFonts.jetBrainsMono(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
  );
}
