/// FairLens - Complete Bias Detection Engine
/// Supports: AnalysisReport, BiasSeverity, AutoFixResult, static methods
library;

enum BiasSeverity { low, medium, high, critical }

enum DatasetType { hiring, loan, medical, education, general }

class BiasMetrics {
  final double disparateImpactRatio;
  final double statisticalParityDifference;
  final double equalOpportunityDifference;

  BiasMetrics({
    required this.disparateImpactRatio,
    required this.statisticalParityDifference,
    required this.equalOpportunityDifference,
  });
}

class BiasResult {
  final String columnName;
  final double biasScore; // 0–1
  final String biasType;
  final Map<String, double> groupDistribution;
  final BiasSeverity severity;
  final String explanation;
  final Map<String, double> groupRatesSafe;
  final String affectedGroupSafe;
  final String lawViolatedSafe;
  final String legalRisk;
  final BiasMetrics metricsSafe;

  BiasResult({
    required this.columnName,
    required this.biasScore,
    required this.biasType,
    required this.groupDistribution,
    required this.severity,
    required this.explanation,
    required this.groupRatesSafe,
    required this.affectedGroupSafe,
    required this.lawViolatedSafe,
    required this.legalRisk,
    required this.metricsSafe,
  });

  // Convenience getters so screens can use either name
  String get column => columnName;
  double get score => biasScore * 100; // 0–100 scale
  Map<String, double> get groupRates => groupRatesSafe;
  String get affectedGroup => affectedGroupSafe;
  String get lawViolated => lawViolatedSafe;
  BiasMetrics get metrics => metricsSafe;

  Map<String, dynamic> toMap() => {
    'columnName': columnName,
    'biasScore': biasScore,
    'biasType': biasType,
    'groupDistribution': groupDistribution,
    'severity': severity.name,
    'explanation': explanation,
    'affectedGroup': affectedGroupSafe,
    'lawViolated': lawViolatedSafe,
    'legalRisk': legalRisk,
  };
}

class AutoFixResult {
  final List<Map<String, String>> fixedData;
  final List<String> removedColumns;
  final List<String> anonymizedColumns;
  final double newBiasScore;
  final double improvement;

  AutoFixResult({
    required this.fixedData,
    required this.removedColumns,
    required this.anonymizedColumns,
    required this.newBiasScore,
    required this.improvement,
  });

  // Convenience getters used by analysis_screen.dart
  double get beforeScore => newBiasScore + improvement;
  double get afterScore => newBiasScore;
  double get improvementPercent =>
      beforeScore > 0 ? (improvement / beforeScore) * 100 : 0;
}

class AnalysisReport {
  final String datasetName;
  final int totalRows;
  final int totalColumns;
  final double overallBiasScore; // 0–100
  final BiasSeverity overallSeverity;
  final String fairnessGrade; // A, B, C, D, F
  final List<BiasResult> biasResults;
  final Map<String, double> featureImportanceMap;
  final DatasetType datasetType;
  final DateTime analyzedAt;
  final List<Map<String, String>> rawData;
  final List<String> headers;
  final List<String> recommendations;

  AnalysisReport({
    required this.datasetName,
    required this.totalRows,
    required this.totalColumns,
    required this.overallBiasScore,
    required this.overallSeverity,
    required this.fairnessGrade,
    required this.biasResults,
    required this.featureImportanceMap,
    required this.datasetType,
    required this.analyzedAt,
    required this.rawData,
    required this.headers,
    required this.recommendations,
  });

  // Alias used in pdf_service.dart
  DateTime get analysisTime => analyzedAt;

  // NEW HIGH-IMPACT UPGRADE GETTERS
  int get realWorldImpact => (overallBiasScore / 100 * totalRows * 12).toInt(); // Annualized estimate
  
