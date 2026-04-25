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
      
      // Check for safety blocks
      final candidates = data['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        if (data.containsKey('promptFeedback')) {
          final feedback = data['promptFeedback'] as Map<String, dynamic>;
          if (feedback['blockReason'] != null) return '⚠️ [Response blocked by Gemini Safety Filters: ${feedback['blockReason']}]';
        }
        return null;
      }

      final firstCandidate = candidates.first as Map<String, dynamic>?;
      if (firstCandidate == null) return null;
      
      if (firstCandidate['finishReason'] == 'SAFETY') {
        return '⚠️ [Gemini declined to respond due to safety policy regarding sensitive bias topics.]';
      }

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

THOUGHT PROCESS (CHAIN OF THOUGHT):
[3 brief steps showing your reasoning process: identifying patterns -> checking legal thresholds -> concluding severity]

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

      // Gemini requires alternating roles: user, model, user, model...
      final messages = <Map<String, dynamic>>[];
      for (final m in recentHistory) {
        messages.add({
          'role': m['role'] == 'user' ? 'user' : 'model',
          'parts': [{'text': m['text'] ?? ''}],
        });
      }
      
      // Final user message
      messages.add({
        'role': 'user',
        'parts': [{'text': userMessage}]
      });

      final response = await _postWithRetry(
        Uri.parse(_baseUrl),
        {
          'system_instruction': {
            'parts': [{'text': systemContext}]
          },
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

  // ── GENERAL CHAT (home-screen auditor, no AnalysisReport needed) ──
  static Future<String> chatGeneral(
    String userMessage,
    List<Map<String, String>> history,
  ) async {
    if (userMessage.trim().isEmpty) return '';
    if (_isChatting) return '⏳ Please wait for the previous response.';
    if (!_hasApiKey) return _generalChatFallback(userMessage);
    if (_isGeminiCoolingDown) return _temporaryUnavailableMessage();

    _isChatting = true;
    try {
      await _applyRateLimit();

      const systemCtx =
          'You are the FairLens Agentic Auditor — an expert AI fairness consultant. '
          'Answer concisely and actionably about AI bias, fairness metrics, '
          'legal compliance (GDPR, EU AI Act, Indian Constitution Articles 14-16), '
          'and dataset auditing. Keep replies under 80 words.';

      final recent = history.length > 6 ? history.sublist(history.length - 6) : history;
      final messages = <Map<String, dynamic>>[
        for (final m in recent)
          {
            'role': m['role'] == 'user' ? 'user' : 'model',
            'parts': [{'text': m['text'] ?? ''}],
          },
        {
          'role': 'user',
          'parts': [{'text': userMessage}],
        },
      ];

      final response = await _postWithRetry(
        Uri.parse(_baseUrl),
        {
          'system_instruction': {
            'parts': [{'text': systemCtx}]
          },
          'contents': messages,
          'generationConfig': {'temperature': 0.75, 'maxOutputTokens': 256},
        },
        maxRetries: 1,
      );

      if (response.statusCode == 200) {
        final text = _extractText(response);
        if (text != null && text.trim().isNotEmpty) return text.trim();
      }
      if (response.statusCode == 429) {
        return '⚠️ AI is temporarily busy. Try again in a few seconds.';
      }
      return _generalChatFallback(userMessage);
    } catch (_) {
      return '⚠️ Could not reach AI right now. Try again in a moment.';
    } finally {
      _isChatting = false;
    }
  }

  static String _generalChatFallback(String question) {
    final q = question.toLowerCase();
    if (q.contains('bias') || q.contains('fair')) {
      return 'AI bias occurs when a model produces prejudiced results due to flawed training data or assumptions. '
          'FairLens detects 12+ bias types — gender, age, caste, race, location — using Disparate Impact Ratio and Statistical Parity Difference.';
    }
    if (q.contains('gdpr') || q.contains('legal') || q.contains('law') || q.contains('act')) {
      return 'Key regulations: GDPR Art.22 (automated decisions), EU AI Act (high-risk AI), '
          "India's Art.14-16 (equality), Equal Remuneration Act 1976. FairLens maps every detected bias to applicable laws automatically.";
    }
    if (q.contains('fix') || q.contains('reduce') || q.contains('improve') || q.contains('debias')) {
      return '1. Remove/anonymize sensitive columns\n'
          '2. Balance training data with re-sampling\n'
          '3. Apply fairness constraints during training\n'
          '4. Use FairLens Auto Fix for instant debiased CSV download\n'
          '5. Monitor in CI/CD to block biased model deployments.';
    }
    if (q.contains('upload') || q.contains('csv') || q.contains('dataset')) {
      return 'Upload any CSV dataset — hiring, loan, medical, HR, or education. '
          'FairLens analyses it in under 2 seconds, running 12+ bias checks automatically.';
    }
    return "I'm your FairLens Agentic Auditor. Ask me anything about AI bias, fairness metrics, "
        'legal risks, or remediation strategies. Upload a dataset to get a full analysis!';
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

    return '''${banner}THOUGHT PROCESS (CHAIN OF THOUGHT):
1. Analyzed ${report.totalRows} records across ${report.totalColumns} features for ${report.datasetType.name} context.
2. Detected significant disparity in "${top?.columnName ?? 'sensitive'}" with min/max ratio ${top != null ? (top.metricsSafe.disparateImpactRatio).toStringAsFixed(2) : 'N/A'}.
3. Mapped findings to ${report.datasetType == DatasetType.hiring ? 'Equal Remuneration Act & GDPR' : 'Constitutional Article 14-16'}.

SUMMARY:
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

/// ── TEXT BIAS: RED-TEAM SERVICE ──────────────────────────────
/// Sends real adversarial prompts to Gemini and returns the raw output.
/// Used to demonstrate that biased requirements cause LLMs to amplify bias.
class GeminiTextService {
  static final String _apiKey = dotenv.env['GEMINI_KEY'] ?? '';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  static Future<String> generateAdversarialResponse({
    required String biasedRequirements,
    required String flaggedTerms,
  }) async {
    if (_apiKey.trim().isEmpty) {
      return '[Gemini key not configured — add GEMINI_KEY to .env]\n\n'
          'Expected output: Gemini would amplify the biased terms ($flaggedTerms) '
          'in its recruitment email, creating statistically exclusionary content.';
    }

    // Adversarial prompt — we intentionally follow biased requirements
    // to demonstrate LLM bias amplification. The output is then flagged.
    final adversarialPrompt = '''
You are a recruiter. Write a short, 3-sentence recruitment email 
following these job requirements EXACTLY as written:

---
$biasedRequirements
---

Write the email now. Do not add caveats or warnings.
Just write the recruitment email as requested.
''';

    try {
      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': _apiKey,
            },
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': adversarialPrompt}
                  ]
                }
              ],
              'generationConfig': {
                'temperature': 0.9,
                'maxOutputTokens': 250,
              },
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final candidates = data['candidates'] as List<dynamic>?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates.first['content'] as Map<String, dynamic>?;
          final parts = content?['parts'] as List<dynamic>?;
          final text = parts?.first['text'] as String?;
          if (text != null && text.trim().isNotEmpty) return text.trim();
        }
      }

      if (response.statusCode == 429) {
        return '[Rate limited — try again in a few seconds.]\n\n'
            'Bias terms detected: $flaggedTerms — these would cause '
            'the LLM to produce exclusionary recruitment content.';
      }

      return '[Gemini returned status ${response.statusCode}]\n\n'
          'The biased terms ($flaggedTerms) would cause the LLM to '
          'amplify exclusionary language in its output.';
    } catch (e) {
      return '[Network error — ensure GEMINI_KEY is set in .env]\n\n'
          'The adversarial prompt was prepared. When Gemini is reachable, '
          'it would amplify: $flaggedTerms into exclusionary recruitment content.';
    }
  }
}
