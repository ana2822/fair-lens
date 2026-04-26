import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/bias_detector.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> saveAnalysis(AnalysisReport result, String aiReport) async {
    try {
      final user = _auth.currentUser;
      await _db.collection('analyses').add({
        ...result.toMap(),
        'aiReport': aiReport,
        'userId': user?.uid ?? 'anonymous',
        'userEmail': user?.email ?? 'anonymous',
      });
    } catch (e) {
      // ignore: avoid_print
      debugPrint('Firebase save error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPastAnalyses() async {
    try {
      final user = _auth.currentUser;
      final snapshot = await _db
          .collection('analyses')
          .where('userId', isEqualTo: user?.uid ?? 'anonymous')
          .orderBy('analyzedAt', descending: true)
          .limit(20)
          .get();
      return snapshot.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    } catch (e) {
      debugPrint('Firebase fetch error: $e');
      return [];
    }
  }
}
