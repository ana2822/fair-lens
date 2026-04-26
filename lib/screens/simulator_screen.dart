import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class SimulatorScreen extends StatefulWidget {
  const SimulatorScreen({super.key});

  @override
  State<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends State<SimulatorScreen> {
  double _fairnessWeight = 0.5;
  String _scenario = 'Hiring';
  bool _isSimulating = false;
  final List<Map<String, dynamic>> _decisionStream = [];
  final math.Random _random = math.Random();

  // Dynamics based on weights
  double get _accuracy => (96.0 - (_fairnessWeight * 14.0)).clamp(80.0, 96.0);
  double get _biasScore => (82.0 - (_fairnessWeight * 65.0)).clamp(15.0, 85.0);
  double get _economicImpact => 1.2 + (_fairnessWeight * 0.8); // Billion $ estimated

  final Map<String, List<String>> _scenarioGroups = {
    'Hiring': ['Gender', 'Age', 'Ethnicity'],
    'Loans': ['Zip Code', 'Income', 'Marital Status'],
    'Education': ['Region', 'Family Income', 'Disability'],
  };

  void _toggleSimulation() {
    setState(() {
      _isSimulating = !_isSimulating;
      if (_isSimulating) {
        _runSimulation();
      }
    });
  }

  void _runSimulation() async {
    while (_isSimulating && mounted) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;

      final groups = _scenarioGroups[_scenario]!;
      final group = groups[_random.nextInt(groups.length)];
      final isAccepted = _random.nextDouble() > (0.4 + (_fairnessWeight * 0.2));
      final wasBiased = !isAccepted && _random.nextDouble() < (_biasScore / 100);

      setState(() {
        _decisionStream.insert(0, {
          'id': 'ID-${_random.nextInt(9000) + 1000}',
          'group': group,
          'status': isAccepted ? 'ACCEPTED' : 'REJECTED',
          'biased': wasBiased,
          'time': DateTime.now(),
        });
        if (_decisionStream.length > 8) _decisionStream.removeLast();
      });
    }
  }

  @override
  void dispose() {
    _isSimulating = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04040C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Fairness Pareto Simulator', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
        actions: [
          _statusBadge(_isSimulating ? 'SIMULATING' : 'IDLE', _isSimulating ? const Color(0xFF10B981) : Colors.white24),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildScenarioSelector(),
            const SizedBox(height: 24),
            _buildMainControls(),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildVisualizer()),
                const SizedBox(width: 24),
                Expanded(flex: 2, child: _buildDecisionLog()),
              ],
            ),
            const SizedBox(height: 32),
            _buildSafetyGating(),
          ],
        ),
      ),
    );
  }

  Widget _buildScenarioSelector() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: const Color(0xFF0D0D1A), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['Hiring', 'Loans', 'Education'].map((s) {
          final isSelected = _scenario == s;
          return GestureDetector(
            onTap: () => setState(() => _scenario = s),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF8B5CF6) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(s, style: GoogleFonts.spaceGrotesk(
                color: isSelected ? Colors.white : Colors.white54,
                fontWeight: FontWeight.bold,
              )),
            ),
          );
        }).toList(),
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildMainControls() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Optimization Strategy', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const Text('Balance predictive power vs group parity', style: TextStyle(color: Colors.white38, fontSize: 13)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _toggleSimulation,
                icon: Icon(_isSimulating ? Icons.stop_rounded : Icons.play_arrow_rounded),
                label: Text(_isSimulating ? 'STOP SIM' : 'START SIM'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSimulating ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              )
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              _metricRing('ACCURACY', _accuracy, const Color(0xFF10B981)),
              const Spacer(),
              _metricRing('BIAS RISK', _biasScore, const Color(0xFFEF4444)),
              const Spacer(),
              _metricRing('TRUST', 100 - _biasScore + (_fairnessWeight * 10), const Color(0xFF06B6D4)),
            ],
          ),
          const SizedBox(height: 32),
          SliderTheme(
            data: const SliderThemeData(
              activeTrackColor: Color(0xFF8B5CF6),
              inactiveTrackColor: Colors.white12,
              thumbColor: Colors.white,
              trackHeight: 6,
            ),
            child: Slider(
              value: _fairnessWeight,
              onChanged: (v) => setState(() => _fairnessWeight = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('MAX PERFORMANCE', style: GoogleFonts.jetBrainsMono(color: Colors.white24, fontSize: 10)),
                Text('OPTIMAL EQUILIBRIUM', style: GoogleFonts.jetBrainsMono(color: const Color(0xFF8B5CF6), fontSize: 10, fontWeight: FontWeight.bold)),
                Text('MAX FAIRNESS', style: GoogleFonts.jetBrainsMono(color: Colors.white24, fontSize: 10)),
              ],
            ),
          )
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildVisualizer() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFF0D0D1A), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Real-time Drift & Impact', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold)),
          const Spacer(),
          Center(
            child: Text(
              'Est. Economic Impact: \$${_economicImpact.toStringAsFixed(2)}B / year',
              style: GoogleFonts.spaceGrotesk(color: const Color(0xFF818CF8), fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Higher fairness weights often lead to more sustainable economic outcomes by tapping into underutilized talent pools.',
            style: TextStyle(color: Colors.white38, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          _impactBar(),
        ],
      ),
    );
  }

  Widget _impactBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Demographic Parity', style: TextStyle(color: Colors.white54, fontSize: 11)),
            Text('${(100 - _biasScore).toInt()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 4,
          width: double.infinity,
          decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2)),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (100 - _biasScore) / 100,
            child: Container(decoration: BoxDecoration(color: const Color(0xFF8B5CF6), borderRadius: BorderRadius.circular(2))),
          ),
        ),
      ],
    );
  }

  Widget _buildDecisionLog() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF0D0D1A), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Live Decisions', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Expanded(
            child: _decisionStream.isEmpty 
              ? const Center(child: Text('Start simulation to see live data', style: TextStyle(color: Colors.white24, fontSize: 11)))
              : ListView.builder(
                  itemCount: _decisionStream.length,
                  itemBuilder: (context, i) {
                    final d = _decisionStream[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(width: 4, height: 4, decoration: BoxDecoration(color: d['status'] == 'ACCEPTED' ? Colors.green : Colors.red, shape: BoxShape.circle)),
                          const SizedBox(width: 10),
                          Expanded(child: Text('${d['id']} (${d['group']})', style: GoogleFonts.jetBrainsMono(color: Colors.white70, fontSize: 10))),
                          if (d['biased']) const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 10),
                        ],
                      ),
                    ).animate().fadeIn().slideX(begin: 0.1);
                  },
                ),
          )
        ],
      ),
    );
  }

  Widget _buildSafetyGating() {
    final isBlocked = _biasScore > 40;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isBlocked ? const Color(0xFFEF4444).withValues(alpha: 0.05) : const Color(0xFF10B981).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isBlocked ? const Color(0xFFEF4444).withValues(alpha: 0.3) : const Color(0xFF10B981).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(isBlocked ? Icons.lock_rounded : Icons.verified_rounded, color: isBlocked ? const Color(0xFFEF4444) : const Color(0xFF10B981), size: 32),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isBlocked ? 'DEPLOYMENT GATED' : 'SAFE FOR PRODUCTION', style: GoogleFonts.spaceGrotesk(
                  color: isBlocked ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                  fontWeight: FontWeight.bold, fontSize: 18,
                )),
                Text(
                  isBlocked ? 'Bias score exceeds institutional risk threshold of 40%.' : 'Model meets all fairness and compliance requirements.',
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),
          if (!isBlocked)
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
              child: const Text('DEPLOY NOW'),
            ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _metricRing(String label, double value, Color color) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 80, height: 80,
              child: CircularProgressIndicator(
                value: value / 100,
                strokeWidth: 8,
                backgroundColor: Colors.white10,
                color: color,
                strokeCap: StrokeCap.round,
              ),
            ),
            Text('${value.toInt()}%', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Text(label, style: GoogleFonts.jetBrainsMono(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _statusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Text(text, style: GoogleFonts.jetBrainsMono(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
