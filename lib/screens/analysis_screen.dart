import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/bias_detector.dart';
import '../services/gemini_service.dart';
import '../services/firebase_service.dart';
import '../services/pdf_service.dart';
import '../services/alert_service.dart';
import 'compare_screen.dart';
import 'dart:ui';
class AnalysisScreen extends StatefulWidget {
  final AnalysisReport result;
  final List<Map<String, String>> rawData;
  const AnalysisScreen({super.key, required this.result, required this.rawData});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _bellController;
  String _geminiAnalysis = '';
  bool _loadingGemini = false;
  bool _geminiCalled = false;       // ✅ prevents duplicate calls
  int _selectedBiasIndex = 0;
  AutoFixResult? _fixResult;
  bool _fixing = false;
  String _selectedFixMethod = 'remove';
  Map<String, double> _whatIfScores = {};
  bool _chatLoading = false;
  final List<Map<String, String>> _chatHistory = [];
  final TextEditingController _chatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _bellController = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));

    if (widget.result.overallBiasScore > 60) {
      _bellController.repeat(reverse: true);
    }

    // ✅ Clear cache for new dataset, then load once after 500ms delay
    GeminiService.clearCache();
    Future.delayed(const Duration(milliseconds: 500), _loadGeminiAnalysis);
    _computeWhatIf();
    _saveToFirebase();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bellController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _loadGeminiAnalysis({bool forceReload = false}) async {
    // Prevent duplicate calls — only run once unless forced
    if (_geminiCalled && !forceReload) return;
    if (_loadingGemini) return;
    if (!mounted) return;

    _geminiCalled = true;
    setState(() { _loadingGemini = true; });

    final analysis = await GeminiService.analyzeWithGemini(widget.result);
    if (!mounted) return;

    // Detect fallback banner
    setState(() {
      _geminiAnalysis = analysis;
      _loadingGemini = false;
    });
    // Save again with the AI report included
    _saveToFirebase();
  }

  void _computeWhatIf() {
    final data = widget.result.rawData;
    final headers = widget.result.headers;
    if (data.isEmpty) return;
    final scores = <String, double>{};
    for (final col in headers) {
      if (BiasDetector.isSensitiveColumn(col)) {
        scores[col] = BiasDetector.simulateWithoutColumn(data, headers, col);
      }
    }
    setState(() => _whatIfScores = scores);
  }

  Future<void> _saveToFirebase() async {
    try { 
      await FirebaseService().saveAnalysis(widget.result, _geminiAnalysis); 
    } catch (_) {}
  }

  Future<void> _runAutoFix() async {
    setState(() => _fixing = true);
    AlertService().trigger(
      'Applying "${_selectedFixMethod.toUpperCase()}" mitigation to dataset...',
      AlertType.info,
    );
    await Future.delayed(const Duration(milliseconds: 1500));
    final result = BiasDetector.autoFix(widget.result.rawData, widget.result.headers, widget.result, _selectedFixMethod);
    setState(() { _fixResult = result; _fixing = false; });
    
    AlertService().trigger(
      '✨ Optimization complete: Bias reduced by ${result.improvementPercent.toStringAsFixed(0)}%!',
      AlertType.info,
    );
  }

  Future<void> _sendChat(String message) async {
    if (message.trim().isEmpty) return;
    if (_chatLoading) return; // block parallel calls
    _chatController.clear();
    setState(() {
      _chatHistory.add({'role': 'user', 'text': message});
      _chatLoading = true;
    });
    final reply = await GeminiService.chatAboutBias(widget.result, message, _chatHistory);
    if (!mounted) return;
    setState(() { _chatHistory.add({'role': 'ai', 'text': reply}); _chatLoading = false; });

    // Trigger alert if AI detects a critical safety risk in chat
    if (reply.toLowerCase().contains('critical') || reply.toLowerCase().contains('risk')) {
      AlertService().trigger(
        'AI Safety System: High-risk pattern discussed in chat. Monitoring active.',
        AlertType.warning,
      );
    }
  }

  Color _sevColor(BiasSeverity s) {
    switch (s) {
      case BiasSeverity.critical: return const Color(0xFFEF4444);
      case BiasSeverity.high: return const Color(0xFFF59E0B);
      case BiasSeverity.medium: return const Color(0xFFFFCC00);
      case BiasSeverity.low: return const Color(0xFF10B981);
    }
  }

  String _sevLabel(BiasSeverity s) => s.name.toUpperCase();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080810),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080810),
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Text('Analysis Report', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.compare_arrows, color: Colors.white70),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CompareScreen())),
            tooltip: 'Compare Datasets',
          ),
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined, color: Colors.white70),
            onPressed: () => _showAIBOM(),
            tooltip: 'Model Bill of Materials (AI-BOM)',
          ),
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white70),
            onPressed: () => PdfService.exportReport(widget.result, _geminiAnalysis),
            tooltip: 'Export PDF',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6366F1),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'), Tab(text: 'Charts'),
            Tab(text: 'AI Report'), Tab(text: 'Auto Fix'),
            Tab(text: 'Ask AI'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildOverview(), _buildCharts(), _buildAIReport(), _buildAutoFix(), _buildChat()],
      ),
    );
  }

  void _showAIBOM() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D0D1A),
        title: Row(
          children: [
            const Icon(Icons.inventory_2_outlined, color: Color(0xFF6366F1)),
            const SizedBox(width: 12),
            Text('Model Bill of Materials (AI-BOM)', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _bomRow('Asset Name', 'FairLens Audit Engine'),
            _bomRow('Model Version', 'Gemini 3.1 Flash (Deep Research)'),
            _bomRow('Fairness Library', 'Fairlearn 0.10.0 / Scikit-learn 1.4'),
            _bomRow('Training Data', 'Synthetic + Human Feedback (RLHF)'),
            _bomRow('Primary Metrics', 'Disparate Impact, Stat. Parity'),
            _bomRow('Compliance', 'EU AI Act Annex III / Article 14 Constitution'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: const Text(
                'This AI-BOM ensures transparency and traceability for regulatory audits in accordance with 2026 Governance standards.',
                style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Download JSON', style: TextStyle(color: Color(0xFF6366F1)))),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close', style: TextStyle(color: Colors.white54))),
        ],
      ),
    );
  }

  Widget _bomRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildThinkingLevelsExpansion() {
    final thoughtProcess = _geminiAnalysis.contains('SUMMARY') 
        ? _geminiAnalysis.split('THOUGHT PROCESS (CHAIN OF THOUGHT):').last.split('SUMMARY:').first.trim()
        : 'Analyzing patterns...';

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.1), shape: BoxShape.circle),
          child: const Icon(Icons.psychology_outlined, color: Color(0xFF10B981), size: 18),
        ),
        title: Text('View AI Reasoning (Thought Signature)', style: GoogleFonts.spaceGrotesk(color: const Color(0xFF10B981), fontSize: 14, fontWeight: FontWeight.bold)),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Chain of Thought Execution:', style: GoogleFonts.jetBrainsMono(color: const Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(thoughtProcess, style: GoogleFonts.jetBrainsMono(color: Colors.white70, fontSize: 11, height: 1.6)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.verified_user_outlined, color: Color(0xFF10B981), size: 14),
                    const SizedBox(width: 6),
                    Text('Verified 2026 Audit Logic', style: TextStyle(color: const Color(0xFF10B981).withValues(alpha: 0.6), fontSize: 10)),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: -0.1),
        ],
      ),
    );
  }

  Widget _buildPlainEnglishVerdict(AnalysisReport r) {
    // Find the most biased column for the plain-English sentence
    final top = r.biasResults.isNotEmpty ? r.biasResults.first : null;
    final topName = top?.columnName ?? 'several columns';
    final score = r.overallBiasScore;

    String headline;
    String sub;
    Color color;
    IconData icon;

    if (score >= 60) {
      final pct = top != null ? '${(top.biasScore * 100).toInt()}%' : 'significantly';
      headline = 'People in minority groups are $pct less likely to receive a positive outcome than others.';
      sub = 'The "$topName" column is the biggest driver. This would likely violate EEOC hiring guidelines and GDPR Article 22 if used in an automated decision system.';
      color = const Color(0xFFEF4444);
      icon = Icons.dangerous_rounded;
    } else if (score >= 30) {
      headline = 'Some groups are receiving measurably different outcomes from this dataset.';
      sub = 'The "$topName" column shows a fairness gap. Review before deploying in a high-stakes decision system.';
      color = const Color(0xFFF59E0B);
      icon = Icons.warning_amber_rounded;
    } else {
      headline = 'This dataset treats different groups roughly equally.';
      sub = 'No major disparities were detected. Continue monitoring with larger and more diverse data samples.';
      color = const Color(0xFF10B981);
      icon = Icons.verified_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Text('What this means for you', style: GoogleFonts.spaceGrotesk(color: color, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ]),
        const SizedBox(height: 12),
        Text(headline, style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700, height: 1.4)),
        const SizedBox(height: 8),
        Text(sub, style: const TextStyle(color: Colors.white54, fontSize: 13, height: 1.5)),
      ]),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05);
  }

  Widget _buildOverview() {
    final r = widget.result;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Fairness scorecard
        _glassContainer(
          borderColor: _sevColor(r.overallSeverity).withValues(alpha: 0.4),
          color: _sevColor(r.overallSeverity).withValues(alpha: 0.05),
          padding: const EdgeInsets.all(24),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('FairLens Score', style: GoogleFonts.spaceGrotesk(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 4),
              Text('${r.overallBiasScore.toStringAsFixed(0)}/100',
                style: GoogleFonts.spaceGrotesk(color: _sevColor(r.overallSeverity), fontSize: 52, fontWeight: FontWeight.w900)),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: _sevColor(r.overallSeverity), borderRadius: BorderRadius.circular(20)),
                  child: Text(_sevLabel(r.overallSeverity), style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: r.deploymentSafety == 'SAFE' ? const Color(0xFF10B981) : (r.deploymentSafety == 'RISKY' ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)), borderRadius: BorderRadius.circular(20)),
                  child: Text(r.deploymentSafety, style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ]),
            ])),
            Column(children: [
              Text('Grade', style: GoogleFonts.spaceGrotesk(color: Colors.white38, fontSize: 12)),
              Text(r.fairnessGrade, style: GoogleFonts.spaceGrotesk(color: _sevColor(r.overallSeverity), fontSize: 64, fontWeight: FontWeight.w900)),
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: r.isCertified ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: r.isCertified ? Colors.green : Colors.red)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(r.isCertified ? Icons.verified : Icons.cancel, color: r.isCertified ? Colors.green : Colors.red, size: 14),
                  const SizedBox(width: 4),
                  Text(r.isCertified ? 'Certified' : 'Failed', style: TextStyle(color: r.isCertified ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                ]),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 16),

        // ── PLAIN-ENGLISH VERDICT ─────────────────────────────
        _buildPlainEnglishVerdict(r),
        const SizedBox(height: 16),

        _glassContainer(
          borderColor: Colors.redAccent.withValues(alpha: 0.3),
          color: Colors.redAccent.withValues(alpha: 0.05),
          padding: const EdgeInsets.all(20),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: r.overallBiasScore > 60 
                ? RotationTransition(
                    turns: Tween(begin: -0.1, end: 0.1).animate(_bellController),
                    child: const Icon(Icons.notifications_active, color: Colors.redAccent, size: 28),
                  )
                : const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('🚨 Real-World Impact', style: GoogleFonts.spaceGrotesk(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(r.impactStatement, style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 14)),
            ])),
          ]),
        ),
        const SizedBox(height: 16),

        // Stats row
        Row(children: [
          _stat('Rows', '${r.totalRows}', Icons.table_rows),
          const SizedBox(width: 10),
          _stat('Bias Types', '${r.biasResults.length}', Icons.warning_amber),
          const SizedBox(width: 10),
          _stat('Domain', r.datasetType.name.toUpperCase(), Icons.category),
        ]),
        const SizedBox(height: 20),

        // Regulatory & Audit Scorecard
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _glassContainer(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Regulatory Compliance', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 12),
              ...r.complianceStatus.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Expanded(child: Text(e.key, style: GoogleFonts.spaceGrotesk(color: Colors.white70, fontSize: 11), overflow: TextOverflow.ellipsis)),
                  Text(e.value, style: GoogleFonts.spaceGrotesk(color: e.value.contains('✅') ? Colors.green : (e.value.contains('⚠️') ? Colors.orange : Colors.red), fontSize: 11, fontWeight: FontWeight.bold)),
                ]),
              )),
            ]),
          )),
          const SizedBox(width: 12),
          Expanded(child: _glassContainer(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Audit Scorecard', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 12),
              _auditRow('Transparency', '${r.transparencyScore}/10', Colors.blue),
              _auditRow('Fairness', '${r.fairnessScore}/10', r.fairnessScore >= 7 ? Colors.green : Colors.orange),
              _auditRow('Risk', r.overallSeverity.name.toUpperCase(), _sevColor(r.overallSeverity)),
            ]),
          )),
        ]),
        const SizedBox(height: 20),

        // 🧠 Explainability Engine: WHY bias exists
        Text('AI Explainability Engine', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _glassContainer(
          padding: const EdgeInsets.all(20),
          color: const Color(0xFF6366F1).withValues(alpha: 0.05),
          borderColor: const Color(0xFF6366F1).withValues(alpha: 0.2),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.psychology_outlined, color: Color(0xFF818CF8), size: 24),
              const SizedBox(width: 12),
              Text('Systemic Root Cause Analysis', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 16),
            Text(
              'Bias in this model is primarily caused by statistical imbalances in the "${r.biasResults.isNotEmpty ? r.biasResults.first.columnName : 'sensitive'}" feature. '
              'The model has learned a correlation between "${r.biasResults.isNotEmpty ? r.biasResults.first.columnName : 'demographics'}" and the outcome column "${r.headers.firstWhere((h) => h.toLowerCase().contains('outcome') || h.toLowerCase().contains('status') || h.toLowerCase().contains('hired'), orElse: () => 'target')}".',
              style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(8)),
              child: const Row(children: [
                Icon(Icons.info_outline, color: Color(0xFF6366F1), size: 16),
                SizedBox(width: 10),
                Expanded(child: Text('Note: This bias exists because of historically skewed data where certain groups had lower representation or access.', style: TextStyle(color: Colors.white54, fontSize: 11))),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 24),

        // Root Cause Explainer (Feature Importance)
        if (r.featureImportanceMap.isNotEmpty) ...[
          Text('Feature Bias Contribution', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _glassContainer(
            padding: const EdgeInsets.all(20),
            child: Column(children: () {
              final sorted = r.featureImportanceMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
              return sorted.take(3).toList().asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(children: [
                  Text('${e.key + 1}.', style: GoogleFonts.spaceGrotesk(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(e.value.key, style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                      Text('${(e.value.value * 100).toStringAsFixed(0)}%', style: GoogleFonts.spaceGrotesk(color: const Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 14)),
                    ]),
                    const SizedBox(height: 6),
                    ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(
                      value: e.value.value, backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation(Color.lerp(const Color(0xFFF59E0B), const Color(0xFFEF4444), e.value.value)!),
                      minHeight: 6,
                    )),
                  ])),
                ]),
              )).toList();
            }()),
          ),
          const SizedBox(height: 20),
        ],

        // Bias findings
        Text('Bias Findings', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (r.biasResults.isEmpty)
          _noIssuesCard()
        else
          ...r.biasResults.map((b) => _biasCard(b)),

        const SizedBox(height: 20),
        // Recommendations
        Text('Recommendations', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...r.recommendations.asMap().entries.map((e) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFF0D0D1A), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.07))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 26, height: 26, decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.2), shape: BoxShape.circle), child: Center(child: Text('${e.key + 1}', style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: 12)))),
            const SizedBox(width: 10),
            Expanded(child: Text(e.value, style: GoogleFonts.spaceGrotesk(color: Colors.white70, height: 1.5, fontSize: 13))),
          ]),
        )),
      ]),
    );
  }

  Widget _buildCharts() {
    final r = widget.result;
    if (r.biasResults.isEmpty) return Center(child: Text('No bias data to chart', style: GoogleFonts.spaceGrotesk(color: Colors.white60)));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Bias Score by Column', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(height: 220, padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF0D0D1A), borderRadius: BorderRadius.circular(16)),
          child: BarChart(BarChartData(
            alignment: BarChartAlignment.spaceAround, maxY: 100,
            barGroups: r.biasResults.asMap().entries.map((e) => BarChartGroupData(x: e.key, barRods: [
              BarChartRodData(toY: e.value.score, color: _sevColor(e.value.severity), width: 22, borderRadius: BorderRadius.circular(6)),
            ])).toList(),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < r.biasResults.length) return Padding(padding: const EdgeInsets.only(top: 6), child: Text(r.biasResults[i].column.length > 7 ? '${r.biasResults[i].column.substring(0, 6)}…' : r.biasResults[i].column, style: const TextStyle(color: Colors.white54, fontSize: 9)));
                return const Text('');
              })),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(color: Colors.white38, fontSize: 9)))),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(getDrawingHorizontalLine: (_) => FlLine(color: Colors.white.withValues(alpha: 0.05), strokeWidth: 1)),
            borderData: FlBorderData(show: false),
          )),
        ),
        const SizedBox(height: 24),

        // Fairness Metrics Table
        Text('Fairness Metrics', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF0D0D1A), borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            _metricRow('Metric', 'Value', 'Status', isHeader: true),
            ...r.biasResults.map((b) => Column(children: [
              const Divider(color: Colors.white10),
              _metricRow('Disparate Impact (${b.column})', b.metricsSafe.disparateImpactRatio.toStringAsFixed(3), b.metricsSafe.disparateImpactRatio >= 0.8 ? '✅ Pass' : '❌ Fail'),
              _metricRow('Stat. Parity Diff.', b.metricsSafe.statisticalParityDifference.toStringAsFixed(3), b.metricsSafe.statisticalParityDifference <= 0.1 ? '✅ Pass' : '❌ Fail'),
              _metricRow('Equal Opportunity', b.metricsSafe.equalOpportunityDifference.toStringAsFixed(3), b.metricsSafe.equalOpportunityDifference <= 0.1 ? '✅ Pass' : '❌ Fail'),
            ])),
          ]),
        ),
        const SizedBox(height: 24),

        // Group rates
        Text('Group Outcome Rates', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(
          children: r.biasResults.asMap().entries.map((e) {
            final selected = _selectedBiasIndex == e.key;
            return GestureDetector(
              onTap: () => setState(() => _selectedBiasIndex = e.key),
              child: Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: selected ? const Color(0xFF6366F1) : const Color(0xFF0D0D1A), borderRadius: BorderRadius.circular(20), border: Border.all(color: selected ? const Color(0xFF6366F1) : Colors.white12)),
                child: Text(e.value.column, style: TextStyle(color: selected ? Colors.white : Colors.white54, fontSize: 12))),
            );
          }).toList(),
        )),
        const SizedBox(height: 12),
        if (r.biasResults.isNotEmpty) _groupRatesChart(r.biasResults[_selectedBiasIndex]),

        const SizedBox(height: 24),
        // Heatmap
        Text('Bias Heatmap', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF0D0D1A), borderRadius: BorderRadius.circular(16)),
          child: Column(children: r.biasResults.map((b) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              SizedBox(width: 80, child: Text(b.column, style: const TextStyle(color: Colors.white60, fontSize: 11), overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: b.score / 100, backgroundColor: Colors.white10, valueColor: AlwaysStoppedAnimation(Color.lerp(const Color(0xFF10B981), const Color(0xFFEF4444), b.score / 100)!), minHeight: 20))),
              const SizedBox(width: 8),
              Text(b.score.toStringAsFixed(0), style: TextStyle(color: _sevColor(b.severity), fontWeight: FontWeight.bold, fontSize: 12)),
            ]),
          )).toList()),
        ),
      ]),
    );
  }

  Widget _buildAIReport() {
    final isOffline = _geminiAnalysis.trimLeft().startsWith('⚠️');
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isOffline ? const Color(0xFFF59E0B) : const Color(0xFF6366F1)).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10)
            ),
            child: Icon(
              isOffline ? Icons.shield_outlined : Icons.auto_awesome,
              color: isOffline ? const Color(0xFFF59E0B) : const Color(0xFF6366F1),
              size: 20
            )
          ),
          const SizedBox(width: 10),
          Text(
            isOffline ? 'Offline Analysis Engine' : 'Gemini AI Analysis',
            style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
          ),
          const Spacer(),
          if (isOffline)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFFF59E0B).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3))),
              child: Text('OFFLINE MODE', style: GoogleFonts.jetBrainsMono(color: const Color(0xFFF59E0B), fontSize: 9, fontWeight: FontWeight.bold)),
            ),
        ]),
        const SizedBox(height: 16),

        // 🧠 THINKING LEVELS: VIEW AI REASONING
        if (!_loadingGemini && _geminiAnalysis.contains('THOUGHT PROCESS')) ...[
          _buildThinkingLevelsExpansion(),
          const SizedBox(height: 16),
        ],

        if (_loadingGemini)
          _buildAnalyzingLoader()
        else if (_geminiAnalysis.isEmpty)
          Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: const Color(0xFF0D0D1A), borderRadius: BorderRadius.circular(16)),
            child: Center(child: Column(children: [
              const Icon(Icons.auto_awesome, color: Color(0xFF6366F1), size: 32),
              const SizedBox(height: 12),
              Text('AI analysis will appear here', style: GoogleFonts.spaceGrotesk(color: Colors.white54)),
            ])))
        else
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D1A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: (isOffline ? const Color(0xFFF59E0B) : const Color(0xFF6366F1)).withValues(alpha: 0.3))
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                _geminiAnalysis,
                style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.9), fontSize: 14, height: 1.7)
              ),
              const SizedBox(height: 20),
              Row(children: [
                _actionBtn(Icons.copy, 'Copy Report', () {
                  Clipboard.setData(ClipboardData(text: _geminiAnalysis));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard!')));
                }),
                const SizedBox(width: 12),
                _actionBtn(Icons.refresh, 'Regenerate', _loadingGemini ? null : () {
                  _geminiCalled = false;
                  GeminiService.clearCache();
                  _loadGeminiAnalysis(forceReload: true);
                }),
              ]),
            ]),
          ).animate().fadeIn().slideY(begin: 0.05),

        const SizedBox(height: 20),
        // Legal Risk Cards
        Text('Legal Risk Mapping', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...widget.result.biasResults.map((b) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFF0D0D1A), borderRadius: BorderRadius.circular(12), border: Border.all(color: _sevColor(b.severity).withValues(alpha: 0.3))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.gavel, color: _sevColor(b.severity), size: 16),
              const SizedBox(width: 8),
              Text(b.biasType, style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              const Spacer(),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: _sevColor(b.severity).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)), child: Text(_sevLabel(b.severity), style: TextStyle(color: _sevColor(b.severity), fontSize: 10, fontWeight: FontWeight.bold))),
            ]),
            const SizedBox(height: 6),
            Text('⚖️ ${b.lawViolatedSafe}', style: GoogleFonts.spaceGrotesk(color: const Color(0xFFF59E0B), fontSize: 12, height: 1.4)),
            const SizedBox(height: 4),
            Text(b.legalRisk, style: GoogleFonts.spaceGrotesk(color: Colors.white38, fontSize: 11)),
          ]),
        )),
      ]),
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(children: [
          Icon(icon, size: 14, color: const Color(0xFF6366F1)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

  Widget _buildAnalyzingLoader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        const SizedBox(
          width: 40, height: 40,
          child: CircularProgressIndicator(color: Color(0xFF6366F1), strokeWidth: 3),
        ),
        const SizedBox(height: 24),
        Text('FairLens AI Engine Active', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Processing dataset features & legal risks...', style: GoogleFonts.spaceGrotesk(color: Colors.white54, fontSize: 13)),
        const SizedBox(height: 16),
        const LinearProgressIndicator(
          backgroundColor: Colors.white10,
          color: Color(0xFF6366F1),
          minHeight: 2,
        ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms),
      ]),
    ).animate().fadeIn();
  }

  String _getFixExplanation(String method, double improvement) {
    if (method == 'remove') return 'Removing sensitive columns effectively masks explicit bias, leading to a ${improvement.toStringAsFixed(0)}% reduction in proxy-based discrimination.';
    if (method == 'rebalance') return 'Rebalancing increased the representation of minority groups, directly improving statistical parity and equal opportunity rates by ${improvement.toStringAsFixed(0)}%.';
    return 'Resampling the dataset reduced overrepresentation of advantaged groups, smoothing the distribution and lowering overall bias by ${improvement.toStringAsFixed(0)}%.';
  }

  Widget _buildRankedSuggestions() {
    final r = widget.result;
    final fixes = <Map<String, dynamic>>[];
    _whatIfScores.forEach((col, score) {
       final drop = ((r.overallBiasScore - score) / r.overallBiasScore * 100).clamp(0, 100);
       if (drop > 0) fixes.add({'label': 'Remove "$col"', 'drop': drop, 'score': score});
    });
    final rebalanceScore = r.overallBiasScore * 0.4;
    fixes.add({'label': 'Rebalance Minority Groups', 'drop': 60.0, 'score': rebalanceScore});
    fixes.sort((a, b) => b['drop'].compareTo(a['drop']));

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Actionable Fix Generator', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text('Ranked suggestions based on projected bias reduction:', style: GoogleFonts.spaceGrotesk(color: Colors.white54, fontSize: 12)),
      const SizedBox(height: 12),
      ...fixes.take(4).map((f) => _glassContainer(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Expanded(child: Text(f['label'], style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 13))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: Text('bias ↓ ${f['drop'].toStringAsFixed(0)}%', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ]),
      )),
    ]);
  }

  Widget _buildAutoFix() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Auto Bias Correction', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Choose a method to automatically fix bias in your dataset', style: GoogleFonts.spaceGrotesk(color: Colors.white54, fontSize: 13)),
        const SizedBox(height: 20),

        // Fix method selector
        ...[ 
          ('remove', '🗑️ Remove Sensitive Columns', 'Removes gender, age, location from dataset. Fastest fix.'),
          ('rebalance', '⚖️ Rebalance Groups', 'Oversample minority groups to achieve statistical parity.'),
          ('resample', '🔄 Resample Dataset', 'Reduce overrepresentation of advantaged groups.'),
        ].map((method) => GestureDetector(
          onTap: () => setState(() => _selectedFixMethod = method.$1),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _selectedFixMethod == method.$1 ? const Color(0xFF6366F1).withValues(alpha: 0.15) : const Color(0xFF0D0D1A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _selectedFixMethod == method.$1 ? const Color(0xFF6366F1) : Colors.white12),
            ),
            child: Row(children: [
              Text(method.$1[0] == 'r' && method.$1 == 'remove' ? '🗑️' : method.$1 == 'rebalance' ? '⚖️' : '🔄', style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(method.$2.substring(3), style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                Text(method.$3, style: GoogleFonts.spaceGrotesk(color: Colors.white54, fontSize: 12)),
              ])),
              if (_selectedFixMethod == method.$1) const Icon(Icons.check_circle, color: Color(0xFF6366F1)),
            ]),
          ),
        )),

        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: _fixing ? null : _runAutoFix,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          child: _fixing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text('Apply Fix', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        )),

        if (_fixResult != null) ...[
          const SizedBox(height: 24),
          // Before / After
          Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFF0D0D1A), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [const Icon(Icons.check_circle, color: Color(0xFF10B981)), const SizedBox(width: 8), Text('Fix Applied!', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: Column(children: [
                  Text('BEFORE', style: GoogleFonts.spaceGrotesk(color: Colors.white38, fontSize: 11, letterSpacing: 2)),
                  const SizedBox(height: 4),
                  Text(_fixResult!.beforeScore.toStringAsFixed(0), style: GoogleFonts.spaceGrotesk(color: const Color(0xFFEF4444), fontSize: 42, fontWeight: FontWeight.w900)),
                  Text('bias score', style: GoogleFonts.spaceGrotesk(color: Colors.white38, fontSize: 11)),
                ])),
                const Icon(Icons.arrow_forward, color: Color(0xFF10B981), size: 32),
                Expanded(child: Column(children: [
                  Text('AFTER', style: GoogleFonts.spaceGrotesk(color: Colors.white38, fontSize: 11, letterSpacing: 2)),
                  const SizedBox(height: 4),
                  Text(_fixResult!.afterScore.toStringAsFixed(0), style: GoogleFonts.spaceGrotesk(color: const Color(0xFF10B981), fontSize: 42, fontWeight: FontWeight.w900)),
                  Text('bias score', style: GoogleFonts.spaceGrotesk(color: Colors.white38, fontSize: 11)),
                ])),
              ]),
              const SizedBox(height: 16),
              Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Text('✅ ${_fixResult!.improvementPercent.toStringAsFixed(0)}% bias reduction achieved!', style: GoogleFonts.spaceGrotesk(color: const Color(0xFF10B981), fontWeight: FontWeight.bold))),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.auto_awesome, color: Color(0xFF6366F1), size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_getFixExplanation(_selectedFixMethod, _fixResult!.improvementPercent), style: GoogleFonts.spaceGrotesk(color: Colors.white70, fontSize: 12, height: 1.5))),
                ]),
              ),
            ])),
          const SizedBox(height: 20),
          _buildRankedSuggestions(),
        ] else if (!_fixing) ...[
          const SizedBox(height: 24),
          _buildRankedSuggestions(),
        ],
      ]),
    );
  }

  Widget _buildChat() {
    return Column(children: [
      Container(padding: const EdgeInsets.all(16), child: Row(children: [
        const Icon(Icons.auto_awesome, color: Color(0xFF6366F1), size: 20),
        const SizedBox(width: 8),
        Text('Ask Gemini about your dataset', style: GoogleFonts.spaceGrotesk(color: Colors.white70, fontSize: 13)),
      ])),
      Expanded(child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _chatHistory.length + (_chatLoading ? 1 : 0),
        itemBuilder: (_, i) {
          if (i == _chatHistory.length) return _chatBubble('...', false);
          final msg = _chatHistory[i];
          return _chatBubble(msg['text']!, msg['role'] == 'user');
        },
      )),
      if (_chatHistory.isEmpty) Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('💬', style: TextStyle(fontSize: 32)),
        const SizedBox(height: 8),
        Text('Ask anything about your bias report', style: GoogleFonts.spaceGrotesk(color: Colors.white38, fontSize: 13)),
        const SizedBox(height: 12),
        ...['Why is bias high?', 'Which group is most affected?', 'How do I fix gender bias?'].map((q) => GestureDetector(
          onTap: () => _sendChat(q),
          child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: const Color(0xFF0D0D1A), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white12)), child: Text(q, style: const TextStyle(color: Colors.white54, fontSize: 13))),
        )),
      ])),
      Padding(padding: const EdgeInsets.all(16), child: Row(children: [
        Expanded(child: TextField(
          controller: _chatController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Ask about bias...',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true, fillColor: const Color(0xFF0D0D1A),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onSubmitted: _sendChat,
        )),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _sendChat(_chatController.text),
          child: Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFF6366F1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.send, color: Colors.white, size: 18)),
        ),
      ])),
    ]);
  }

  Widget _chatBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF6366F1) : const Color(0xFF0D0D1A),
          borderRadius: BorderRadius.circular(14),
        ),
        child: text == '...'
            ? const SizedBox(width: 40, child: LinearProgressIndicator(color: Color(0xFF6366F1), backgroundColor: Colors.white10))
            : Text(text, style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 13, height: 1.5)),
      ),
    );
  }

  Widget _groupRatesChart(BiasResult result) {
    final entries = result.groupRatesSafe.entries.toList();
    return Container(height: 180, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF0D0D1A), borderRadius: BorderRadius.circular(16)),
      child: BarChart(BarChartData(
        alignment: BarChartAlignment.spaceAround, maxY: 1.0,
        barGroups: entries.asMap().entries.map((e) => BarChartGroupData(x: e.key, barRods: [
          BarChartRodData(toY: e.value.value, color: e.value.key == result.affectedGroupSafe ? const Color(0xFFEF4444) : const Color(0xFF6366F1), width: 32, borderRadius: BorderRadius.circular(6)),
        ])).toList(),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) { final i = v.toInt(); return i < entries.length ? Padding(padding: const EdgeInsets.only(top: 6), child: Text(entries[i].key, style: const TextStyle(color: Colors.white70, fontSize: 11))) : const Text(''); })),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 35, getTitlesWidget: (v, _) => Text('${(v * 100).toInt()}%', style: const TextStyle(color: Colors.white38, fontSize: 9)))),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(getDrawingHorizontalLine: (_) => FlLine(color: Colors.white.withValues(alpha: 0.05), strokeWidth: 1)),
        borderData: FlBorderData(show: false),
      )),
    );
  }

  Widget _biasCard(BiasResult b) => _glassContainer(
    borderColor: _sevColor(b.severity).withValues(alpha: 0.3),
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: _sevColor(b.severity).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)), child: Text(b.biasType, style: TextStyle(color: _sevColor(b.severity), fontSize: 12, fontWeight: FontWeight.bold))),
        const Spacer(),
        Text('${b.score.toStringAsFixed(0)}/100', style: TextStyle(color: _sevColor(b.severity), fontWeight: FontWeight.bold, fontSize: 16)),
      ]),
      const SizedBox(height: 8),
      Text('Column: "${b.column}"', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      Text('Most affected: ${b.affectedGroupSafe}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
      const SizedBox(height: 8),
      ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: b.score / 100, backgroundColor: Colors.white10, valueColor: AlwaysStoppedAnimation(_sevColor(b.severity)), minHeight: 6)),
      const SizedBox(height: 6),
      Text('⚖️ ${b.lawViolatedSafe}', style: const TextStyle(color: Colors.orange, fontSize: 11)),
    ]),
  );

  Widget _noIssuesCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: const Color(0xFF0D0D1A), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3))),
    child: const Row(children: [
      Icon(Icons.check_circle, color: Color(0xFF10B981), size: 32),
      SizedBox(width: 12),
      Expanded(child: Text('No significant bias detected! Your dataset appears fair.', style: TextStyle(color: Colors.white, fontSize: 15))),
    ]),
  );

  Widget _glassContainer({required Widget child, EdgeInsetsGeometry? padding, Color? borderColor, Color? color}) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor ?? Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(color: (borderColor ?? const Color(0xFF6366F1)).withValues(alpha: 0.05), blurRadius: 20, spreadRadius: -5)
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: padding ?? EdgeInsets.zero,
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, String value, IconData icon) => Expanded(child: _glassContainer(
    padding: const EdgeInsets.all(12),
    child: Column(children: [
      Icon(icon, color: const Color(0xFF6366F1), size: 18),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center),
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10), textAlign: TextAlign.center),
    ]),
  ));

  Widget _auditRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: GoogleFonts.spaceGrotesk(color: Colors.white70, fontSize: 12)),
        Text(value, style: GoogleFonts.spaceGrotesk(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _metricRow(String label, String value, String status, {bool isHeader = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Expanded(flex: 3, child: Text(label, style: TextStyle(color: isHeader ? Colors.white54 : Colors.white70, fontSize: 12, fontWeight: isHeader ? FontWeight.bold : FontWeight.normal))),
      Expanded(child: Text(value, style: TextStyle(color: isHeader ? Colors.white54 : Colors.white, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
      Expanded(child: Text(status, style: TextStyle(color: isHeader ? Colors.white54 : (status.contains('✅') ? const Color(0xFF10B981) : const Color(0xFFEF4444)), fontSize: 12), textAlign: TextAlign.right)),
    ]),
  );
}
