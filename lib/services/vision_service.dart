import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Result for a single face detected by Google Cloud Vision API.
class FaceAnnotation {
  final double detectionConfidence;
  final double landmarkingConfidence;
  final String joyLikelihood;
  final bool isBlurred;
  final bool hasHeadwear;

  FaceAnnotation({
    required this.detectionConfidence,
    required this.landmarkingConfidence,
    required this.joyLikelihood,
    required this.isBlurred,
    required this.hasHeadwear,
  });

  factory FaceAnnotation.fromJson(Map<String, dynamic> json) {
    return FaceAnnotation(
      detectionConfidence: (json['detectionConfidence'] as num?)?.toDouble() ?? 0.0,
      landmarkingConfidence: (json['landmarkingConfidence'] as num?)?.toDouble() ?? 0.0,
      joyLikelihood: json['joyLikelihood'] as String? ?? 'UNKNOWN',
      isBlurred: json['blurredLikelihood'] == 'LIKELY' || json['blurredLikelihood'] == 'VERY_LIKELY',
      hasHeadwear: json['headwearLikelihood'] == 'LIKELY' || json['headwearLikelihood'] == 'VERY_LIKELY',
    );
  }
}

/// Per-image result from Vision API.
class ImageAnalysisResult {
  final String filename;
  final bool faceDetected;
  final FaceAnnotation? face;
  final String? error;

  ImageAnalysisResult({
    required this.filename,
    required this.faceDetected,
    this.face,
    this.error,
  });
}

/// Computed bias statistics for a demographic group.
class GroupBiasStats {
  final String groupName;
  final int totalImages;
  final int detectedFaces;
  final double detectionRate;           // % of images where face was found
  final double avgDetectionConfidence;  // avg of detection confidence scores
  final double avgLandmarkConfidence;   // avg of landmark confidence scores

  GroupBiasStats({
    required this.groupName,
    required this.totalImages,
    required this.detectedFaces,
    required this.detectionRate,
    required this.avgDetectionConfidence,
    required this.avgLandmarkConfidence,
  });
}

/// Full audit result comparing two demographic groups.
class FaceAuditResult {
  final GroupBiasStats groupA;
  final GroupBiasStats groupB;

  /// Core metric: min(detection_rate) / max(detection_rate)
  /// < 0.8 → fails EEOC 80% four-fifths rule — legally flagged.
  final double disparateImpactRatio;

  /// Confidence gap: |avgConfidence_A - avgConfidence_B|
  final double confidenceGap;

  final String verdict;
  final String verdictDetail;

  FaceAuditResult({
    required this.groupA,
    required this.groupB,
    required this.disparateImpactRatio,
    required this.confidenceGap,
    required this.verdict,
    required this.verdictDetail,
  });
}

/// Google Cloud Vision API service for face bias detection.
///
/// Uses FACE_DETECTION feature to extract:
/// - detectionConfidence: how confidently a face was detected (0–1)
/// - landmarkingConfidence: accuracy of facial landmark mapping (0–1)
///
/// Bias is measured as disparity in these scores across demographic groups —
/// this is the same methodology used by academic face bias audits
/// (e.g., Gender Shades by Buolamwini & Gebru, 2018).
class VisionService {
  static final String _apiKey = dotenv.env['VISION_KEY'] ?? '';
  static const String _baseUrl =
      'https://vision.googleapis.com/v1/images:annotate';

  static bool get hasApiKey => _apiKey.trim().isNotEmpty;

