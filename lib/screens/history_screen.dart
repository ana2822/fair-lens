import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/firebase_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _analyses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await FirebaseService().getPastAnalyses();
    setState(() { _analyses = data; _loading = false; });
  }

  Color _scoreColor(double s) => s > 0.6
      ? const Color(0xFFEF4444) : s > 0.3
      ? const Color(0xFFF59E0B) : const Color(0xFF10B981);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080810),
      body: SafeArea(child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
              ),
            ),
            const SizedBox(width: 12),
            Text('Analysis History', style: GoogleFonts.spaceGrotesk(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
        ),
        const SizedBox(height: 20),
        if (!_loading && _analyses.length >= 2) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildImprovementTracker(),
          ),
          const SizedBox(height: 16),
        ],
        Expanded(
          child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
            : _analyses.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('📊', style: TextStyle(fontSize: 40)),
                    const SizedBox(height: 12),
                    Text('No analyses yet', style: GoogleFonts.spaceGrotesk(
                      color: Colors.white38, fontSize: 14)),
                  ]))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: _analyses.length,
                  itemBuilder: (_, i) {
                    final a = _analyses[i];
                    final score = (a['overallBiasScore'] as num?)?.toDouble() ?? 0;
                    final color = _scoreColor(score);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D0D1A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
                      ),
                      child: Row(children: [
                        Container(
                          width: 46, height: 46,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(child: Text('${score.toInt()}',
                            style: GoogleFonts.spaceGrotesk(
                              color: color, fontSize: 16, fontWeight: FontWeight.w800))),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(a['datasetName'] ?? 'Unknown',
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white, fontSize: 13,
                              fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text('${a['totalRows'] ?? 0} rows • ${a['analyzedAt']?.toString().substring(0, 10) ?? ''}',
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white30, fontSize: 11)),
                        ])),
                        const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
                      ]),
                    ).animate().fadeIn(delay: Duration(milliseconds: 60 * i));
                  },
                ),
        ),
      ])),
    );
  }

  Widget _buildImprovementTracker() {
    // Assuming _analyses is sorted newest first
    final newest = (_analyses.first['overallBiasScore'] as num?)?.toDouble() ?? 0;
    final oldest = (_analyses.last['overallBiasScore'] as num?)?.toDouble() ?? 0;
    final diff = oldest.toInt() - newest.toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Fairness Improvement Tracker', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 12),
        Row(children: [
          Icon(diff > 0 ? Icons.trending_down : Icons.trending_up, color: diff > 0 ? const Color(0xFF10B981) : Colors.redAccent, size: 28),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(diff > 0 ? 'Bias reduced over time' : 'Bias increased over time', style: GoogleFonts.spaceGrotesk(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 4),
            Row(children: [
              Text('${oldest.toInt()}', style: GoogleFonts.spaceGrotesk(color: Colors.white38, fontSize: 24, fontWeight: FontWeight.bold)),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.arrow_forward, color: Colors.white38, size: 16)),
              Text('${newest.toInt()}', style: GoogleFonts.spaceGrotesk(color: diff > 0 ? const Color(0xFF10B981) : Colors.redAccent, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              if (diff > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                  child: Text('↓ $diff pts', style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold)),
                ),
            ]),
          ])),
        ]),
      ]),
    ).animate().fadeIn();
  }
}
