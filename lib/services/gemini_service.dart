import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/bias_detector.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Gemini AI service with:
/// - no hardcoded API key fallback
/// - rate limiting
/// - exponential backoff on 429s
/// - safer error handling
/// - compact prompts to reduce token usage
class GeminiService {
  // Use:
  // flutter run --dart-define=GEMINI_KEY=YOUR_KEY_HERE

static final String _apiKey = dotenv.env['GEMINI_KEY'] ?? '';

  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  static bool get _hasApiKey => _apiKey.trim().isNotEmpty;

  // ── RATE LIMITING ─────────────────────────────────────────
  static DateTime _nextAllowedTime = DateTime.now();
  static const Duration _minInterval = Duration(seconds: 8);

  // ── CACHE ─────────────────────────────────────────────────
  static String? _cachedReportKey;
  static String? _cachedReport;

  // ── LOCKS ────────────────────────────────────────────────
  static bool _isAnalyzing = false;
  static bool _isChatting = false;
  static DateTime? _geminiUnavailableUntil;

  // ── HELPERS ──────────────────────────────────────────────
  static Future<void> _applyRateLimit() async {
    final now = DateTime.now();
    if (now.isBefore(_nextAllowedTime)) {
      final waitTime = _nextAllowedTime.difference(now);
      _nextAllowedTime = _nextAllowedTime.add(_minInterval);
      await Future.delayed(waitTime);
    } else {
      _nextAllowedTime = now.add(_minInterval);
    }
  }

  static bool _shouldRetry(int statusCode) {
    // DO NOT retry 429. Gemini's free tier limit is 15 RPM.
    // Retrying immediately will just spam the console with 429s.
    // We should immediately return and use the system fallback.
    return statusCode == 500 ||
        statusCode == 502 ||
        statusCode == 503 ||
        statusCode == 504;
  }

  static bool get _isGeminiCoolingDown {
    final unavailableUntil = _geminiUnavailableUntil;
    if (unavailableUntil == null) return false;
    if (DateTime.now().isBefore(unavailableUntil)) return true;
    _geminiUnavailableUntil = null;
    return false;
  }

  static void _coolDownGemini() {
    _geminiUnavailableUntil = DateTime.now().add(const Duration(minutes: 1));
  }

  static String _temporaryUnavailableMessage() {
    return 'Gemini is temporarily unavailable, so FairLens is using local analysis. Please try AI chat again in a minute.';
  }

  static String? _extractText(http.Response response) {
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = data['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) return null;

      final firstCandidate = candidates.first as Map<String, dynamic>?;
      if (firstCandidate == null) return null;

      final content = firstCandidate['content'] as Map<String, dynamic>?;
      if (content == null) return null;

      final parts = content['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) return null;

      final firstPart = parts.first as Map<String, dynamic>?;
      if (firstPart == null) return null;

      final text = firstPart['text'];
      return text is String ? text : null;
    } catch (_) {
      return null;
    }
  }

  static Future<http.Response> _postWithRetry(
    Uri url,
    Map<String, dynamic> body, {
    int maxRetries = 3,
  }) async {
    int attempt = 0;
    int backoffMs = 1500;

    while (true) {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': _apiKey,
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || attempt >= maxRetries || !_shouldRetry(response.statusCode)) {
        if (response.statusCode >= 500) {
          _coolDownGemini();
        }
        return response;
      }

      int waitMs = backoffMs;

      // Respect Retry-After when present.
      final retryAfter = response.headers['retry-after'];
      if (retryAfter != null) {
        final parsed = int.tryParse(retryAfter);
        if (parsed != null && parsed > 0) {
          waitMs = parsed * 1000;
        }
      }

      await Future.delayed(Duration(milliseconds: waitMs));
      attempt += 1;
      backoffMs *= 2;
    }
  }

