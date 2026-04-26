import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math' as math;
import '../models/bias_detector.dart';
import '../services/alert_service.dart';
import 'analysis_screen.dart';
import 'simulator_screen.dart';
import 'public_portal_screen.dart';
import 'global_compliance_screen.dart';

class GovDashboardScreen extends StatefulWidget {
  const GovDashboardScreen({super.key});

  @override
  State<GovDashboardScreen> createState() => _GovDashboardScreenState();
}

class _GovDashboardScreenState extends State<GovDashboardScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _liveFeedTimer;
  int _liveScore = 72;
  int _batchCount = 4901;
  int _alertCount = 0;
  final bool _isOnline = true;
  final List<Map<String, dynamic>> _liveLogs = [];
  
  // Agentic Auditor State
  final String _currentGoal = "Minimize Disparate Impact in rural areas";
  final double _goalProgress = 0.65;

  static const _events = [
    {'type': 'batch',    'msg': 'New applicant batch processed.'},
    {'type': 'flag',     'msg': 'Gender feature flagged — correlation with outcome.'},
    {'type': 'location', 'msg': 'Location proxy bias detected in rural subset.'},
    {'type': 'audit',    'msg': 'Compliance check triggered by risk threshold.'},
    {'type': 'retrain',  'msg': 'Model retraining requested by safety system.'},
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this, duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addLog('info', 'System initialized. FairLens monitoring active.');
      AlertService().trigger(
        'FairLens Gov Monitor started. Bias score: $_liveScore/100.',
        AlertType.info,
      );
    });

    _liveFeedTimer = Timer.periodic(const Duration(seconds: 4), _tick);
  }

  void _tick(Timer _) {
    if (!mounted) return;
    final rand = math.Random();
    final oldScore = _liveScore;

    // Simulate score drift (realistic, bounded between 60-85)
    final delta = rand.nextInt(7) - 3; // -3 to +3
    _liveScore = (_liveScore + delta).clamp(60, 85);
    _batchCount++;

    // Pick a random event
    final event = _events[rand.nextInt(_events.length)];
    final type = event['type'] as String;

    setState(() {
      if (type == 'batch') {
        _addLog('score',
          'Batch #$_batchCount → Bias score: $oldScore → $_liveScore');
      } else {
        _addLog(type, '${event["msg"]}');
      }
    });

    // Trigger real alerts based on conditions
    if (_liveScore >= 80 && oldScore < 80) {
      AlertService().trigger(
        '🚨 Bias score crossed CRITICAL threshold: $_liveScore/100 — Scholarship AI.',
        AlertType.critical,
      );
      _alertCount++;
    } else if (type == 'flag') {
      AlertService().trigger(
        'Gender feature flagged in live batch #$_batchCount — score: $_liveScore/100.',
        AlertType.warning,
      );
    } else if (type == 'location' && _liveScore > 72) {
      AlertService().trigger(
        'Location proxy bias detected — rural applicants show lower selection rate.',
        AlertType.warning,
      );
    }
  }

  void _addLog(String type, String msg) {
    _liveLogs.insert(0, {'type': type, 'msg': msg, 'time': DateTime.now()});
    if (_liveLogs.length > 5) _liveLogs.removeLast();
  }

  Color _logColor(String type) {
    switch (type) {
      case 'score':    return const Color(0xFF818CF8);
      case 'flag':     return const Color(0xFFF59E0B);
      case 'location': return const Color(0xFFF59E0B);
      case 'audit':    return const Color(0xFF34D399);
      case 'retrain':  return const Color(0xFF60A5FA);
      default:         return Colors.white54;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _liveFeedTimer?.cancel();
    super.dispose();
  }

  void _runEducationAudit() {
    final data = [
      {'ID': '1', 'Gender': 'Male', 'Location': 'Urban', 'Score': '95', 'Admitted': 'Yes'},
      {'ID': '2', 'Gender': 'Female', 'Location': 'Urban', 'Score': '92', 'Admitted': 'Yes'},
      {'ID': '3', 'Gender': 'Male', 'Location': 'Rural', 'Score': '88', 'Admitted': 'No'},
      {'ID': '4', 'Gender': 'Female', 'Location': 'Rural', 'Score': '94', 'Admitted': 'No'},
      {'ID': '5', 'Gender': 'Male', 'Location': 'Urban', 'Score': '85', 'Admitted': 'Yes'},
      {'ID': '6', 'Gender': 'Female', 'Location': 'Rural', 'Score': '91', 'Admitted': 'No'},
      {'ID': '7', 'Gender': 'Male', 'Location': 'Urban', 'Score': '82', 'Admitted': 'Yes'},
      {'ID': '8', 'Gender': 'Female', 'Location': 'Urban', 'Score': '89', 'Admitted': 'Yes'},
    ];
    
    final headers = ['ID', 'Gender', 'Location', 'Score', 'Admitted'];
    final analysisResult = BiasDetector.analyze(data, headers);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnalysisScreen(
          result: analysisResult,
          rawData: data.map((e) => e.map((k, v) => MapEntry(k, v.toString()))).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04040C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        elevation: 1,
        title: Row(
          children: [
            const Icon(Icons.account_balance_rounded, color: Color(0xFF818CF8)),
            const SizedBox(width: 10),
            Text('Government Command Center', style: GoogleFonts.spaceGrotesk(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18,
            )),
          ],
        ),
        actions: [
          _roleBadge('👨‍💼 Admin', () {
            AlertService().trigger('Switched to Admin View. Full system access granted.', AlertType.info);
          }),
          const SizedBox(width: 8),
          _roleBadge('🕵️ Auditor', () {
            AlertService().trigger('Switched to Auditor Mode. High-resolution logs enabled.', AlertType.info);
          }),
          const SizedBox(width: 8),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, __) => Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.5 + 0.5 * _pulseController.value),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.5 * _pulseController.value),
                          blurRadius: 6,
                        )
                      ]
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('LIVE', style: GoogleFonts.spaceGrotesk(
                  color: const Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1
                )),
              ],
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // 🚨 GLOBAL AI ALERT SYSTEM (Sticky Top Banner)
          _buildStickyAlert(),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🏛️ MAIN DASHBOARD & LIVE FEED
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _buildMainDashboard()),
                      const SizedBox(width: 24),
                      Expanded(flex: 1, child: _buildLiveFeed()),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 🤖 AGENTIC AUDITOR: GOAL TRACKER
                  _buildGoalTracker(),
                  const SizedBox(height: 24),
      
                  // 📊 EDUCATION-SPECIFIC MODULE
                  _buildEducationModule(),
                  const SizedBox(height: 24),
                  
                  // 📈 DRIFT FORECASTER
                  _buildDriftForecaster(),
                  const SizedBox(height: 24),
                  
                  // ⚖️ ADVANCED PANELS ROW 1
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildDecisionExplainer()),
                      const SizedBox(width: 24),
                      Expanded(child: _buildFairnessTradeoff()),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // 📜 COMPLIANCE & TRANSPARENCY ROW 2
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildLegalCompliancePanel()),
                      const SizedBox(width: 24),
                      Expanded(child: _buildTransparencyPortal()),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 🌍 GLOBAL ROADMAP BANNER
                  _buildRoadmapBanner(),
                  const SizedBox(height: 24),

                  // 📡 API INTEGRATION
                  _buildApiPanel(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleBadge(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ),
    );
  }

  Widget _buildStickyAlert() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFEF4444),
        boxShadow: [
          BoxShadow(color: Color(0xFFEF4444), blurRadius: 10, offset: Offset(0, 2))
        ]
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, __) => Icon(
              Icons.warning_amber_rounded,
              color: Colors.white.withValues(alpha: 0.6 + 0.4 * _pulseController.value),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'CRITICAL: Scholarship allocation shows gender bias (78%) in rural district datasets.',
            style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFEF4444),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
            ),
            child: const Text('View Logs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          )
        ],
      ),
    );
  }

  Widget _buildMainDashboard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('🏛️ Scholarship Allocation AI', style: GoogleFonts.spaceGrotesk(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold,
                ), overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 12),
              _statusBadge(),
              const Spacer(),
              // ✨ ONE-CLICK "MAKE SYSTEM FAIR"
              ElevatedButton.icon(
                onPressed: () {
                  AlertService().trigger('Simulating automated bias mitigation...', AlertType.info);
                },
                icon: const Icon(Icons.auto_fix_high_rounded, size: 16, color: Colors.white),
                label: const Text('✨ Fix System', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              ),
              const SizedBox(width: 12),
              // 🚀 SIMULATOR BUTTON
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SimulatorScreen()),
                  );
                },
                icon: const Icon(Icons.rocket_launch_rounded, size: 16, color: Colors.white),
                label: const Text('Simulator', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              )
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              // 🧠 AI RISK SCORE
              _statCard('AI Risk Score', '82/100', '⚠️ High Risk', const Color(0xFFEF4444)),
              const SizedBox(width: 16),
              _statCard('Fairness Score', '$_liveScore/100', 'Grade: C', const Color(0xFFF59E0B)),
              const SizedBox(width: 16),
              _statCard('Alerts Triggered', '$_alertCount', 'Last 24h', const Color(0xFF6366F1)),
              const SizedBox(width: 16),
              _statCard('Processed Batches', '#$_batchCount', 'Active Monitoring', const Color(0xFF10B981)),
            ],
          )
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1);
  }

  Widget _statusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (_isOnline ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: (_isOnline ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isOnline ? Icons.wifi : Icons.wifi_off,
            size: 10,
            color: _isOnline ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
          ),
          const SizedBox(width: 4),
          Text(
            _isOnline ? 'ONLINE' : 'OFFLINE MODE',
            style: GoogleFonts.jetBrainsMono(
              color: _isOnline ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, String sub, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.spaceGrotesk(color: Colors.white60, fontSize: 12)),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.spaceGrotesk(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(sub, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveFeed() {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.05),
            blurRadius: 15,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.stream_rounded, color: Color(0xFF10B981), size: 18),
              const SizedBox(width: 8),
              Text('Live Monitoring', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold)),
              const Spacer(),
              AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) => Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.4 + 0.6 * _pulseController.value),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _liveLogs.length,
              itemBuilder: (context, index) {
                final log = _liveLogs[index];
                final color = _logColor(log['type']);
                final time = log['time'] as DateTime;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}',
                        style: GoogleFonts.jetBrainsMono(color: Colors.white24, fontSize: 10),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          log['msg'],
                          style: GoogleFonts.jetBrainsMono(
                            color: index == 0 ? color : color.withValues(alpha: 0.6),
                            fontSize: 11,
                            fontWeight: index == 0 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideX(begin: 0.05);
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildGoalTracker() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF818CF8).withValues(alpha: 0.3)),
        gradient: LinearGradient(
          colors: [const Color(0xFF6366F1).withValues(alpha: 0.05), const Color(0xFF0D0D1A)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.track_changes_rounded, color: Color(0xFF818CF8)),
              const SizedBox(width: 12),
              Text('Agentic Auditor: Dynamic Goal Alignment', style: GoogleFonts.spaceGrotesk(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold,
              )),
              const Spacer(),
              _glowButton('Update Goal', Icons.edit_note_rounded, () {
                AlertService().trigger('Goal alignment engine ready. Enter new policy objective.', AlertType.info);
              }),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current Policy Objective', style: GoogleFonts.spaceGrotesk(color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(_currentGoal, style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    Text('${(_goalProgress * 100).toInt()}%', style: GoogleFonts.spaceGrotesk(color: const Color(0xFF10B981), fontSize: 20, fontWeight: FontWeight.bold)),
                    const Text('Aligned', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _goalProgress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              color: const Color(0xFF6366F1),
            ),
          ),
          const SizedBox(height: 16),
          _glassContainer(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF6366F1).withValues(alpha: 0.05),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFF818CF8), size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Gemini Insight: Your model is currently prioritizing speed over rural equity. To reach 90% alignment, adjust the Fairness-Accuracy slider by +12%.',
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1);
  }

  Widget _glowButton(String label, IconData icon, VoidCallback onTap) =>
    InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: const Color(0xFF818CF8)),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.spaceGrotesk(color: const Color(0xFF818CF8), fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );

  Widget _glassContainer({required Widget child, required EdgeInsets padding, Color? color, Color? borderColor}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor ?? Colors.white.withValues(alpha: 0.08)),
      ),
      child: child,
    );
  }

  Widget _buildEducationModule() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF0D0D1A)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.school_rounded, color: Color(0xFF818CF8)),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Education-Specific Mode', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const Text('Analyze student data for admission, grading, and scholarship bias', style: TextStyle(color: Colors.white60, fontSize: 13)),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _runEducationAudit,
                icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                label: const Text('Run Education Audit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              )
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _eduPill('Input: Student Data (Marks, Category, Gender)'),
              const SizedBox(width: 10),
              _eduPill('Detect: Admission & Grading Bias'),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: const Text('⚠️ Rural students selected 32% less', style: TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.bold)),
              )
            ],
          )
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _eduPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.2)),
      ),
      child: Text(text, style: const TextStyle(color: Color(0xFF818CF8), fontSize: 12)),
    );
  }

  Widget _buildDecisionExplainer() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.help_outline_rounded, color: Color(0xFF06B6D4)),
              const SizedBox(width: 10),
              Text('Decision Explainer', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Student #4920: Rejected', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Why was this student rejected?', style: TextStyle(color: Colors.white54, fontSize: 12)),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 14),
                    SizedBox(width: 6),
                    Text('Score below threshold', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.warning_rounded, color: Color(0xFFEF4444), size: 14),
                    SizedBox(width: 6),
                    Text('Bias detected in location factor', style: TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1);
  }

  Widget _buildFairnessTradeoff() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.balance_rounded, color: Color(0xFF8B5CF6)),
              const SizedBox(width: 10),
              Text('Fairness vs Accuracy Trade-off', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: Column(
                  children: [
                    Icon(Icons.arrow_downward_rounded, color: Color(0xFF10B981)),
                    SizedBox(height: 4),
                    Text('Bias ↓ 40%', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white12),
              const Expanded(
                child: Column(
                  children: [
                    Icon(Icons.arrow_downward_rounded, color: Color(0xFFF59E0B)),
                    SizedBox(height: 4),
                    Text('Accuracy ↓ 6%', style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 12),
          const Text('Rebalancing the dataset significantly reduces bias with a minimal acceptable drop in overall model accuracy.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1);
  }

  Widget _buildLegalCompliancePanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.gavel_rounded, color: Color(0xFFF59E0B)),
              const SizedBox(width: 10),
              Text('Legal & Policy Recommendations', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          _complianceItem('Indian Constitution (Art 14, 15, 16)', false),
          _complianceItem('Right to Education (RTE) Act', false),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🧠 Gemini Policy Recommendation:', style: TextStyle(color: Color(0xFF818CF8), fontWeight: FontWeight.bold, fontSize: 12)),
                SizedBox(height: 4),
                Text('• Remove gender from decision pipeline\n• Introduce blind evaluation', style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5)),
              ],
            ),
          )
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }

  Widget _complianceItem(String text, bool pass) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(pass ? Icons.check_circle_rounded : Icons.cancel_rounded, color: pass ? const Color(0xFF10B981) : const Color(0xFFEF4444), size: 16),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildTransparencyPortal() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.visibility_rounded, color: Color(0xFF06B6D4)),
              const SizedBox(width: 10),
              Text('Public Transparency Portal', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Citizens can verify fairness metrics publicly. Raw data is never shown (privacy safe).', style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.5)),
          const SizedBox(height: 16),
          Row(
            children: [
              _actionBtn('View Public Portal', Icons.open_in_new_rounded, const Color(0xFF06B6D4).withValues(alpha: 0.2), () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PublicPortalScreen()),
                );
              }),
              const SizedBox(width: 12),
              _actionBtn('Export Gov Audit', Icons.picture_as_pdf_rounded, Colors.white12, () {
                AlertService().trigger('Generating Government Compliance Audit PDF...', AlertType.info);
              }),
            ],
          )
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildRoadmapBanner() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF312E81), Color(0xFF1E1B4B)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.public_rounded, color: Color(0xFF818CF8), size: 40),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Global Regulatory Roadmap', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const Text('View real-time deployment readiness across 50+ jurisdictions based on current bias scores.', style: TextStyle(color: Colors.white60, fontSize: 14)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GlobalComplianceScreen())),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white),
            child: const Text('Open Roadmap'),
          ),
        ],
      ),
    );
  }

  Widget _buildDriftForecaster() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up_rounded, color: Color(0xFF8B5CF6)),
              const SizedBox(width: 10),
              Text('Temporal Bias Drift Forecaster (LSTM)', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Predictive projection showing how the current dataset will likely drift into bias over the next 12 months based on historical application trends.', style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.5)),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _driftBar(50, 'Jan', false),
              _driftBar(55, 'Mar', false),
              _driftBar(68, 'Jun', false),
              _driftBar(72, 'Sep', true), // Current
              _driftBar(85, 'Dec', true, isProjection: true),
              _driftBar(95, 'Mar 27', true, isProjection: true),
              const SizedBox(width: 24),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.5))),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('⚠️ Drift Warning', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('Model projected to breach 80% bias threshold by December due to compounding location feature skew.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              )
            ],
          )
        ],
      ),
    ).animate().fadeIn(delay: 220.ms).slideY(begin: 0.1);
  }

  Widget _driftBar(double height, String label, bool isHigh, {bool isProjection = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 32,
            height: height,
            decoration: BoxDecoration(
              color: isProjection 
                ? Colors.transparent 
                : (isHigh ? const Color(0xFFEF4444) : const Color(0xFF6366F1)),
              border: isProjection ? Border.all(color: const Color(0xFFEF4444), width: 2, style: BorderStyle.solid) : null,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildApiPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF04040C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.api_rounded, color: Colors.white54),
              const SizedBox(width: 10),
              Text('API Integration Panel', style: GoogleFonts.spaceGrotesk(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
            child: const Text(
              'POST /api/v1/fairness/analyze\n{\n  "model": "ScholarshipAI",\n  "data_uri": "s3://edu-bucket/batch_49.csv"\n}\n\n-> 200 OK\n{\n  "bias_score": 75,\n  "flagged_columns": ["location"]\n}',
              style: TextStyle(color: Color(0xFF10B981), fontFamily: 'Courier', fontSize: 12, height: 1.5),
            ),
          )
        ],
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1);
  }

  Widget _actionBtn(String label, IconData icon, Color bg, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
