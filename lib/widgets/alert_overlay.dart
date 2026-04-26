import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/alert_service.dart';

/// Wrap your HomeScreen with this to get global floating alerts across the app.
class AlertOverlay extends StatefulWidget {
  final Widget child;
  const AlertOverlay({super.key, required this.child});

  @override
  State<AlertOverlay> createState() => _AlertOverlayState();
}

class _AlertOverlayState extends State<AlertOverlay> {
  bool _showHistory = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          widget.child,
  
          // ── Floating Alert Banners ─────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: ValueListenableBuilder<List<AppAlert>>(
                valueListenable: AlertService().active,
                builder: (_, alerts, __) {
                  if (alerts.isEmpty) return const SizedBox.shrink();
                  return Column(
                    children: alerts.take(3).map((a) => _AlertBanner(
                      key: ValueKey(a.id),
                      alert: a,
                      onDismiss: () => AlertService().dismiss(a.id),
                      onViewHistory: () => setState(() => _showHistory = true),
                    )).toList(),
                  );
                },
              ),
            ),
          ),
  
          // ── Alert History Panel ────────────────────────────────
          if (_showHistory)
            Positioned.fill(
              child: _AlertHistoryPanel(
                onClose: () => setState(() => _showHistory = false),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Individual Alert Banner ────────────────────────────────────
class _AlertBanner extends StatelessWidget {
  final AppAlert alert;
  final VoidCallback onDismiss;
  final VoidCallback onViewHistory;

  const _AlertBanner({
    super.key,
    required this.alert,
    required this.onDismiss,
    required this.onViewHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1A),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: alert.color, width: 4)),
        boxShadow: [
          BoxShadow(
            color: alert.color.withValues(alpha: 0.25),
            blurRadius: 24,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Text(alert.icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    _TypeBadge(alert: alert),
                    const SizedBox(width: 8),
                    Text(
                      _timeAgo(alert.timestamp),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ]),
                  const SizedBox(height: 3),
                  Text(
                    alert.message,
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: onDismiss,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.close,
                        color: Colors.white.withValues(alpha: 0.4), size: 16),
                  ),
                ),
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: onViewHistory,
                  child: Text(
                    'History',
                    style: TextStyle(color: alert.color, fontSize: 10),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    )
        .animate()
        .slideY(begin: -1.0, end: 0, duration: 400.ms, curve: Curves.easeOutCubic)
        .fadeIn(duration: 300.ms);
  }

  static String _timeAgo(DateTime t) {
    final s = DateTime.now().difference(t).inSeconds;
    if (s < 60) return 'just now';
    if (s < 3600) return '${s ~/ 60}m ago';
    return '${s ~/ 3600}h ago';
  }
}

class _TypeBadge extends StatelessWidget {
  final AppAlert alert;
  const _TypeBadge({required this.alert});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: alert.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: alert.color.withValues(alpha: 0.4)),
      ),
      child: Text(
        alert.label,
        style: GoogleFonts.jetBrainsMono(
          color: alert.color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── Alert History Panel ────────────────────────────────────────
class _AlertHistoryPanel extends StatelessWidget {
  final VoidCallback onClose;
  const _AlertHistoryPanel({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final history = AlertService().history;

    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withValues(alpha: 0.6),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: 520,
              height: 440,
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D1A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                    blurRadius: 40,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                    child: Row(
                      children: [
                        const Text('🔔', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Text(
                          'Alert History',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${history.length}',
                            style: GoogleFonts.jetBrainsMono(
                                color: Colors.white54, fontSize: 11),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: onClose,
                          icon: const Icon(Icons.close, color: Colors.white38),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),

                  // History list
                  Expanded(
                    child: history.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🛡️',
                                    style: TextStyle(fontSize: 36)),
                                const SizedBox(height: 8),
                                Text(
                                  'No alerts triggered yet',
                                  style: GoogleFonts.inter(
                                      color: Colors.white38, fontSize: 14),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: history.length,
                            separatorBuilder: (_, __) => Divider(
                              color: Colors.white.withValues(alpha: 0.04),
                              height: 1,
                            ),
                            itemBuilder: (_, i) {
                              final a = history[i];
                              return ListTile(
                                leading: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: a.color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(a.icon,
                                        style: const TextStyle(fontSize: 16)),
                                  ),
                                ),
                                title: Text(
                                  a.message,
                                  style: GoogleFonts.inter(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                                subtitle: Text(
                                  _fullTime(a.timestamp),
                                  style: const TextStyle(
                                      color: Colors.white38, fontSize: 11),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: a.color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(a.label,
                                      style: TextStyle(
                                          color: a.color, fontSize: 9)),
                                ),
                                dense: true,
                              );
                            },
                          ),
                  ),

                  // Footer
                  Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            AlertService().dismissAll();
                            onClose();
                          },
                          icon: const Icon(Icons.delete_sweep,
                              size: 16, color: Color(0xFFEF4444)),
                          label: Text(
                            'Clear All',
                            style: GoogleFonts.inter(
                                color: const Color(0xFFEF4444), fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .scale(
                    begin: const Offset(0.92, 0.92),
                    end: const Offset(1, 1),
                    duration: 250.ms,
                    curve: Curves.easeOutCubic)
                .fadeIn(duration: 200.ms),
          ),
        ),
      ),
    );
  }

  static String _fullTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago — ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }
}