  /// Analyze a single image with Google Vision FACE_DETECTION.
  static Future<ImageAnalysisResult> analyzeImage(
    Uint8List imageBytes,
    String filename,
  ) async {
    if (!hasApiKey) {
      return ImageAnalysisResult(
        filename: filename,
        faceDetected: false,
        error: 'VISION_KEY not set in .env',
      );
    }

    final base64Image = base64Encode(imageBytes);

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl?key=$_apiKey'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'requests': [
                {
                  'image': {'content': base64Image},
                  'features': [
                    {'type': 'FACE_DETECTION', 'maxResults': 1}
                  ],
                }
              ]
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        return ImageAnalysisResult(
          filename: filename,
          faceDetected: false,
          error: 'Vision API error ${response.statusCode}',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final responses = data['responses'] as List<dynamic>?;
      if (responses == null || responses.isEmpty) {
        return ImageAnalysisResult(filename: filename, faceDetected: false);
      }

      final firstResponse = responses.first as Map<String, dynamic>;

      // Check for API-level errors
      if (firstResponse.containsKey('error')) {
        final err = firstResponse['error'] as Map<String, dynamic>;
        return ImageAnalysisResult(
          filename: filename,
          faceDetected: false,
          error: err['message'] as String? ?? 'Unknown API error',
        );
      }

      final faceAnnotations = firstResponse['faceAnnotations'] as List<dynamic>?;
      if (faceAnnotations == null || faceAnnotations.isEmpty) {
        // No face detected — this counts as a detection failure for the group
        return ImageAnalysisResult(filename: filename, faceDetected: false);
      }

      final face = FaceAnnotation.fromJson(
          faceAnnotations.first as Map<String, dynamic>);
      return ImageAnalysisResult(
        filename: filename,
        faceDetected: true,
        face: face,
      );
    } catch (e) {
      return ImageAnalysisResult(
        filename: filename,
        faceDetected: false,
        error: 'Network error: $e',
      );
    }
  }

  /// Analyze multiple images for a group and return computed bias statistics.
  static Future<GroupBiasStats> analyzeGroup(
    List<({Uint8List bytes, String name})> images,
    String groupName,
    void Function(int done, int total) onProgress,
  ) async {
    final results = <ImageAnalysisResult>[];

    for (int i = 0; i < images.length; i++) {
      final result = await analyzeImage(images[i].bytes, images[i].name);
      results.add(result);
      onProgress(i + 1, images.length);
    }

    final detected = results.where((r) => r.faceDetected).toList();
    final detectionRate = results.isEmpty ? 0.0 : detected.length / results.length;

    final confidences = detected
        .where((r) => r.face != null)
        .map((r) => r.face!.detectionConfidence)
        .toList();
    final landmarks = detected
        .where((r) => r.face != null)
        .map((r) => r.face!.landmarkingConfidence)
        .toList();

    final avgConf = confidences.isEmpty
        ? 0.0
        : confidences.reduce((a, b) => a + b) / confidences.length;
    final avgLandmark = landmarks.isEmpty
        ? 0.0
        : landmarks.reduce((a, b) => a + b) / landmarks.length;

    return GroupBiasStats(
      groupName: groupName,
      totalImages: results.length,
      detectedFaces: detected.length,
      detectionRate: detectionRate,
      avgDetectionConfidence: avgConf,
      avgLandmarkConfidence: avgLandmark,
    );
  }

  /// Compare two groups and produce a complete FaceAuditResult.
  static FaceAuditResult computeAudit(GroupBiasStats a, GroupBiasStats b) {
    // Disparate Impact Ratio: min_rate / max_rate
    final minRate = a.detectionRate < b.detectionRate ? a.detectionRate : b.detectionRate;
    final maxRate = a.detectionRate > b.detectionRate ? a.detectionRate : b.detectionRate;
    final dir = maxRate > 0 ? minRate / maxRate : 1.0;

    // Confidence gap
    final gap = (a.avgDetectionConfidence - b.avgDetectionConfidence).abs();

    // Verdict
    String verdict;
    String verdictDetail;
    if (dir < 0.8) {
      verdict = 'BIASED';
      verdictDetail = 'Disparate Impact Ratio of ${dir.toStringAsFixed(2)} '
          'falls below the EEOC 80% four-fifths rule. '
          'This model detects faces in "${a.detectionRate >= b.detectionRate ? a.groupName : b.groupName}" '
          'significantly more reliably — a legally actionable disparity.';
    } else if (dir < 0.9) {
      verdict = 'BORDERLINE';
      verdictDetail = 'Disparate Impact Ratio of ${dir.toStringAsFixed(2)} '
          'passes the 80% rule but remains below 90%. '
          'Close monitoring and further testing across a larger sample is recommended.';
    } else {
      verdict = 'FAIR';
      verdictDetail = 'Disparate Impact Ratio of ${dir.toStringAsFixed(2)} '
          'is within acceptable fairness thresholds. '
          'Continue monitoring with larger and more diverse test sets.';
    }

    return FaceAuditResult(
      groupA: a,
      groupB: b,
      disparateImpactRatio: dir,
      confidenceGap: gap,
      verdict: verdict,
      verdictDetail: verdictDetail,
    );
  }
}
