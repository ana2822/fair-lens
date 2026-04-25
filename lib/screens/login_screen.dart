import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:csv/csv.dart';
import '../services/auth_service.dart';
import '../models/bias_detector.dart';
import 'home_screen.dart';
import 'analysis_screen.dart';

enum AuthMode { login, signup }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  AuthMode _authMode = AuthMode.login;
  bool _isLoading = false;
  bool _isDemoLoading = false;
  bool _showAuth = false;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  late AnimationController _orbitController;
  late AnimationController _pulseController;

  // Sample hiring dataset — bundled for instant demo, no upload needed
  static const String _sampleCsv = '''CandidateID,AgeGroup,Gender,Race,YearsExperience,InterviewScore,Hired
1,25-34,Male,Majority,3,85,Yes
2,35-44,Female,Majority,5,88,Yes
3,18-24,Male,Minority,1,70,No
4,45-54,Male,Majority,10,92,Yes
5,25-34,Female,Minority,4,90,Yes
6,55+,Male,Majority,20,95,Yes
7,35-44,Male,Majority,6,82,No
8,25-34,Female,Majority,3,85,Yes
9,45-54,Female,Minority,12,88,Yes
10,25-34,Male,Minority,2,75,No
11,35-44,Male,Majority,8,89,Yes
12,18-24,Female,Majority,1,80,No
13,55+,Female,Majority,18,91,Yes
14,25-34,Male,Majority,4,84,Yes
15,35-44,Female,Minority,7,87,Yes
16,45-54,Male,Minority,14,90,Yes
17,25-34,Female,Majority,3,83,Yes
18,18-24,Male,Majority,2,78,No
19,35-44,Male,Majority,5,86,Yes
20,55+,Male,Minority,16,88,Yes
21,25-34,Female,Minority,4,89,Yes
22,45-54,Female,Majority,11,92,Yes
23,35-44,Male,Minority,6,84,No
24,25-34,Male,Majority,3,81,No
25,18-24,Female,Minority,1,75,No
26,55+,Female,Minority,22,94,Yes
27,35-44,Female,Majority,7,88,Yes
28,45-54,Male,Majority,13,91,Yes
29,25-34,Male,Minority,4,82,No
30,18-24,Male,Majority,1,77,No
31,35-44,Female,Minority,8,90,Yes
32,55+,Male,Majority,19,93,Yes
33,25-34,Female,Majority,3,85,Yes
34,45-54,Female,Minority,10,87,Yes
35,35-44,Male,Majority,6,86,Yes
36,18-24,Female,Majority,2,80,No
37,25-34,Male,Majority,5,88,Yes
38,55+,Female,Majority,25,96,Yes
39,45-54,Male,Minority,12,89,Yes
40,35-44,Female,Majority,9,91,Yes''';

  @override
  void initState() {
    super.initState();
    _orbitController = AnimationController(vsync: this, duration: const Duration(seconds: 30))..repeat();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _orbitController.dispose();
    _pulseController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ── DEMO: one tap, lands on real analysis results ────────────
  Future<void> _launchDemo() async {
    setState(() => _isDemoLoading = true);
    try {
      // Enter demo mode (no Firebase needed)
      AuthService().enterDemoMode();

      // Parse the bundled sample CSV
      final rows = const CsvToListConverter(fieldDelimiter: ',', eol: '\n')
          .convert(_sampleCsv)
          .where((r) => r.isNotEmpty)
          .toList();

      final headers = rows.first.map((e) => e.toString()).toList();
      final data = rows.skip(1).map((row) {
        final map = <String, dynamic>{};
        for (int i = 0; i < headers.length; i++) {
          map[headers[i]] = i < row.length ? row[i].toString() : '';
        }
        return map;
      }).toList();

      final result = BiasDetector.analyze(data, headers);
      final rawData = data.map((e) => e.map((k, v) => MapEntry(k, v.toString()))).toList();

      if (!mounted) return;

      // Push HomeScreen first so back button works, then AnalysisScreen on top
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
      // Small delay so HomeScreen is fully in the stack before pushing Analysis
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, a, b) => AnalysisScreen(result: result, rawData: rawData),
          transitionsBuilder: (_, a, b, child) => FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } catch (e) {
      setState(() => _isDemoLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      if (_authMode == AuthMode.login) {
        await AuthService().signInWithEmail(_emailController.text.trim(), _passwordController.text.trim());
      } else {
        await AuthService().signUpWithEmail(_emailController.text.trim(), _passwordController.text.trim());
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      String msg = 'Authentication failed';
      if (e.toString().contains('user-not-found')) msg = 'No user found with this email';
      if (e.toString().contains('wrong-password')) msg = 'Incorrect password';
      if (e.toString().contains('email-already-in-use')) msg = 'Email already registered';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await AuthService().signInWithGoogle();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Google Sign-In failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFF04040C),
      body: Stack(children: [
        // Animated background
        AnimatedBuilder(
          animation: _orbitController,
          builder: (_, __) {
            final angle = _orbitController.value * 2 * math.pi;
            return Stack(children: [
              Positioned(top: -100 + math.sin(angle) * 50, left: -100 + math.cos(angle) * 50,
                child: _glowBlob(const Color(0xFF6366F1), 400)),
              Positioned(bottom: -150 + math.cos(angle) * 100, right: -100 + math.sin(angle) * 100,
                child: _glowBlob(const Color(0xFF8B5CF6), 500)),
            ]);
          },
        ),

        Center(child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: math.min(size.width, 480)),
            child: Column(children: [
              // Logo
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.4), blurRadius: 24)],
                ),
                child: const Icon(Icons.lens_blur_rounded, color: Colors.white, size: 36),
              ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 20),
              Text('FairLens', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900))
                  .animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 8),
              Text('AI Governance & Bias Detection Platform', style: GoogleFonts.spaceGrotesk(color: Colors.white38, fontSize: 13))
                  .animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 36),

              // ── HUMAN STORY HOOK ──────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.2)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.format_quote_rounded, color: Color(0xFFEF4444), size: 16),
                    const SizedBox(width: 8),
                    Text('Real Case', style: GoogleFonts.spaceGrotesk(color: const Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ]),
                  const SizedBox(height: 10),
                  Text(
                    'Amazon\'s hiring AI penalized CVs that included the word "women\'s" — trained on 10 years of male-dominated hire data.',
                    style: GoogleFonts.spaceGrotesk(color: Colors.white70, fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 10),
                  Text('FairLens catches this. See it live →', style: GoogleFonts.spaceGrotesk(color: const Color(0xFF818CF8), fontSize: 12, fontWeight: FontWeight.bold)),
                ]),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 28),

              // ── DEMO BUTTON — THE HERO CTA ────────────────────
              AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) => GestureDetector(
                  onTap: _isDemoLoading ? null : _launchDemo,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.35 + 0.2 * _pulseController.value),
                        blurRadius: 28 + 12 * _pulseController.value,
                        offset: const Offset(0, 8),
                      )],
                    ),
                    child: _isDemoLoading
                        ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)))
                        : Column(children: [
                            Text('🚀 Try Live Demo', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 4),
                            Text('No sign-up required — see real bias analysis instantly', style: GoogleFonts.spaceGrotesk(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                          ]),
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.95, 0.95)),

              const SizedBox(height: 16),

              // Stats strip
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _statChip('40 candidates', 'Analyzed'),
                const SizedBox(width: 8),
                _statChip('Gender + Race', 'Bias detected'),
                const SizedBox(width: 8),
                _statChip('Grade F', 'Result'),
              ]).animate().fadeIn(delay: 500.ms),

              const SizedBox(height: 32),

              // Divider
              Row(children: [
                const Expanded(child: Divider(color: Colors.white10)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('or sign in for full access', style: GoogleFonts.spaceGrotesk(color: Colors.white24, fontSize: 11)),
                ),
                const Expanded(child: Divider(color: Colors.white10)),
              ]),

              const SizedBox(height: 24),

              // ── AUTH CARD (collapsed by default) ─────────────
              if (!_showAuth)
                GestureDetector(
                  onTap: () => setState(() => _showAuth = true),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Center(child: Text('Sign In / Create Account', style: GoogleFonts.spaceGrotesk(color: Colors.white38, fontSize: 13))),
                  ),
                )
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(children: [
                          _buildTextField(controller: _emailController, label: 'Corporate Email', icon: Icons.email_outlined, validator: (v) => v!.contains('@') ? null : 'Invalid email'),
                          const SizedBox(height: 16),
                          _buildTextField(controller: _passwordController, label: 'Password', icon: Icons.lock_outline, isPassword: true, validator: (v) => v!.length >= 6 ? null : 'Min 6 characters'),
                          if (_authMode == AuthMode.signup) ...[
                            const SizedBox(height: 16),
                            _buildTextField(controller: _confirmPasswordController, label: 'Confirm Password', icon: Icons.lock_reset_rounded, isPassword: true, validator: (v) => v == _passwordController.text ? null : 'Passwords mismatch'),
                          ],
                          const SizedBox(height: 20),
                          _primaryAuthButton(_authMode == AuthMode.login ? 'Sign In' : 'Register', _submit),
                          const SizedBox(height: 16),
                          _googleButton(_handleGoogleSignIn),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () => setState(() => _authMode = _authMode == AuthMode.login ? AuthMode.signup : AuthMode.login),
                            child: Text(
                              _authMode == AuthMode.login ? "Don't have an account? Sign Up" : "Already have an account? Log In",
                              style: GoogleFonts.spaceGrotesk(color: const Color(0xFF818CF8), fontSize: 13),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ),
                ).animate().fadeIn(),
            ]),
          ),
        )),
      ]),
    );
  }

  Widget _statChip(String value, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.04),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.white.withOpacity(0.08)),
    ),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(value, style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9)),
    ]),
  );

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, bool isPassword = false, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      validator: validator,
      style: GoogleFonts.spaceGrotesk(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6366F1))),
        filled: true,
        fillColor: Colors.white.withOpacity(0.02),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
    );
  }

  Widget _primaryAuthButton(String label, VoidCallback onTap) => SizedBox(
    width: double.infinity,
    height: 50,
    child: ElevatedButton(
      onPressed: _isLoading ? null : onTap,
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      child: _isLoading ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2) : Text(label, style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
    ),
  );

  Widget _googleButton(VoidCallback onTap) => InkWell(
    onTap: _isLoading ? null : onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      height: 50,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.g_mobiledata_rounded, color: Colors.black, size: 32),
        const SizedBox(width: 8),
        Text('Sign in with Google', style: GoogleFonts.spaceGrotesk(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold)),
      ]),
    ),
  );

  Widget _glowBlob(Color color, double size) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color.withOpacity(0.15), color.withOpacity(0.0)])),
  );
}
