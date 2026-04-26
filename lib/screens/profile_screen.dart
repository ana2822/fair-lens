import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? get user => AuthService().currentUser;
  bool _notificationsEnabled = true;
  bool _emailAlerts = true;
  bool _twoFAEnabled = false;

  // ── HELPERS ────────────────────────────────────────────────────
  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.spaceGrotesk(color: Colors.white)),
      backgroundColor: error ? const Color(0xFFEF4444) : const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ── EDIT PROFILE MODAL ─────────────────────────────────────────
  void _showEditProfile() {
    final nameCtrl = TextEditingController(text: user?.displayName ?? '');
    final orgCtrl  = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => _GlassDialog(
        title: '✔️ Edit Profile',
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _dlgField(nameCtrl, 'Display Name', Icons.person_outline_rounded),
          const SizedBox(height: 16),
          _dlgField(orgCtrl, 'Organization', Icons.business_rounded),
        ]),
        actions: [
          _dlgBtn('Cancel', onTap: () => Navigator.pop(context), primary: false),
          _dlgBtn('Save Changes', onTap: () async {
            if (user != null && !AuthService.useMockMode) {
              try {
                await user!.updateDisplayName(nameCtrl.text);
              } catch (e) {
                if (mounted) _showSnack('Failed to update: $e', error: true);
                return;
              }
            }
            if (mounted) {
              setState(() {}); // Refresh UI with new name
              Navigator.pop(context);
              _showSnack('Profile updated successfully!');
            }
          }),
        ],
      ),
    );
  }

  // ── PERSONAL INFO MODAL ────────────────────────────────────────
  void _showPersonalInfo() {
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    final phoneCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => _GlassDialog(
        title: '👤 Personal Information',
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _dlgField(emailCtrl, 'Email Address', Icons.email_outlined, readOnly: true),
          const SizedBox(height: 16),
          _dlgField(phoneCtrl, 'Phone Number', Icons.phone_outlined),
          const SizedBox(height: 12),
          _infoRow('User ID', user?.uid ?? 'N/A'),
          _infoRow('Account Type', (user?.isAnonymous ?? true) ? 'Demo' : 'Full Account'),
          _infoRow('Email Verified', (user?.emailVerified ?? false) ? '✅ Yes' : '❌ No'),
        ]),
        actions: [
          _dlgBtn('Close', onTap: () => Navigator.pop(context), primary: false),
          _dlgBtn('Update', onTap: () {
            Navigator.pop(context);
            _showSnack('Personal info updated!');
          }),
        ],
      ),
    );
  }

  // ── ORGANIZATION MODAL ─────────────────────────────────────────
  void _showOrganization() {
    final orgCtrl  = TextEditingController(text: 'My Organization');
    final roleCtrl = TextEditingController(text: 'Admin');
    showDialog(
      context: context,
      builder: (_) => _GlassDialog(
        title: '🏢 Organization Settings',
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _dlgField(orgCtrl,  'Organization Name', Icons.business_rounded),
          const SizedBox(height: 16),
          _dlgField(roleCtrl, 'Your Role', Icons.badge_outlined),
          const SizedBox(height: 16),
          _infoRow('Plan', 'Pro — 5 seats'),
          _infoRow('Datasets this month', '127'),
        ]),
        actions: [
          _dlgBtn('Cancel', onTap: () => Navigator.pop(context), primary: false),
          _dlgBtn('Save', onTap: () {
            Navigator.pop(context);
            _showSnack('Organization settings saved!');
          }),
        ],
      ),
    );
  }

  // ── SECURITY MODAL ─────────────────────────────────────────────
  void _showSecurity() {
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, setSt) => _GlassDialog(
        title: '🔐 Security & Privacy',
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _switchRow('Two-Factor Authentication', _twoFAEnabled, (v) {
            setSt(() => _twoFAEnabled = v);
            setState(() {});
          }),
          const SizedBox(height: 8),
          _infoRow('Last sign-in', 'Today'),
          _infoRow('Sessions', '1 active'),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showSnack('Password reset email sent!');
              },
              icon: const Icon(Icons.lock_reset_rounded, size: 16),
              label: Text('Reset Password', style: GoogleFonts.spaceGrotesk()),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF818CF8),
                side: const BorderSide(color: Color(0xFF818CF8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ]),
        actions: [
          _dlgBtn('Done', onTap: () => Navigator.pop(context)),
        ],
      )),
    );
  }

  // ── NOTIFICATIONS MODAL ────────────────────────────────────────
  void _showNotifications() {
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, setSt) => _GlassDialog(
        title: '🔔 Notifications',
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _switchRow('Push Notifications', _notificationsEnabled, (v) {
            setSt(() => _notificationsEnabled = v);
            setState(() {});
          }),
          const SizedBox(height: 8),
          _switchRow('Email Alerts', _emailAlerts, (v) {
            setSt(() => _emailAlerts = v);
            setState(() {});
          }),
          const SizedBox(height: 8),
          _infoRow('Frequency', 'Instant'),
          _infoRow('Last alert', '2 hours ago'),
        ]),
        actions: [
          _dlgBtn('Save', onTap: () {
            Navigator.pop(context);
            _showSnack('Notification preferences saved!');
          }),
        ],
      )),
    );
  }

  // ── HELP CENTER ────────────────────────────────────────────────
  void _showHelpCenter() {
    showDialog(
      context: context,
      builder: (_) => _GlassDialog(
        title: '❓ Help Center',
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          ...[
            ('📖 Getting Started Guide', 'Learn bias detection basics'),
            ('📊 Uploading Datasets', 'Supported formats & limits'),
            ('⚖️ Understanding Results', 'How scores are calculated'),
            ('🔗 API Integration Docs', 'Embed FairLens in your pipeline'),
          ].map((item) => _helpItem(item.$1, item.$2)),
        ]),
        actions: [
          _dlgBtn('Close', onTap: () => Navigator.pop(context), primary: false),
        ],
      ),
    );
  }

  // ── CONTACT SUPPORT ────────────────────────────────────────────
  void _showContactSupport() {
    final msgCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => _GlassDialog(
        title: '💬 Contact Support',
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _infoRow('Response time', '< 2 hours'),
          _infoRow('Support email', 'support@fairlens.ai'),
          const SizedBox(height: 16),
          TextFormField(
            controller: msgCtrl,
            maxLines: 4,
            style: GoogleFonts.spaceGrotesk(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Describe your issue...',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.04),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF6366F1)),
              ),
            ),
          ),
        ]),
        actions: [
          _dlgBtn('Cancel', onTap: () => Navigator.pop(context), primary: false),
          _dlgBtn('Send', onTap: () {
            Navigator.pop(context);
            _showSnack('Message sent! We\'ll reply within 2 hours.');
          }),
        ],
      ),
    );
  }

  // ── SIGN OUT ───────────────────────────────────────────────────
  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (_) => _GlassDialog(
        title: '🚪 Sign Out',
        content: Text(
          'Are you sure you want to sign out of FairLens?',
          style: GoogleFonts.spaceGrotesk(color: Colors.white70, fontSize: 14, height: 1.6),
        ),
        actions: [
          _dlgBtn('Cancel', onTap: () => Navigator.pop(context), primary: false),
          _dlgBtn('Sign Out', color: const Color(0xFFEF4444), onTap: () async {
            Navigator.pop(context);
            await AuthService().signOut();
            if (mounted) Navigator.pop(context);
          }),
        ],
      ),
    );
  }

  // ── COPY UID ───────────────────────────────────────────────────
  void _copyUid() {
    Clipboard.setData(ClipboardData(text: user?.uid ?? ''));
    _showSnack('User ID copied to clipboard');
  }

  // ── BUILD ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: const Color(0xFF04040C),
      body: Stack(children: [
        Positioned(top: -100, left: -100, child: _glowBlob(const Color(0xFF6366F1), 300)),
        Positioned(bottom: -50,  right: -50, child: _glowBlob(const Color(0xFF8B5CF6), 250)),
        SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // AppBar row
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 16),
              Text('Profile Settings', style: GoogleFonts.spaceGrotesk(
                color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold,
              )),
            ]),
          ),

          Expanded(child: Center(child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: w > 800 ? 0 : 24, vertical: 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _buildProfileHeader(),
                const SizedBox(height: 40),
                _sectionLabel('Account Settings'),
                const SizedBox(height: 16),
                _buildSettingsCard([
                  _row(Icons.person_outline_rounded,  'Personal Information', 'Update your details',          _showPersonalInfo, trailing: const Icon(Icons.edit_rounded, color: Colors.white38, size: 20)),
                  _divider(),
                  _row(Icons.business_rounded,         'Organization',         'Manage workspace settings',    _showOrganization, trailing: const Icon(Icons.edit_rounded, color: Colors.white38, size: 20)),
                  _divider(),
                  _row(Icons.security_rounded,         'Security & Privacy',   'Password, 2FA, data usage',   _showSecurity),
                ]),
                const SizedBox(height: 32),
                _sectionLabel('Preferences'),
                const SizedBox(height: 16),
                _buildSettingsCard([
                  _row(Icons.notifications_none_rounded, 'Notifications', 'Email & push alerts', _showNotifications,
                      trailing: _notificationsEnabled
                          ? const Text('On',  style: TextStyle(color: Color(0xFF10B981), fontSize: 12))
                          : const Text('Off', style: TextStyle(color: Colors.white38,   fontSize: 12))),
                  _divider(),
                  _row(Icons.palette_outlined, 'Appearance', 'Dark mode active',
                      () => _showSnack('Appearance settings coming soon!')),
                ]),
                const SizedBox(height: 32),
                _sectionLabel('Data & Privacy'),
                const SizedBox(height: 16),
                _buildSettingsCard([
                  _row(Icons.fingerprint_rounded,    'Data Usage',         'How your data is used',           () => _showSnack('Data policy: No datasets are stored on our servers.')),
                  _divider(),
                  _row(Icons.copy_rounded,           'Copy User ID',       user?.uid != null ? '${user!.uid.substring(0, 8)}…' : 'N/A', _copyUid),
                  _divider(),
                  _row(Icons.delete_outline_rounded, 'Delete Account',     'Permanently remove your data',    () => _showSnack('Contact support to delete your account.', error: true),
                      iconColor: const Color(0xFFEF4444)),
                ]),
                const SizedBox(height: 32),
                _sectionLabel('Support'),
                const SizedBox(height: 16),
                _buildSettingsCard([
                  _row(Icons.help_outline_rounded,         'Help Center',     'Guides & documentation',  _showHelpCenter),
                  _divider(),
                  _row(Icons.chat_bubble_outline_rounded,  'Contact Support', 'Talk to our team',         _showContactSupport),
                ]),
                const SizedBox(height: 40),
                // Sign Out
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _confirmSignOut,
                    icon: const Icon(Icons.logout_rounded, size: 20),
                    label: Text('Sign Out', style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.1),
                      foregroundColor: const Color(0xFFEF4444),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ))),
        ])),
      ]),
    );
  }

  // ── PROFILE HEADER ─────────────────────────────────────────────
  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.5), width: 2),
            image: user?.photoURL != null
                ? DecorationImage(image: NetworkImage(user!.photoURL!), fit: BoxFit.cover)
                : null,
            color: user?.photoURL == null ? const Color(0xFF8B5CF6) : null,
            boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.3), blurRadius: 20)],
          ),
          child: user?.photoURL == null
              ? Center(child: Text(
                  user?.displayName?.isNotEmpty == true ? user!.displayName![0].toUpperCase() : 'U',
                  style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 32),
                ))
              : null,
        ).animate().scale(delay: 100.ms, duration: 300.ms, curve: Curves.easeOutBack),
        const SizedBox(width: 24),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(user?.displayName ?? 'Demo User', style: GoogleFonts.spaceGrotesk(
            color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold,
          )),
          const SizedBox(height: 4),
          Text(user?.email ?? 'demo@fairlens.ai', style: GoogleFonts.spaceGrotesk(
            color: Colors.white54, fontSize: 14,
          )),
          const SizedBox(height: 10),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
              ),
              child: Text(
                (user?.isAnonymous ?? true) ? '🎯 Demo Mode' : '✨ Pro Plan',
                style: GoogleFonts.spaceGrotesk(color: const Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ]),
        ]).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1)),
        if (MediaQuery.of(context).size.width > 560)
          ElevatedButton(
            onPressed: _showEditProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Edit Profile', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600)),
          ),
      ]),
    );
  }

  // ── REUSABLE WIDGETS ───────────────────────────────────────────
  Widget _sectionLabel(String label) => Text(label, style: GoogleFonts.spaceGrotesk(
    color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2,
  ));

  Widget _buildSettingsCard(List<Widget> children) => Container(
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.03),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
    ),
    child: Column(children: children),
  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05);

  Widget _row(IconData icon, String title, String subtitle, VoidCallback onTap,
      {Widget? trailing, Color? iconColor}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (iconColor ?? Colors.white).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor ?? Colors.white70, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,    style: GoogleFonts.spaceGrotesk(color: Colors.white,   fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(subtitle, style: GoogleFonts.spaceGrotesk(color: Colors.white54, fontSize: 12)),
          ])),
          trailing ?? const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 20),
        ]),
      ),
    );
  }

  Widget _divider() => Divider(height: 1, thickness: 1,
      color: Colors.white.withValues(alpha: 0.06), indent: 64);

  Widget _glowBlob(Color color, double size) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
      BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 100, spreadRadius: 20),
    ]),
  );

  // ── DIALOG HELPERS ─────────────────────────────────────────────
  Widget _dlgField(TextEditingController ctrl, String label, IconData icon,
      {bool readOnly = false}) {
    return TextFormField(
      controller: ctrl,
      readOnly: readOnly,
      style: GoogleFonts.spaceGrotesk(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: Colors.white38, size: 18),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF6366F1)),
        ),
      ),
    );
  }

  Widget _dlgBtn(String label, {required VoidCallback onTap, bool primary = true, Color? color}) {
    final c = color ?? const Color(0xFF6366F1);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: primary ? c : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: primary ? null : Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Text(label, style: GoogleFonts.spaceGrotesk(
          color: primary ? Colors.white : Colors.white60,
          fontWeight: FontWeight.w600, fontSize: 13,
        )),
      ),
    );
  }

  Widget _infoRow(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(k, style: GoogleFonts.spaceGrotesk(color: Colors.white54, fontSize: 13)),
      Text(v, style: GoogleFonts.spaceGrotesk(color: Colors.white,   fontSize: 13, fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _switchRow(String label, bool value, ValueChanged<bool> onChanged) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: GoogleFonts.spaceGrotesk(color: Colors.white70, fontSize: 14)),
      Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: const Color(0xFF6366F1),
      ),
    ],
  );

  Widget _helpItem(String title, String subtitle) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF818CF8), size: 12),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,    style: GoogleFonts.spaceGrotesk(color: Colors.white,   fontSize: 13, fontWeight: FontWeight.w600)),
        Text(subtitle, style: GoogleFonts.spaceGrotesk(color: Colors.white54, fontSize: 11)),
      ])),
    ]),
  );
}

// ── GLASS DIALOG WIDGET ──────────────────────────────────────────
class _GlassDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget> actions;

  const _GlassDialog({required this.title, required this.content, required this.actions});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D1A).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: GoogleFonts.spaceGrotesk(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold,
              )),
              const SizedBox(height: 20),
              content,
              const SizedBox(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.end,
                  children: actions.map((w) => Padding(padding: const EdgeInsets.only(left: 8), child: w)).toList()),
            ]),
          ),
        ),
      ),
    );
  }
}
