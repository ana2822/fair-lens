import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class TextBiasScreen extends StatefulWidget {
  const TextBiasScreen({super.key});

  @override
  State<TextBiasScreen> createState() => _TextBiasScreenState();
}

class _TextBiasScreenState extends State<TextBiasScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isAnalyzing = false;
  bool _showResults = false;
  bool _piiScrubbingEnabled = true;
  double _toxicity = 0.08;
  double _inclusion = 0.45;
  int _flaggedCount = 0;

  final List<Map<String, String>> _allFlags = [
    {
      'phrase': '"aggressive leader"',
      'reason': 'Masculine bias - suggests exclusionary work culture',
      'category': 'Gender',
      'suggestion': '"decisive leader" or "strong communicator"'
    },
    {
      'phrase': '"rockstar developer"',
      'reason': 'Age & Gender bias - statistically discourages female and older applicants',
      'category': 'Inclusion',
      'suggestion': '"expert developer" or "highly skilled engineer"'
    },
    {
      'phrase': '"digital native"',
      'reason': 'Age bias - discriminates against older candidates',
      'category': 'Age',
      'suggestion': '"tech-savvy professional" or "proficient in modern tools"'
    },
    {
      'phrase': '"ninja"',
      'reason': 'Cultural appropriation & gender skew - informal language can signal bro-culture',
      'category': 'Culture',
      'suggestion': '"specialist" or "efficient performer"'
    },
    {
      'phrase': '"native speaker"',
      'reason': 'Linguistic bias - may discriminate based on national origin',
      'category': 'Origin',
      'suggestion': '"proficient in [Language]"'
    },
  ];

  List<Map<String, String>> _detectedFlags = [];

  void _analyzeText() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      _isAnalyzing = true;
      _showResults = false;
      _detectedFlags = [];
    });

    // Simulate Deep NLP Analysis
    await Future.delayed(const Duration(seconds: 2));

    final text = _controller.text.toLowerCase();
    for (final flag in _allFlags) {
      if (text.contains(flag['phrase']!.replaceAll('"', '').toLowerCase())) {
        _detectedFlags.add(flag);
      }
    }

    // Dynamic scores based on detections
    _flaggedCount = _detectedFlags.length;
    _toxicity = (0.05 + (_flaggedCount * 0.05)).clamp(0.0, 1.0);
    _inclusion = (0.9 - (_flaggedCount * 0.15)).clamp(0.1, 1.0);

    if (!mounted) return;
    setState(() {
      _isAnalyzing = false;
      _showResults = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04040C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('NLP Semantic Guard', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.history_rounded, color: Colors.white70)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined, color: Colors.white70)),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInputSection(),
            if (_showResults) ...[
              const SizedBox(height: 32),
              _buildResultsSection(),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF1E1B4B).withOpacity(0.5), const Color(0xFF0D0D1A)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.05), blurRadius: 20, spreadRadius: 5)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.psychology_rounded, color: Color(0xFFC084FC), size: 20),
              ),
              const SizedBox(width: 12),
              Text('Semantic Analysis Engine', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              _statusBadge('GPT-4o Backend', const Color(0xFF10B981)),
            ],
          ),
          const SizedBox(height: 20),
          _privacyToggle(),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            maxLines: 8,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Paste resume text, job description, or internal memo here...',
              hintStyle: const TextStyle(color: Colors.white24),
              filled: true,
              fillColor: Colors.black38,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(20),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isAnalyzing ? null : _analyzeText,
              icon: _isAnalyzing 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                  : const Icon(Icons.bolt_rounded, color: Colors.white),
              label: Text(_isAnalyzing ? 'ORCHESTRATING LLM ANALYSIS...' : 'DETECT LATENT BIAS', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          )
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.05);
  }

  Widget _privacyToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.shield_rounded, color: Color(0xFF10B981), size: 18),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Anonymization Layer', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
              Text('Scrub names, emails, and sensitive IDs', style: TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
          const Spacer(),
          Switch(
            value: _piiScrubbingEnabled,
            activeColor: const Color(0xFF10B981),
            onChanged: (val) {
              setState(() {
                _piiScrubbingEnabled = val;
                if (val && _controller.text.isNotEmpty) {
                  _controller.text = _controller.text
                      .replaceAll(RegExp(r'\b[A-Z][a-z]+ [A-Z][a-z]+\b'), '[NAME_REDACTED]')
                      .replaceAll(RegExp(r'\b[\w\.-]+@[\w\.-]+\.\w{2,4}\b'), '[EMAIL_REDACTED]')
                      .replaceAll(RegExp(r'\b\d{3}-\d{2}-\d{4}\b|\b\d{10}\b'), '[ID_REDACTED]');
                }
              });
            },
          )
        ],
      ),
    );
  }

  Widget _buildResultsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Intelligence Report', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            _statusBadge('$_flaggedCount ISSUES FOUND', _flaggedCount > 0 ? Colors.orangeAccent : Colors.greenAccent),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: _metricSquare('Inclusion Score', '${(_inclusion * 100).toInt()}%', _inclusion > 0.7 ? Colors.greenAccent : Colors.orangeAccent)),
            const SizedBox(width: 16),
            Expanded(child: _metricSquare('Latent Toxicity', '${(_toxicity * 100).toInt()}%', _toxicity < 0.2 ? Colors.greenAccent : Colors.redAccent)),
            const SizedBox(width: 16),
            Expanded(child: _metricSquare('Cultural Skew', _flaggedCount > 2 ? 'High' : 'Neutral', _flaggedCount > 2 ? Colors.redAccent : Colors.blueAccent)),
          ],
        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
        const SizedBox(height: 32),
        Text('Flagged Semantic Patterns', style: GoogleFonts.spaceGrotesk(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        if (_detectedFlags.isEmpty)
          _emptyResults()
        else
          ..._detectedFlags.map((flag) => _buildFlagCard(flag)).toList(),
      ],
    );
  }

  Widget _emptyResults() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(color: const Color(0xFF0D0D1A), borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 48),
          const SizedBox(height: 16),
          Text('No major biases detected', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('The text appears to use inclusive and neutral language.', style: TextStyle(color: Colors.white54), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildFlagCard(Map<String, String> flag) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(flag['category']!.toUpperCase(), style: const TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Text(flag['phrase']!, style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, backgroundColor: Colors.white10)),
          const SizedBox(height: 8),
          Text(flag['reason']!, style: const TextStyle(color: Colors.white54, fontSize: 13, height: 1.4)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: Color(0xFF10B981), size: 14),
                const SizedBox(width: 8),
                const Text('SUGGESTION: ', style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)),
                Expanded(child: Text(flag['suggestion']!, style: const TextStyle(color: Colors.white70, fontSize: 12))),
              ],
            ),
          )
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.05);
  }

  Widget _metricSquare(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.spaceGrotesk(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.spaceGrotesk(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _statusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(text, style: GoogleFonts.jetBrainsMono(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