  String get impactStatement {
    final count = realWorldImpact;
    if (datasetType == DatasetType.hiring) {
      return 'This model would unfairly reject ~$count qualified candidates per year.';
    } else if (datasetType == DatasetType.loan) {
      return 'This model would unfairly deny ~$count critical loan applications per year.';
    } else if (datasetType == DatasetType.medical) {
      return 'This model would misallocate healthcare resources to ~$count patients per year.';
    }
    return 'This model would unfairly impact ~$count people per year.';
  }

  String get deploymentSafety {
    if (overallBiasScore < 30) return 'SAFE';
    if (overallBiasScore < 60) return 'RISKY';
    return 'NOT DEPLOYABLE';
  }

  bool get isCertified => overallBiasScore <= 20;

  Map<String, String> get complianceStatus {
    final base = {
      'GDPR Article 22': overallBiasScore < 40 ? '✅ Compliant' : '❌ Violated',
      'EU AI Act': overallBiasScore < 30 ? '✅ Low Risk' : (overallBiasScore < 60 ? '⚠️ Medium Risk' : '❌ High Risk'),
    };
    if (datasetType == DatasetType.hiring) {
      base['Indian Equal Remuneration'] = overallBiasScore < 45 ? '✅ Compliant' : '⚠️ Risk';
      base['EEOC Guidelines (US)'] = overallBiasScore < 35 ? '✅ Compliant' : '❌ Violated';
    } else if (datasetType == DatasetType.loan) {
      base['Equal Credit Opp. Act'] = overallBiasScore < 35 ? '✅ Compliant' : '❌ Violated';
      base['RBI Fair Practices'] = overallBiasScore < 50 ? '✅ Compliant' : '⚠️ Risk';
    } else if (datasetType == DatasetType.medical) {
      base['HIPAA / NDHM Guidelines'] = overallBiasScore < 30 ? '✅ Compliant' : '❌ High Risk';
    } else {
      base['Indian Constitution Art 14'] = overallBiasScore < 50 ? '✅ Compliant' : '⚠️ Risk';
    }
    return base;
  }

  int get transparencyScore => (10 - (overallBiasScore / 20)).toInt().clamp(1, 10);
  int get fairnessScore => (10 - (overallBiasScore / 10)).toInt().clamp(1, 10);


  Map<String, dynamic> toMap() => {
    'datasetName': datasetName,
    'totalRows': totalRows,
    'totalColumns': totalColumns,
    'overallBiasScore': overallBiasScore,
    'overallSeverity': overallSeverity.name,
    'fairnessGrade': fairnessGrade,
    'datasetType': datasetType.name,
    'analyzedAt': analyzedAt.toIso8601String(),
    'biasResults': biasResults.map((b) => b.toMap()).toList(),
    'featureImportanceMap': featureImportanceMap,
    'recommendations': recommendations,
  };
}

// Keep AnalysisResult as alias for backward compatibility
typedef AnalysisResult = AnalysisReport;

class BiasDetector {
  static const List<String> _sensitiveKeywords = [
    'gender', 'sex', 'age', 'race', 'ethnicity', 'religion',
    'nationality', 'caste', 'disability', 'marital', 'income',
    'zip', 'pincode', 'region', 'state', 'location', 'education',
    'community', 'tribe', 'colour', 'color', 'skin',
  ];

  static const List<String> _outcomeKeywords = [
    'hired', 'approved', 'accepted', 'selected', 'promoted',
    'loan', 'result', 'outcome', 'decision', 'status', 'label',
    'target', 'class', 'y', 'output',
  ];

  static bool isSensitiveColumn(String col) {
    final lower = col.toLowerCase();
    return _sensitiveKeywords.any((k) => lower.contains(k));
  }

  /// Simulate bias score if a column is removed
  static double simulateWithoutColumn(
      List<Map<String, String>> data, List<String> headers, String removeCol) {
    final filteredData = data.map((row) {
      final m = Map<String, String>.from(row);
      m.remove(removeCol);
      return m;
    }).toList();
    final newHeaders = headers.where((h) => h != removeCol).toList();
    final result = BiasDetector.analyze(
      filteredData.map((r) => r.map((k, v) => MapEntry(k, v as dynamic))).toList(),
      newHeaders,
    );
    return result.overallBiasScore;
  }

