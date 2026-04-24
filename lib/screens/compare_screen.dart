import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/bias_detector.dart';

class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});
  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  AnalysisReport? _result1, _result2;
  String? _name1, _name2;
  bool _loading1 = false, _loading2 = false;
  String? _error;

  Future<void> _pickFile(int slot) async {
    setState(() { _error = null; if (slot == 1) _loading1 = true; else _loading2 = true; });
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['csv'], withData: true);
      if (picked == null || picked.files.isEmpty) return;
      final file = picked.files.first;
      final csvString = String.fromCharCodes(file.bytes!);
      final cleanedCsv = csvString.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
      final rows = const CsvToListConverter(fieldDelimiter: ',', eol: '\n').convert(cleanedCsv).where((r) => r.isNotEmpty).toList();
      if (rows.length < 2) { setState(() => _error = 'CSV must have at least 2 valid rows'); return; }
      final headers = rows.first.map((e) => e.toString()).toList();
      final strData = rows.skip(1).map((row) {
        final map = <String, String>{};
        for (int i = 0; i < headers.length; i++) {
          map[headers[i]] = i < row.length ? row[i].toString() : '';
        }
        return map;
      }).toList();
      final r = BiasDetector.analyze(
        strData.map((row) => row.map((k, v) => MapEntry(k, v as dynamic))).toList(),
        headers,
      );
      setState(() { if (slot == 1) { _result1 = r; _name1 = file.name; } else { _result2 = r; _name2 = file.name; } });
    } catch (e) {
      setState(() => _error = 'Error: $e');
    } finally {
      setState(() { if (slot == 1) _loading1 = false; else _loading2 = false; });
    }
  }

  Color _scoreColor(double s) => s > 60 ? const Color(0xFFEF4444) : s > 30 ? const Color(0xFFF59E0B) : const Color(0xFF10B981);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080810),
      body: SafeArea(child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white.withOpacity(0.1))),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
              ),
            ),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Compare Datasets', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
              Text('Upload 2 CSVs to compare bias', style: GoogleFonts.spaceGrotesk(color: Colors.white30, fontSize: 11)),
            ]),
          ]),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.withOpacity(0.2))),
              child: Row(children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!, style: GoogleFonts.spaceGrotesk(color: Colors.redAccent, fontSize: 12))),
              ]),
            ),
          ),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: _uploadSlot(1, _name1, _result1, _loading1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 35),
                child: Column(children: [
                  const Icon(Icons.compare_arrows_rounded, color: Color(0xFF6366F1), size: 26),
                  const SizedBox(height: 4),
                  Text('VS', style: GoogleFonts.spaceGrotesk(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w800)),
                ]),
              ),
              Expanded(child: _uploadSlot(2, _name2, _result2, _loading2)),
            ]),
            if (_result1 == null || _result2 == null) ...[
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.15))),
                child: Column(children: [
                  const Icon(Icons.info_outline, color: Color(0xFF818CF8), size: 28),
                  const SizedBox(height: 10),
                  Text('How to Compare', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('1. Upload Dataset 1 (e.g. old hiring data)\n2. Upload Dataset 2 (e.g. updated data)\n3. See which one has less bias', textAlign: TextAlign.center,
                    style: GoogleFonts.spaceGrotesk(color: Colors.white38, fontSize: 12, height: 1.8)),
                ]),
              ),
            ],
            if (_result1 != null && _result2 != null) ...[
              const SizedBox(height: 30),
              _buildComparison(_result1!, _result2!),
            ],
          ]),
        )),
      ])),
    );
  }

  Widget _uploadSlot(int slot, String? name, AnalysisReport? result, bool loading) {
    final color = slot == 1 ? const Color(0xFF6366F1) : const Color(0xFF8B5CF6);
    return GestureDetector(
      onTap: loading ? null : () => _pickFile(slot),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: result != null ? color.withOpacity(0.06) : const Color(0xFF0D0D1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: result != null ? color.withOpacity(0.4) : color.withOpacity(0.2), width: result != null ? 1.5 : 1),
        ),
        child: loading
          ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1), strokeWidth: 2)))
          : result == null
            ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const SizedBox(height: 12),
                Container(width: 48, height: 48,
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.25))),
                  child: Icon(Icons.upload_file_rounded, color: color, size: 24)),
                const SizedBox(height: 10),
                Text('Dataset $slot', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Tap to upload CSV', style: GoogleFonts.spaceGrotesk(color: Colors.white30, fontSize: 11)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.3))),
                  child: Text('Choose File', style: GoogleFonts.spaceGrotesk(color: color, fontSize: 12, fontWeight: FontWeight.w700))),
                const SizedBox(height: 12),
              ])
            : Column(children: [
                Icon(Icons.check_circle_rounded, color: color, size: 18),
                const SizedBox(height: 8),
                Text('${result.overallBiasScore.toStringAsFixed(0)}',
                  style: GoogleFonts.spaceGrotesk(color: color, fontSize: 40, fontWeight: FontWeight.w900)),
                Text('/ 100 bias score', style: GoogleFonts.spaceGrotesk(color: Colors.white38, fontSize: 11)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: _scoreColor(result.overallBiasScore).withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                  child: Text('Grade ${result.fairnessGrade}', style: GoogleFonts.spaceGrotesk(color: _scoreColor(result.overallBiasScore), fontSize: 11, fontWeight: FontWeight.w700))),
                const SizedBox(height: 6),
                Text(name ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.spaceGrotesk(color: Colors.white24, fontSize: 10)),
                const SizedBox(height: 8),
                GestureDetector(onTap: () => _pickFile(slot),
                  child: Text('Change', style: GoogleFonts.spaceGrotesk(color: color.withOpacity(0.6), fontSize: 11, decoration: TextDecoration.underline))),
              ]),
      ),
    );
  }

  Widget _buildComparison(AnalysisReport r1, AnalysisReport r2) {
    final improved = r2.overallBiasScore < r1.overallBiasScore;
    final diff = (r1.overallBiasScore - r2.overallBiasScore).abs();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: improved
            ? [const Color(0xFF10B981).withOpacity(0.12), const Color(0xFF080810)]
            : [const Color(0xFFEF4444).withOpacity(0.08), const Color(0xFF080810)]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: improved ? const Color(0xFF10B981).withOpacity(0.3) : const Color(0xFFEF4444).withOpacity(0.2)),
        ),
        child: Column(children: [
          Text(improved ? '🏆' : '⚠️', style: const TextStyle(fontSize: 30)),
          const SizedBox(height: 8),
          Text(improved ? 'Dataset 2 is ${diff.toStringAsFixed(0)}% less biased!' : 'Dataset 1 is ${diff.toStringAsFixed(0)}% less biased!',
            style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
          Text(improved ? '"${_name2 ?? "Dataset 2"}" is fairer' : '"${_name1 ?? "Dataset 1"}" is fairer',
            style: GoogleFonts.spaceGrotesk(color: Colors.white38, fontSize: 12)),
        ]),
      ),
      const SizedBox(height: 24),
      Text('SCORE COMPARISON', style: GoogleFonts.spaceGrotesk(color: Colors.white30, fontSize: 10, letterSpacing: 2)),
      const SizedBox(height: 14),
      SizedBox(height: 180, child: BarChart(BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        barGroups: [
          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: r1.overallBiasScore, color: const Color(0xFF6366F1), width: 50, borderRadius: BorderRadius.circular(8))]),
          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: r2.overallBiasScore, color: const Color(0xFF8B5CF6), width: 50, borderRadius: BorderRadius.circular(8))]),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28,
            getTitlesWidget: (v, _) => Padding(padding: const EdgeInsets.only(top: 6),
              child: Text(v.toInt() == 0 ? 'Dataset 1' : 'Dataset 2', style: GoogleFonts.spaceGrotesk(color: Colors.white38, fontSize: 11))))),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32,
            getTitlesWidget: (v, _) => Text('${v.toInt()}%', style: GoogleFonts.spaceGrotesk(color: Colors.white24, fontSize: 9)))),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: Colors.white.withOpacity(0.05), strokeWidth: 1)),
        borderData: FlBorderData(show: false),
      ))),
      const SizedBox(height: 24),
      Text('BIAS BY COLUMN', style: GoogleFonts.spaceGrotesk(color: Colors.white30, fontSize: 10, letterSpacing: 2)),
      const SizedBox(height: 12),
      ...{...r1.biasResults.map((b) => b.columnName), ...r2.biasResults.map((b) => b.columnName)}.map((col) {
        final b1 = r1.biasResults.where((b) => b.columnName == col).map((b) => b.biasScore).firstOrNull ?? 0.0;
        final b2 = r2.biasResults.where((b) => b.columnName == col).map((b) => b.biasScore).firstOrNull ?? 0.0;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFF0D0D1A), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withOpacity(0.07))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(col, style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: b2 <= b1 ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(5)),
                child: Text(b2 <= b1 ? '✓ Improved' : '↑ Worse',
                  style: GoogleFonts.spaceGrotesk(color: b2 <= b1 ? const Color(0xFF10B981) : const Color(0xFFEF4444), fontSize: 10, fontWeight: FontWeight.w700))),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              SizedBox(width: 68, child: Text('Dataset 1', style: GoogleFonts.spaceGrotesk(color: Colors.white30, fontSize: 10))),
              Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: b1, backgroundColor: Colors.white.withOpacity(0.05), valueColor: const AlwaysStoppedAnimation(Color(0xFF6366F1)), minHeight: 6))),
              const SizedBox(width: 8),
              Text('${(b1 * 100).toInt()}%', style: GoogleFonts.spaceGrotesk(color: const Color(0xFF6366F1), fontSize: 11, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              SizedBox(width: 68, child: Text('Dataset 2', style: GoogleFonts.spaceGrotesk(color: Colors.white30, fontSize: 10))),
              Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: b2, backgroundColor: Colors.white.withOpacity(0.05), valueColor: const AlwaysStoppedAnimation(Color(0xFF8B5CF6)), minHeight: 6))),
              const SizedBox(width: 8),
              Text('${(b2 * 100).toInt()}%', style: GoogleFonts.spaceGrotesk(color: const Color(0xFF8B5CF6), fontSize: 11, fontWeight: FontWeight.w700)),
            ]),
          ]),
        );
      }).toList(),
    ]);
  }
}
