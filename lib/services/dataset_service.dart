import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import '../models/bias_detector.dart';
import '../screens/analysis_screen.dart';

class DatasetService {
  static Future<void> pickAndAnalyze(BuildContext context, {required Function(bool) setLoading, required Function(String?) setError}) async {
    setLoading(true);
    setError(null);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result == null) {
        setLoading(false);
        return;
      }

      final file = result.files.first;
      final csvString = String.fromCharCodes(file.bytes!);
      final cleanedCsv = csvString.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

      final rows = const CsvToListConverter(
        fieldDelimiter: ',',
        eol: '\n',
      ).convert(cleanedCsv);

      final validRows = rows.where((r) => r.isNotEmpty).toList();

      if (validRows.length < 2) {
        throw Exception('CSV needs at least 2 valid rows');
      }

      final headers = validRows.first.map((e) => e.toString()).toList();

      final data = validRows.skip(1).map((row) {
        final map = <String, dynamic>{};
        for (int i = 0; i < headers.length; i++) {
          map[headers[i]] = i < row.length ? row[i].toString() : '';
        }
        return map;
      }).toList();

      final analysisResult = BiasDetector.analyze(data, headers);

      if (!context.mounted) return;

      if (analysisResult.overallBiasScore > 50) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '⚠️ High risk dataset detected!',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }

      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, a, b) => AnalysisScreen(
            result: analysisResult,
            rawData: data.map((e) => e.map((k, v) => MapEntry(k, v.toString()))).toList(),
          ),
          transitionsBuilder: (_, a, b, child) => FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }
}