  /// Main static analysis entry point
  static AnalysisReport analyze(
      List<Map<String, dynamic>> data, List<String> headers) {
    final strData = data
        .map((row) => row.map((k, v) => MapEntry(k, v.toString())))
        .toList();
    final name = headers.isNotEmpty ? headers.first : 'dataset';
    return BiasDetector()._run(name, strData);
  }

  /// Auto fix biased data
  static AutoFixResult autoFix(
      List<Map<String, String>> data,
      List<String> headers,
      AnalysisReport report,
      String method) {
    final highBias = report.biasResults
        .where((b) =>
            b.severity == BiasSeverity.high ||
            b.severity == BiasSeverity.critical)
        .map((b) => b.columnName)
        .toSet();

    List<Map<String, String>> fixedData;
    List<String> removed = [];
    List<String> anonymized = [];

    if (method == 'remove') {
      fixedData = data.map((row) {
        final m = Map<String, String>.from(row);
        for (final col in highBias) {
          m.remove(col);
          removed.add(col);
        }
        return m;
      }).toList();
    } else {
      fixedData = data.map((row) {
        final m = Map<String, String>.from(row);
        for (final col in highBias) {
          if (m.containsKey(col)) {
            m[col] = _anonymize(col, m[col] ?? '');
            anonymized.add(col);
          }
        }
        return m;
      }).toList();
    }

    final remaining = report.biasResults
        .where((b) => !highBias.contains(b.columnName))
        .toList();
    final newScore = remaining.isEmpty
        ? 0.0
        : remaining.map((b) => b.biasScore * 100).reduce((a, b) => a + b) /
            remaining.length;
    final improvement = report.overallBiasScore - newScore;

    return AutoFixResult(
      fixedData: fixedData,
      removedColumns: removed.toSet().toList(),
      anonymizedColumns: anonymized.toSet().toList(),
      newBiasScore: newScore,
      improvement: improvement,
    );
  }

  static String _anonymize(String col, String value) {
    final lower = col.toLowerCase();
    if (lower.contains('age')) {
      final age = int.tryParse(value);
      if (age != null) {
        if (age < 25) return '18-24';
        if (age < 35) return '25-34';
        if (age < 45) return '35-44';
        if (age < 55) return '45-54';
        return '55+';
      }
    }
    if (lower.contains('gender') || lower.contains('sex')) return 'undisclosed';
    if (lower.contains('zip') || lower.contains('pin')) {
      return value.length > 2 ? '${value.substring(0, 2)}***' : 'XXXX';
    }
    return 'REDACTED';
  }

  AnalysisReport _run(String datasetName, List<Map<String, String>> data) {
    if (data.isEmpty) throw Exception('Dataset is empty');

    final columns = data.first.keys.toList();
    final sensitiveColumns = columns.where(isSensitiveColumn).toList();
    final outcomeColumn = _detectOutcomeColumn(columns);
    final datasetType = _detectDatasetType(columns);

    final biasResults = <BiasResult>[];
    for (final col in sensitiveColumns) {
      final result = _analyzeColumn(data, col, outcomeColumn);
      if (result != null) biasResults.add(result);
    }
    biasResults.sort((a, b) => b.biasScore.compareTo(a.biasScore));

    final rawScore = biasResults.isEmpty
        ? 0.0
        : biasResults.map((r) => r.biasScore).reduce((a, b) => a + b) /
            biasResults.length;
    final overallScore = rawScore * 100;

    final severity = overallScore >= 75
        ? BiasSeverity.critical
        : overallScore >= 50
            ? BiasSeverity.high
            : overallScore >= 25
                ? BiasSeverity.medium
                : BiasSeverity.low;

    final grade = overallScore < 20
        ? 'A'
        : overallScore < 40
            ? 'B'
            : overallScore < 60
                ? 'C'
                : overallScore < 80
                    ? 'D'
                    : 'F';

    final Map<String, double> importance = {};
    for (final b in biasResults) {
      importance[b.columnName] = b.biasScore;
    }

    final recommendations = _buildRecommendations(biasResults, datasetType);

    return AnalysisReport(
      datasetName: datasetName,
      totalRows: data.length,
      totalColumns: columns.length,
      overallBiasScore: overallScore,
      overallSeverity: severity,
      fairnessGrade: grade,
      biasResults: biasResults,
      featureImportanceMap: importance,
      datasetType: datasetType,
      analyzedAt: DateTime.now(),
      rawData: data,
      headers: columns,
      recommendations: recommendations,
    );
  }

