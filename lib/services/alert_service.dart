import 'package:flutter/material.dart';

enum AlertType { info, warning, critical }

class AppAlert {
  final String id;
  final String message;
  final AlertType type;
  final DateTime timestamp;

  AppAlert({required this.message, required this.type})
      : id = DateTime.now().microsecondsSinceEpoch.toString(),
        timestamp = DateTime.now();

  Color get color {
    switch (type) {
      case AlertType.critical: return const Color(0xFFEF4444);
      case AlertType.warning:  return const Color(0xFFF59E0B);
      case AlertType.info:     return const Color(0xFF3B82F6);
    }
  }

  String get icon {
    switch (type) {
      case AlertType.critical: return '🚨';
      case AlertType.warning:  return '⚠️';
      case AlertType.info:     return 'ℹ️';
    }
  }

  String get label {
    switch (type) {
      case AlertType.critical: return 'CRITICAL';
      case AlertType.warning:  return 'WARNING';
      case AlertType.info:     return 'INFO';
    }
  }
}

/// Singleton global alert service. Call AlertService().trigger() from anywhere.
class AlertService {
  static final AlertService _i = AlertService._();
  factory AlertService() => _i;
  AlertService._();

  final ValueNotifier<List<AppAlert>> active = ValueNotifier([]);
  final List<AppAlert> history = [];

  void trigger(String message, AlertType type) {
    final alert = AppAlert(message: message, type: type);
    history.insert(0, alert);
    active.value = [alert, ...active.value];
    // Auto-dismiss after 7 seconds
    Future.delayed(const Duration(seconds: 7), () => dismiss(alert.id));
  }

  void dismiss(String id) {
    active.value = active.value.where((a) => a.id != id).toList();
  }

  void dismissAll() => active.value = [];
}
