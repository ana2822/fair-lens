// ignore_for_file: deprecated_member_use
// ignore: avoid_web_libraries_in_flutter
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
        ? '#DC2626'
        : result.overallBiasScore > 30
            ? '#D97706'
            : '#059669';
    final badgeClass = result.overallBiasScore > 60
        ? 'high'
        : result.overallBiasScore > 30
            ? 'medium'
            : 'low';

    String biasCardsHtml = result.biasResults.map((b) {
      final severityStr = b.severity.name.toUpperCase();
      final barColor =
          b.severity == BiasSeverity.critical || b.severity == BiasSeverity.high
              ? '#DC2626'
              : b.severity == BiasSeverity.medium
                  ? '#D97706'
                  : '#059669';
      final groupRatesStr = b.groupRatesSafe.entries
          .where((e) => e.key != 'Unknown' && e.key.isNotEmpty)
          .map((e) => '${e.key}: ${(e.value * 100).toStringAsFixed(1)}%')
          .join(' | ');
      return '''
  <div class="card">
    <div style="display:flex; justify-content:space-between; align-items:center;">
      <strong style="color:#1E1E2E;">${b.biasType}</strong>
      <span class="badge ${b.severity == BiasSeverity.high || b.severity == BiasSeverity.critical ? 'high' : b.severity == BiasSeverity.medium ? 'medium' : 'low'}">$severityStr</span>
    </div>
    <p class="meta">Column: "${b.column}"</p>
    <div class="bar-bg">
      <div class="bar" style="width: ${b.score.toInt()}%; background: $barColor;"></div>
    </div>
    <p class="meta">${b.score.toInt()}% bias score</p>
    <p class="meta">$groupRatesStr</p>
  </div>
''';
    }).join('');

    final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>FairLens AI Audit Report</title>
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap');

    * { box-sizing: border-box; margin: 0; padding: 0; }

    body {
      font-family: 'Inter', 'Segoe UI', Arial, sans-serif;
      background: #F8F9FC;
      color: #1E1E2E;
      padding: 0;
    }

    .page {
      max-width: 900px;
      margin: 0 auto;
      background: #ffffff;
      padding: 48px 56px;
      box-shadow: 0 1px 4px rgba(0,0,0,0.08);
    }

    /* Header */
    .header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding-bottom: 24px;
      border-bottom: 2px solid #E5E7EB;
      margin-bottom: 32px;
    }
    .header-left { display: flex; align-items: center; gap: 14px; }
    .logo {
      background: linear-gradient(135deg, #6366F1, #8B5CF6);
      width: 44px; height: 44px;
      border-radius: 10px;
      display: flex; align-items: center; justify-content: center;
      font-size: 22px;
    }
    .header h1 { font-size: 22px; font-weight: 800; color: #1E1E2E; }
    .header .subtitle { font-size: 12px; color: #6B7280; margin-top: 2px; }
    .header-right { text-align: right; }
    .header-right .label { font-size: 11px; color: #9CA3AF; text-transform: uppercase; letter-spacing: 1px; }
    .header-right .value { font-size: 13px; color: #374151; font-weight: 500; margin-top: 2px; }

    /* Summary card */
    .summary {
      background: #F3F4F6;
      border-radius: 12px;
      padding: 24px 28px;
      margin-bottom: 32px;
      display: flex;
      align-items: center;
      justify-content: space-between;
    }
    .score-block .score {
      font-size: 56px;
      font-weight: 800;
      color: $scoreColor;
      line-height: 1;
    }
    .score-block .score-label {
      font-size: 12px;
      color: #6B7280;
      margin-top: 4px;
      text-transform: uppercase;
      letter-spacing: 1px;
    }
    .summary-meta { text-align: right; }
    .summary-meta p { font-size: 13px; color: #6B7280; margin-bottom: 4px; }
    .summary-meta strong { color: #1E1E2E; }

    /* Section headings */
    h2 {
      font-size: 14px;
      font-weight: 700;
      color: #374151;
      text-transform: uppercase;
      letter-spacing: 1.5px;
      margin: 32px 0 14px 0;
      padding-bottom: 8px;
      border-bottom: 1px solid #E5E7EB;
    }

    /* Cards */
    .card {
      background: #ffffff;
      border: 1px solid #E5E7EB;
      border-radius: 10px;
      padding: 18px 20px;
      margin: 10px 0;
    }

    .meta { color: #6B7280; font-size: 12px; margin-top: 6px; line-height: 1.6; }

    /* Badges */
    .badge {
      display: inline-block;
      padding: 3px 10px;
      border-radius: 4px;
      font-size: 10px;
      font-weight: 700;
      letter-spacing: 1px;
      text-transform: uppercase;
    }
    .high { background: #FEE2E2; color: #DC2626; }
    .medium { background: #FEF3C7; color: #D97706; }
    .low { background: #D1FAE5; color: #059669; }

    /* Progress bar */
    .bar-bg {
      background: #F3F4F6;
      border-radius: 4px;
      height: 8px;
      margin: 10px 0 6px 0;
      overflow: hidden;
    }
    .bar { height: 8px; border-radius: 4px; }

    /* BOM table */
    .bom-table { width: 100%; border-collapse: collapse; font-size: 13px; }
    .bom-table td { padding: 8px 4px; border-bottom: 1px solid #F3F4F6; }
    .bom-table td:first-child { color: #6B7280; }
    .bom-table td:last-child { text-align: right; font-weight: 500; color: #1E1E2E; }
    .bom-table tr:last-child td { border-bottom: none; }

    /* AI Report */
    .ai-report {
      white-space: pre-wrap;
      line-height: 1.9;
      color: #374151;
      font-size: 13px;
    }

    /* Footer */
    .footer {
      margin-top: 48px;
      padding-top: 20px;
      border-top: 1px solid #E5E7EB;
      color: #9CA3AF;
      font-size: 11px;
      text-align: center;
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
    .footer span { font-weight: 600; color: #6366F1; }

    @media print {
      body { background: white; }
      .page { box-shadow: none; }
    }
  </style>
</head>
<body>
<div class="page">

  <!-- Header -->
  <div class="header">
    <div class="header-left">
      <div class="logo">🔍</div>
      <div>
        <h1>FairLens AI Audit Report</h1>
        <div class="subtitle">Official AI Fairness &amp; Compliance Audit — Government Use</div>
      </div>
    </div>
    <div class="header-right">
      <div class="label">Generated</div>
      <div class="value">${result.analysisTime.toLocal().toString().substring(0, 16)}</div>
    </div>
  </div>

  <!-- Summary -->
  <div class="summary">
    <div class="score-block">
      <div class="score">${result.overallBiasScore.toInt()}<span style="font-size:24px;color:#9CA3AF;">/100</span></div>
      <div class="score-label">Overall Bias Score &nbsp;<span class="badge $badgeClass">$severityLabel</span></div>
    </div>
    <div class="summary-meta">
      <p><strong>${result.totalRows}</strong> records analyzed</p>
      <p><strong>${result.totalColumns}</strong> columns</p>
      <p>Dataset: <strong>${result.datasetType.name.toUpperCase()}</strong></p>
      <p>Grade: <strong>${result.fairnessGrade}</strong></p>
    </div>
  </div>

  <!-- Detected Biases -->
  <h2>Detected Biases</h2>
  $biasCardsHtml

  <!-- AI-BOM -->
  <h2>Model Bill of Materials (AI-BOM)</h2>
  <div class="card">
    <table class="bom-table">
      <tr><td>Model Version</td><td>Gemini 2.5 Flash</td></tr>
      <tr><td>Fairness Engine</td><td>FairLens Auditor v2.0 (Industry Standard Math)</td></tr>
      <tr><td>Training Baseline</td><td>Synthetic + Human Feedback (RLHF)</td></tr>
      <tr><td>Governance Compliance</td><td>EU AI Act Annex III / India AI Guidelines 2026</td></tr>
      <tr><td>Traceability ID</td><td>FL-AUDIT-${DateTime.now().millisecondsSinceEpoch}</td></tr>
    </table>
  </div>

  <!-- Gemini Analysis -->
  <h2>Gemini AI Analysis</h2>
  <div class="card">
    <p class="ai-report">$aiReport</p>
  </div>

  <!-- Footer -->
  <div class="footer">
    <div>Generated by <span>FairLens</span> • Google Solution Challenge 2026</div>
    <div>${DateTime.now().toLocal().toString().substring(0, 19)}</div>
  </div>

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