  List<String> _buildRecommendations(
      List<BiasResult> results, DatasetType type) {
    final recs = <String>[];
    for (final r in results.take(3)) {
      if (r.severity == BiasSeverity.critical ||
          r.severity == BiasSeverity.high) {
        recs.add(
            'Remove or anonymize "${r.columnName}" column to reduce ${r.biasType.toLowerCase()}');
      } else {
        recs.add(
            'Monitor "${r.columnName}" column and apply fairness-aware sampling');
      }
    }
    if (recs.isEmpty) {
      recs.add('Continue monitoring all sensitive columns quarterly');
    }
    recs.add('Implement fairness-aware ML training techniques (re-weighting, adversarial debiasing)');
    recs.add('Schedule quarterly FairLens audits to track improvement over time');
    return recs;
  }

  String? _detectOutcomeColumn(List<String> columns) {
    for (final col in columns) {
      final lower = col.toLowerCase();
      if (_outcomeKeywords.any((k) => lower.contains(k))) return col;
    }
    return null;
  }

  DatasetType _detectDatasetType(List<String> columns) {
    final joined = columns.join(' ').toLowerCase();
    if (joined.contains('salary') ||
        joined.contains('hire') ||
        joined.contains('interview')) {
      return DatasetType.hiring;
    }
    if (joined.contains('loan') ||
        joined.contains('credit') ||
        joined.contains('bank')) {
      return DatasetType.loan;
    }
    if (joined.contains('diagnosis') ||
        joined.contains('patient') ||
        joined.contains('medical')) {
      return DatasetType.medical;
    }
    if (joined.contains('grade') ||
        joined.contains('student') ||
        joined.contains('school')) {
      return DatasetType.education;
    }
    return DatasetType.general;
  }