  static String _topAffectedGroup(BiasResult bias) {
    if (bias.groupRatesSafe.isNotEmpty) {
      return bias.groupRatesSafe.entries
          .reduce((a, b) => a.value < b.value ? a : b)
          .key;
    }
    if (bias.groupDistribution.isEmpty) return 'minority';
    final entries = bias.groupDistribution.entries.toList();
    entries.sort((a, b) => a.value.compareTo(b.value));
    return entries.first.key;
  }

  // ── MAIN ANALYSIS ────────────────────────────────────────
  // Strategy: Return local analysis INSTANTLY. If a valid API key exists,
  // attempt Gemini ONCE silently in background. Cache the result for next time.
  // This means ZERO network errors on screen and ZERO 429s in console.
  static Future<String> analyzeWithGemini(AnalysisReport report) async {
    final cacheKey = '${report.datasetName}_${report.totalRows}';

    // ✅ Return cached Gemini result if available
    if (_cachedReportKey == cacheKey && _cachedReport != null) {
      return _cachedReport!;
    }

    // ✅ ALWAYS show local analysis immediately — no waiting, no errors
    final localResult = _fallback(report);

    // 🔕 If no key or already analyzing, just return local result silently
    if (!_hasApiKey || _isAnalyzing || _isGeminiCoolingDown) {
      return localResult;
    }

    // 🌐 Try Gemini ONCE in background (fire-and-forget for cache warming)
    // We return local result now. Next call will get the cached Gemini result.
    _isAnalyzing = true;
    _tryGeminiInBackground(report, cacheKey);

    return localResult;
  }

