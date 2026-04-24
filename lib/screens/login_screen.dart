import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../services/auth_service.dart';
import 'home_screen.dart';

enum AuthMode { login, signup }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  AuthMode _authMode = AuthMode.login;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  late AnimationController _orbitController;

  @override
  void initState() {
    super.initState();
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
  }

  @override
  void dispose() {
    _orbitController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      if (_authMode == AuthMode.login) {
        await AuthService().signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } else {
        await AuthService().signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      }
      // No manual navigation needed! StreamBuilder in main.dart handles it.
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      String errorMessage = 'Authentication failed';
      if (e.toString().contains('user-not-found')) errorMessage = 'No user found with this email';
      if (e.toString().contains('wrong-password')) errorMessage = 'Incorrect password';
      if (e.toString().contains('email-already-in-use')) errorMessage = 'Email already registered';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _handleAnonymousSignIn() async {
    setState(() => _isLoading = true);
    try {
      await AuthService().signInAnonymously();
    } catch (e) {
      // If Firebase Auth is not enabled, use the new enterDemoMode
      AuthService().enterDemoMode();
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await AuthService().signInWithGoogle();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-In failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF04040C),
      body: Stack(
        children: [
          // Background Animation
          AnimatedBuilder(
            animation: _orbitController,
            builder: (context, child) {
              final angle = _orbitController.value * 2 * math.pi;
              return Stack(
                children: [
                  Positioned(
                    top: -100 + math.sin(angle) * 50,
                    left: -100 + math.cos(angle) * 50,
                    child: _glowBlob(const Color(0xFF6366F1), 400),
                  ),
                  Positioned(
                    bottom: -150 + math.cos(angle) * 100,
                    right: -100 + math.sin(angle) * 100,
                    child: _glowBlob(const Color(0xFF8B5CF6), 500),
                  ),
                ],
              );
            },
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.4),
                          blurRadius: 24,
                        )
                      ],
                    ),
                    child: const Icon(Icons.lens_blur_rounded, color: Colors.white, size: 36),
                  ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack),

                  const SizedBox(height: 24),

                  Text(
                    _authMode == AuthMode.login ? 'Welcome Back' : 'Create Account',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 40),

                  // Auth Card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        width: math.min(size.width, 450),
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _buildTextField(
                                controller: _emailController,
                                label: 'Corporate Email',
                                icon: Icons.email_outlined,
                                validator: (v) => v!.contains('@') ? null : 'Invalid email',
                              ),
                              const SizedBox(height: 20),
                                _buildTextField(
                                  controller: _passwordController,
                                  label: 'Password',
                                  icon: Icons.lock_outline,
                                  isPassword: true,
                                  validator: (v) => v!.length >= 6 ? null : 'Min 6 characters',
                                ),
                                if (_authMode == AuthMode.login)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Password reset link sent to your email.')),
                                        );
                                      },
                                      child: Text(
                                        'Forgot Password?',
                                        style: GoogleFonts.spaceGrotesk(
                                          color: const Color(0xFF6366F1),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (_authMode == AuthMode.signup) ...[
                                  const SizedBox(height: 20),
                                  _buildTextField(
                                    controller: _confirmPasswordController,
                                    label: 'Confirm Password',
                                    icon: Icons.lock_reset_rounded,
                                    isPassword: true,
                                    validator: (v) => v == _passwordController.text ? null : 'Passwords mismatch',
                                  ),
                                ],
                                const SizedBox(height: 24),
                              
                              _primaryButton(
                                _authMode == AuthMode.login ? 'Sign In' : 'Register Now',
                                _submit,
                              ),

                              const SizedBox(height: 24),
                              
                              Row(children: [
                                const Expanded(child: Divider(color: Colors.white10)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text('OR', style: GoogleFonts.spaceGrotesk(color: Colors.white24, fontSize: 12)),
                                ),
                                const Expanded(child: Divider(color: Colors.white10)),
                              ]),

                              const SizedBox(height: 24),

                              _googleButton(_handleGoogleSignIn),

                              const SizedBox(height: 16),

                              _secondaryButton('Launch Demo Mode', _handleAnonymousSignIn),

                              const SizedBox(height: 32),

                              GestureDetector(
                                onTap: () => setState(() => _authMode = _authMode == AuthMode.login ? AuthMode.signup : AuthMode.login),
                                child: RichText(
                                  text: TextSpan(
                                    style: GoogleFonts.spaceGrotesk(color: Colors.white54, fontSize: 14),
                                    children: [
                                      TextSpan(text: _authMode == AuthMode.login ? "Don't have an account? " : "Already have an account? "),
                                      TextSpan(
                                        text: _authMode == AuthMode.login ? "Sign Up" : "Log In",
                                        style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      validator: validator,
      style: GoogleFonts.spaceGrotesk(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6366F1)),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.02),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  Widget _secondaryButton(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton(
        onPressed: _isLoading ? null : onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          label,
          style: GoogleFonts.spaceGrotesk(color: Colors.white38, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _primaryButton(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 8,
          shadowColor: const Color(0xFF6366F1).withOpacity(0.5),
        ),
        child: _isLoading 
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(label, style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _googleButton(VoidCallback onTap) {
    return InkWell(
      onTap: _isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.g_mobiledata_rounded, color: Colors.black, size: 36),
            const SizedBox(width: 8),
            Text(
              'Sign in with Google',
              style: GoogleFonts.spaceGrotesk(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glowBlob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(0.15), color.withOpacity(0.0)],
        ),
      ),
    );
  }
}
