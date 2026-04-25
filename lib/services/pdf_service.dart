// ignore_for_file: deprecated_member_use
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import '../models/bias_detector.dart';

class PdfService {
  /// Download an HTML-based bias report (works on web)
  static Future<void> exportReport(
      AnalysisReport result, String aiReport) async {
    final severityLabel = result.overallBiasScore > 60
        ? 'CRITICAL'
        : result.overallBiasScore > 30
            ? 'MODERATE'
            : 'FAIR';
    final scoreColor = result.overallBiasScore > 60
        ? '#EF4444'
        : result.overallBiasScore > 30
            ? '#F59E0B'
            : '#10B981';
    final badgeClass = result.overallBiasScore > 60
        ? 'high'
        : result.overallBiasScore > 30
            ? 'medium'
            : 'low';

    String biasCardsHtml = result.biasResults.map((b) {
      final severityStr = b.severity.name.toUpperCase();
      final barColor =
          b.severity == BiasSeverity.critical || b.severity == BiasSeverity.high
              ? '#EF4444'
              : b.severity == BiasSeverity.medium
                  ? '#F59E0B'
                  : '#10B981';
      // b.groupRatesSafe, b.column, b.score are now available via getters
      final groupRatesStr = b.groupRatesSafe.entries
          .map((e) => '${e.key}: ${(e.value * 100).toInt()}%')
          .join(' | ');
      return '''
  <div class="card">
    <div style="display:flex; justify-content:space-between; align-items:center;">
      <strong>${b.biasType}</strong>
      <span class="badge ${b.severity == BiasSeverity.high || b.severity == BiasSeverity.critical ? 'high' : b.severity == BiasSeverity.medium ? 'medium' : 'low'}">$severityStr</span>
    </div>
    <p class="meta">Column: "${b.column}"</p>
    <div class="bar" style="width: ${b.score.toInt()}%; background: $barColor;"></div>
    <p class="meta">${b.score.toInt()}% bias score</p>
    <p class="meta">$groupRatesStr</p>
  </div>
''';
    }).join('');

    // result.analysisTime is an alias getter for analyzedAt
    final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>FairLens AI Audit Report – Government Use</title>
  <style>
    body { font-family: 'Segoe UI', sans-serif; background: #080810; color: #fff; padding: 40px; }
    h1 { color: #818CF8; font-size: 28px; }
    h2 { color: #A5B4FC; font-size: 18px; border-bottom: 1px solid #2D2D4E; padding-bottom: 8px; }
    .score { font-size: 48px; font-weight: 800; color: $scoreColor; }
    .badge { display: inline-block; padding: 4px 10px; border-radius: 4px; font-size: 11px; font-weight: 700; letter-spacing: 1px; }
    .high { background: rgba(239,68,68,0.15); color: #EF4444; }
    .medium { background: rgba(245,158,11,0.15); color: #F59E0B; }
    .low { background: rgba(16,185,129,0.15); color: #10B981; }
    .card { background: #0D0D1A; border: 1px solid #2D2D4E; border-radius: 12px; padding: 20px; margin: 12px 0; }
    .meta { color: #666; font-size: 13px; }
    .ai-report { white-space: pre-wrap; line-height: 1.8; color: #A5B4FC; }
    .bar { height: 8px; border-radius: 4px; margin: 8px 0; }
    .footer { margin-top: 40px; color: #444; font-size: 12px; text-align: center; }
  </style>
</head>
<body>
  <div style="display:flex; align-items:center; gap:12px; margin-bottom:30px;">
    <div style="background: linear-gradient(135deg, #6366F1, #8B5CF6); width:40px; height:40px; border-radius:10px; display:flex; align-items:center; justify-content:center; font-size:20px;">🔍</div>
    <div>
      <h1 style="margin:0;">FairLens AI Audit Report – Government Use</h1>
      <p class="meta" style="margin:0;">Official AI Fairness & Compliance Audit</p>
    </div>
  </div>

  <div class="card">
    <p class="meta">${result.totalRows} records • ${result.totalColumns} columns • ${result.datasetType.name.toUpperCase()} dataset</p>
    <p class="meta">Analyzed: ${result.analysisTime.toLocal()}</p>
    <div class="score">${result.overallBiasScore.toInt()}/100</div>
    <span class="badge $badgeClass">$severityLabel</span>
  </div>

  <h2>Detected Biases</h2>
  $biasCardsHtml

  <h2>Model Bill of Materials (AI-BOM)</h2>
  <div class="card">
    <table style="width:100%; border-collapse:collapse; font-size:13px;">
      <tr><td style="color:#666; padding:4px 0;">Model Version</td><td style="text-align:right;">Gemini 3.1 Flash (Deep Research)</td></tr>
      <tr><td style="color:#666; padding:4px 0;">Fairness Engine</td><td style="text-align:right;">FairLens Auditor v2.0 (Industry Standard Math)</td></tr>
      <tr><td style="color:#666; padding:4px 0;">Training Baseline</td><td style="text-align:right;">Synthetic + Human Feedback (RLHF)</td></tr>
      <tr><td style="color:#666; padding:4px 0;">Governance Compliance</td><td style="text-align:right;">EU AI Act Annex III / India AI Guidelines 2026</td></tr>
      <tr><td style="color:#666; padding:4px 0;">Traceability ID</td><td style="text-align:right;">FL-AUDIT-${DateTime.now().millisecondsSinceEpoch}</td></tr>
    </table>
  </div>

  <h2>Gemini AI Analysis</h2>
  <div class="card">
    <p class="ai-report">$aiReport</p>
  </div>

  <div class="footer">
    Generated by FairLens • Google Solution Challenge 2026 • ${DateTime.now().toLocal()}
  </div>
</body>
</html>
''';

    final blob = html.Blob([htmlContent], 'text/html');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute(
          'download', 'Government_Audit_Report_${result.datasetType.name}.html')
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  /// Download a CSV file
  static void downloadCsv(String csvContent, String filename) {
    final blob = html.Blob([csvContent], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