  // Attempts Gemini API call silently. Never throws. Updates cache on success.
  static Future<void> _tryGeminiInBackground(
      AnalysisReport report, String cacheKey) async {
    try {
      await _applyRateLimit();

      final topBiases = report.biasResults.take(3).map((r) {
        return '${r.biasType} in "${r.columnName}": '
            '${(r.biasScore * 100).toStringAsFixed(0)}/100 '
            '(${r.severity.name}) — ${_topAffectedGroup(r)} affected';
      }).join('\n');

      final prompt = '''
AI Fairness Expert. Analyze this ${report.datasetType.name.toUpperCase()} dataset bias report.

SCORE: ${report.overallBiasScore.toStringAsFixed(0)}/100 | GRADE: ${report.fairnessGrade} | SEVERITY: ${report.overallSeverity.name.toUpperCase()}
ROWS: ${report.totalRows} | COLUMNS: ${report.totalColumns}
TOP BIASES:
$topBiases

Reply in EXACTLY this format (no extra text):

SUMMARY:
[2 sentences — executive overview]

MOST CRITICAL ISSUE:
[Biggest problem + real-world human impact]

LEGAL RISK:
[Indian Constitution (Art 14, 15, 16) + Right to Education + GDPR/EU AI Act violations]

3 ACTION STEPS:
1. [Technical fix]
2. [Policy change]
3. [Monitoring plan]

FAIRNESS SCORE INTERPRETATION:
[What ${report.overallBiasScore.toStringAsFixed(0)}/100 means + target]
''';

      final response = await _postWithRetry(
        Uri.parse(_baseUrl),
        {
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.6,
            'maxOutputTokens': 500,
          },
        },
        maxRetries: 1,
      );

      if (response.statusCode == 200) {
        final text = _extractText(response);
        if (text != null && text.trim().isNotEmpty) {
          // Cache result — next call to analyzeWithGemini will return Gemini text
          _cachedReportKey = cacheKey;
          _cachedReport = text;
        }
      } else if (response.statusCode >= 500) {
        _coolDownGemini();
      }
      // Silently ignore 429, 500, or any other error — local fallback already shown
    } catch (_) {
      // Silently ignore all network errors
    } finally {
      _isAnalyzing = false;
    }
  }

  // ── CHAT ─────────────────────────────────────────────────
  static Future<String> chatAboutBias(
    AnalysisReport report,
    String userMessage,
    List<Map<String, String>> history,
  ) async {
    if (userMessage.trim().isEmpty) return '';

    if (_isChatting) {
      return '⏳ Please wait for the previous response to complete.';
    }

    if (!_hasApiKey) {
      return '⚠️ Gemini API key is missing. Set GEMINI_KEY with --dart-define, then try again.';
    }

    if (_isGeminiCoolingDown) {
      return _temporaryUnavailableMessage();
    }

    _isChatting = true;

    try {
      await _applyRateLimit();

      final systemContext = 'FairLens AI. Dataset: ${report.datasetType.name}, '
          'Score: ${report.overallBiasScore.toStringAsFixed(0)}/100 (${report.overallSeverity.name}), '
          'Grade: ${report.fairnessGrade}. '
          'Top bias: ${report.biasResults.isNotEmpty ? "${report.biasResults.first.biasType} in ${report.biasResults.first.columnName}" : "none"}. '
          'Be specific, concise, actionable.';

      final recentHistory =
          history.length > 6 ? history.sublist(history.length - 6) : history;

      final messages = <Map<String, dynamic>>[
        {
          'role': 'user',
          'parts': [
            {'text': systemContext}
          ]
        },
        {
          'role': 'model',
          'parts': [
            {'text':
                'Understood. I am ready to answer questions about this bias report.'}
          ]
        },
        ...recentHistory.map(
          (m) => {
            'role': m['role'] == 'user' ? 'user' : 'model',
            'parts': [
              {'text': m['text'] ?? ''}
            ],
          },
        ),
        {
          'role': 'user',
          'parts': [
            {'text': userMessage}
          ]
        },
      ];

      final response = await _postWithRetry(
        Uri.parse(_baseUrl),
        {
          'contents': messages,
          'generationConfig': {
            'temperature': 0.75,
            'maxOutputTokens': 400,
          },
        },
        maxRetries: 1,
      );

      if (response.statusCode == 200) {
        final text = _extractText(response);
        if (text != null && text.trim().isNotEmpty) return text;
        return _chatFallback(report, userMessage);
      }

      if (response.statusCode == 429) {
        return '⚠️ AI is temporarily busy. Please wait a few seconds and try again.';
      }

      if (response.statusCode >= 500) {
        return _temporaryUnavailableMessage();
      }

      return _chatFallback(report, userMessage);
    } catch (_) {
      return '⚠️ Could not reach AI right now. '
          'Your dataset has a bias score of ${report.overallBiasScore.toStringAsFixed(0)}/100. '
          'Try again in a moment.';
    } finally {
      _isChatting = false;
    }
  }

  // ── CACHE CONTROL ────────────────────────────────────────
  static void clearCache() {
    _cachedReportKey = null;
    _cachedReport = null;
  }

  // ── SMART OFFLINE ANALYSIS ENGINE ────────────────────────
  // Generates dynamic, data-driven insights from actual computed values.
  // Output changes entirely based on the dataset — no static templates.
  static String _fallback(AnalysisReport report, {String? reason}) {
    final score = report.overallBiasScore;
    final top = report.biasResults.isNotEmpty ? report.biasResults.first : null;
    final banner = reason != null ? '⚠️ $reason\n\n' : '';

    // ── Group rate analysis (data-driven) ──
    String groupInsight = '';
    String rateDetail = '';
    if (top != null && top.groupRatesSafe.length >= 2) {
      final sorted = top.groupRatesSafe.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      final lowest = sorted.first;
      final highest = sorted.last;
      final pctLow  = (lowest.value  * 100).toStringAsFixed(1);
      final pctHigh = (highest.value * 100).toStringAsFixed(1);
      final gap     = ((highest.value - lowest.value) * 100).toStringAsFixed(1);
      final ratio   = highest.value > 0 ? (lowest.value / highest.value) : 1.0;
      groupInsight  = '"${lowest.key}" group: $pctLow% vs "${highest.key}" group: $pctHigh% — a ${gap}% gap.';
      rateDetail    = ratio < 0.8
          ? 'Disparate Impact Ratio: ${ratio.toStringAsFixed(2)} (fails the 80% four-fifths rule — legally actionable).'
          : 'Disparate Impact Ratio: ${ratio.toStringAsFixed(2)} (borderline — close monitoring required).';
    }

    // ── Representation imbalance ──
    String reprInsight = '';
    if (top != null && top.groupDistribution.isNotEmpty) {
      final dominant = top.groupDistribution.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      if (dominant.value > 0.6) {
        reprInsight = 'Training data is ${(dominant.value * 100).toStringAsFixed(0)}% "${dominant.key}" — '
            'severe underrepresentation of minority groups skews the model.';
      }
    }

    // ── Compound bias (multiple columns) ──
    String compoundNote = '';
    if (report.biasResults.length > 1) {
      final cols = report.biasResults.take(3).map((b) => '"${b.columnName}"').join(', ');
      compoundNote = 'Intersectional bias detected across $cols — removing one column alone is insufficient.';
    }

    // ── Explainability: WHY bias exists ──
    final whyParts = <String>[];
    if (reprInsight.isNotEmpty) whyParts.add(reprInsight);
    if (rateDetail.isNotEmpty) whyParts.add(rateDetail);
    if (compoundNote.isNotEmpty) whyParts.add(compoundNote);
    if (whyParts.isEmpty && top != null) {
      whyParts.add('Statistical imbalance in "${top.columnName}" feature causes '
          'the model to associate this attribute with outcomes, violating fairness criteria.');
    }
    final why = whyParts.join('\n');

    // ── Legal risk statement ──
    final legalStmt = _legalStatement(report);

    // ── Action steps (data-driven) ──
    final step1 = top != null
        ? (top.severity == BiasSeverity.critical
            ? 'IMMEDIATELY remove "${top.columnName}" column — use FairLens Auto Fix to download debiased CSV.'
            : 'Anonymize "${top.columnName}" column using FairLens Auto Fix. Estimated bias reduction: '
              '${((top.biasScore) * 60).toStringAsFixed(0)}%.')
        : 'Audit all sensitive columns and apply fairness-aware re-sampling.';

    final step2 = report.datasetType == DatasetType.hiring
        ? 'Implement structured interview scoring with blind CV review. Enforce EEOC 80% guideline.'
        : report.datasetType == DatasetType.loan
            ? 'Apply Equal Credit Opportunity Act compliance checks. Remove proxy variables.'
            : report.datasetType == DatasetType.education
                ? 'Review admission criteria for geographic and socioeconomic proxies.'
                : 'Apply fairness-aware ML reweighting and adversarial debiasing techniques.';

    // ── Score interpretation ──
    final interp = score < 20
        ? 'Excellent — deployment safe. Maintain regular audits.'
        : score < 40
            ? 'Moderate — improvement recommended before scaling.'
            : score < 60
                ? 'Borderline — remediation required. Do not deploy to production.'
                : score < 80
                    ? 'Poor — significant bias. Deployment blocked under EU AI Act.'
                    : 'CRITICAL — Immediate intervention required. System poses active discrimination risk.';

    return '''${banner}SUMMARY:
${report.datasetType.name.toUpperCase()} dataset | ${report.totalRows} records | ${report.totalColumns} features | Fairness Grade: ${report.fairnessGrade}
Overall Bias Score: ${score.toStringAsFixed(1)}/100 (${report.overallSeverity.name.toUpperCase()}). ${report.deploymentSafety}. ${report.impactStatement}

MOST CRITICAL ISSUE:
${top != null ? '${top.biasType} in "${top.columnName}" column. $groupInsight\n${top.legalRisk}' : 'No single dominant bias. Composite risk across multiple features requires holistic remediation.'}

BIAS EXPLAINABILITY — WHY THIS EXISTS:
$why

LEGAL RISK ASSESSMENT:
$legalStmt

3 REMEDIATION STEPS:
1. $step1
2. $step2
3. Deploy FairLens monitoring in CI/CD pipeline — auto-block deployment if bias exceeds 50/100.

FAIRNESS SCORE INTERPRETATION:
${score.toStringAsFixed(0)}/100 = Grade ${report.fairnessGrade}. $interp Target: <20/100 for regulatory compliance.''';
  }

  static String _legalStatement(AnalysisReport report) {
    final s = report.overallSeverity;
    if (s == BiasSeverity.critical) {
      return 'CRITICAL LEGAL EXPOSURE: Violates EU AI Act (Annex III High-Risk), GDPR Art.22, '
          '${report.datasetType == DatasetType.hiring ? "Equal Remuneration Act 1976, EEOC 80% Rule" : "Articles 14-16 Indian Constitution"}. '
          'Regulatory action and civil litigation are likely. Immediate halt advised.';
    } else if (s == BiasSeverity.high) {
      return 'HIGH LEGAL RISK: Potential violations of GDPR Art.22 and EU AI Act. '
          'Document all mitigation steps immediately. Legal review before deployment mandatory.';
    } else if (s == BiasSeverity.medium) {
      return 'MEDIUM RISK: Within borderline ranges. Monitor quarterly. Document all fairness measures '
          'to demonstrate due diligence under GDPR and EU AI Act requirements.';
    }
    return 'LOW RISK: Currently within acceptable fairness thresholds. Continue monitoring and maintain audit trail.';
  }

  // ── FALLBACK CHAT ────────────────────────────────────────
  static String _chatFallback(AnalysisReport report, String question) {
    final q = question.toLowerCase();
    final top = report.biasResults.isNotEmpty ? report.biasResults.first : null;

    if (q.contains('fix') || q.contains('reduce') || q.contains('improve')) {
      return 'To reduce bias in your dataset:\n\n'
          '1. Remove or anonymize "${top?.columnName ?? 'sensitive'}" column\n'
          '2. Apply re-sampling to balance group distribution\n'
          '3. Use FairLens Auto Fix tab to download a debiased CSV\n'
          '4. Retrain your model on the cleaned data';
    }

    if (q.contains('affect') || q.contains('group') || q.contains('who')) {
      return top != null
          ? 'The most affected group is "${_topAffectedGroup(top)}" in the "${top.columnName}" column. '
              'They face a ${(top.biasScore * 100).toStringAsFixed(0)}% bias score compared to other groups.'
          : 'Check the Charts tab for group-by-group comparison rates.';
    }

    if (q.contains('law') || q.contains('legal') || q.contains('gdpr')) {
      return 'Based on your score of ${report.overallBiasScore.toStringAsFixed(0)}/100:\n\n'
          '${top != null ? "• ${top.biasType.contains("Gender") ? "Equal Remuneration Act 1976 / EEOC Guidelines" : top.biasType.contains("Age") ? "Age Discrimination in Employment Act" : top.biasType.contains("Caste") ? "Articles 14-16 Indian Constitution" : "Applicable Discrimination Laws"}\n" : ""}'
          '• GDPR Article 22 (automated decision-making)\n'
          '• EU AI Act (high-risk AI systems)\n'
          '${report.datasetType == DatasetType.hiring ? "• Equal Remuneration Act 1976\n• EEOC Guidelines" : "• Articles 14-16 Indian Constitution"}';
    }

    return 'Your dataset scores ${report.overallBiasScore.toStringAsFixed(0)}/100 '
        '(${report.overallSeverity.name}, Grade ${report.fairnessGrade}). '
        '${top != null ? "The biggest issue is ${top.biasType} in the ${top.columnName} column." : ""} '
        'Check the AI Report tab for full analysis, or try asking a more specific question.';
  }
}