  BiasResult? _analyzeColumn(
      List<Map<String, String>> data, String column, String? outcomeCol) {
    final Map<String, int> valueCounts = {};
    final Map<String, int> positiveOutcomes = {};

    for (final row in data) {
      final val = row[column]?.trim() ?? 'Unknown';
      valueCounts[val] = (valueCounts[val] ?? 0) + 1;
      if (outcomeCol != null) {
        final outcome = row[outcomeCol]?.trim().toLowerCase() ?? '';
        final isPositive = outcome == '1' ||
            outcome == 'yes' ||
            outcome == 'true' ||
            outcome == 'hired' ||
            outcome == 'approved' ||
            outcome == 'accepted';
        if (isPositive) {
          positiveOutcomes[val] = (positiveOutcomes[val] ?? 0) + 1;
        }
      }
    }

    if (valueCounts.length < 2) return null;

    final total = data.length;
    final Map<String, double> distribution = {};
    for (final entry in valueCounts.entries) {
      distribution[entry.key] = entry.value / total;
    }

    // Outcome rates per group
    final Map<String, double> groupRates = {};
    for (final entry in valueCounts.entries) {
      final pos = positiveOutcomes[entry.key] ?? 0;
      groupRates[entry.key] =
          outcomeCol != null ? pos / entry.value : distribution[entry.key]!;
    }

    double biasScore = 0.0;
    double disparateImpact = 1.0;
    double statParity = 0.0;
    double equalOpp = 0.0;

    if (outcomeCol != null && positiveOutcomes.isNotEmpty) {
      final maxRate =
          groupRates.values.reduce((a, b) => a > b ? a : b);
      final minRate =
          groupRates.values.reduce((a, b) => a < b ? a : b);
      disparateImpact = maxRate > 0 ? minRate / maxRate : 1.0;
      statParity = maxRate - minRate;
      equalOpp = statParity; // simplified
      biasScore = (1.0 - disparateImpact).clamp(0.0, 1.0);
    } else {
      final values = distribution.values.toList();
      final maxShare = values.reduce((a, b) => a > b ? a : b);
      final minShare = values.reduce((a, b) => a < b ? a : b);
      disparateImpact = maxShare > 0 ? minShare / maxShare : 1.0;
      statParity = maxShare - minShare;
      biasScore = statParity.clamp(0.0, 1.0);
    }

    final severity = biasScore >= 0.75
        ? BiasSeverity.critical
        : biasScore >= 0.5
            ? BiasSeverity.high
            : biasScore >= 0.25
                ? BiasSeverity.medium
                : BiasSeverity.low;

    // Most affected group = lowest outcome rate
    final affectedGroup = groupRates.entries
        .reduce((a, b) => a.value < b.value ? a : b)
        .key;

    final lawViolated = _getLawViolated(column, severity);
    final legalRisk = _getLegalRisk(severity);

    return BiasResult(
      columnName: column,
      biasScore: biasScore,
      biasType: _getBiasType(column),
      groupDistribution: distribution,
      severity: severity,
      explanation:
          '${_getBiasType(column)} detected in "$column". Score: ${(biasScore * 100).toStringAsFixed(1)}%.',
      groupRatesSafe: groupRates,
      affectedGroupSafe: affectedGroup,
      lawViolatedSafe: lawViolated,
      legalRisk: legalRisk,
      metricsSafe: BiasMetrics(
        disparateImpactRatio: disparateImpact,
        statisticalParityDifference: statParity,
        equalOpportunityDifference: equalOpp,
      ),
    );
  }

  String _getBiasType(String column) {
    final lower = column.toLowerCase();
    if (lower.contains('gender') || lower.contains('sex')) return 'Gender Bias';
    if (lower.contains('age')) return 'Age Bias';
    if (lower.contains('race') || lower.contains('ethnic')) return 'Racial Bias';
    if (lower.contains('caste') || lower.contains('community')) return 'Caste Bias';
    if (lower.contains('religion')) return 'Religious Bias';
    if (lower.contains('zip') ||
        lower.contains('region') ||
        lower.contains('state') ||
        lower.contains('location')) {
      return 'Geographic Bias';
    }
    if (lower.contains('education') || lower.contains('school')) {
      return 'Education Bias';
    }
    return 'Demographic Bias';
  }

  String _getLawViolated(String column, BiasSeverity severity) {
    if (severity == BiasSeverity.low) return 'No violation detected';
    final lower = column.toLowerCase();
    if (lower.contains('gender') || lower.contains('sex')) {
      return 'Equal Remuneration Act 1976 / GDPR Art.9';
    }
    if (lower.contains('age')) return 'Age Discrimination Act / GDPR Art.9';
    if (lower.contains('caste') || lower.contains('community')) {
      return 'SC/ST Prevention of Atrocities Act / Art.15 Constitution';
    }
    if (lower.contains('religion')) {
      return 'Article 14-16 Indian Constitution / GDPR Art.9';
    }
    if (lower.contains('race') || lower.contains('ethnic')) {
      return 'ICERD / GDPR Article 9';
    }
    return 'Article 14 Indian Constitution / EU AI Act';
  }

  String _getLegalRisk(BiasSeverity severity) {
    switch (severity) {
      case BiasSeverity.critical:
        return 'CRITICAL: Immediate legal exposure. Regulatory action likely.';
      case BiasSeverity.high:
        return 'HIGH: Significant legal risk. Remediation required before deployment.';
      case BiasSeverity.medium:
        return 'MEDIUM: Monitor closely. Document mitigation steps.';
      case BiasSeverity.low:
        return 'LOW: Within acceptable range. Continue monitoring.';
    }
  }
}
