import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../screens/home_screen.dart';
import '../screens/gov_dashboard_screen.dart';
import '../screens/text_bias_screen.dart';
import '../screens/simulator_screen.dart';
import '../screens/face_bias_screen.dart';
import '../screens/login_screen.dart';
import '../screens/profile_screen.dart';
import '../services/auth_service.dart';
import '../services/dataset_service.dart';

class TopNav extends StatefulWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(64);
  final String activeItem;

  const TopNav({super.key, required this.activeItem});

  @override
  State<TopNav> createState() => _TopNavState();
}

class _TopNavState extends State<TopNav> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final MenuController _toolsMenuController = MenuController();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleUpload(BuildContext context) {
    DatasetService.pickAndAnalyze(
      context,
      setLoading: (loading) {},
      setError: (error) {
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $error', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
          );
        }
      },
    );
  }

  Widget _pulseDot(Color color) => AnimatedBuilder(
    animation: _pulseController,
    builder: (_, __) => Container(
      width: 7, height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(
          color: color.withValues(alpha: 0.4 + 0.4 * _pulseController.value),
          blurRadius: 6 + 4 * _pulseController.value,
        )],
      ),
    ),
  );

  Widget _navItem(String label, bool isActive, VoidCallback onTap) {
    bool isHover = false;
    bool isPressed = false;
    return StatefulBuilder(
      builder: (context, setBtnState) {
        return MouseRegion(
          onEnter: (_) => setBtnState(() => isHover = true),
          onExit: (_) => setBtnState(() => isHover = false),
          child: GestureDetector(
            onTapDown: (_) => setBtnState(() => isPressed = true),
            onTapUp: (_) => setBtnState(() => isPressed = false),
            onTapCancel: () => setBtnState(() => isPressed = false),
            onTap: onTap,
            child: AnimatedScale(
              scale: isPressed ? 0.92 : (isHover ? 1.03 : 1.0),
              duration: const Duration(milliseconds: 100),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isActive 
                      ? Colors.white.withValues(alpha: 0.08)
                      : (isHover ? Colors.white.withValues(alpha: 0.04) : Colors.transparent),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(label, style: GoogleFonts.spaceGrotesk(
                  color: isActive ? Colors.white : (isHover ? Colors.white : Colors.white70),
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                )),
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildToolsDropdown() {
    bool isHover = false;
    final isActive = widget.activeItem == 'Tools';
    return MenuAnchor(
      controller: _toolsMenuController,
      menuChildren: [
        MenuItemButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TextBiasScreen())),
          child: _dropdownItem(Icons.document_scanner, 'Text Bias', 'Scan language for hidden sentiment'),
        ),
        MenuItemButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SimulatorScreen())),
          child: _dropdownItem(Icons.tune_rounded, 'Simulator', 'Model outcome simulation'),
        ),
        MenuItemButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FaceBiasScreen())),
          child: _dropdownItem(Icons.face_retouching_natural, 'Face Bias', 'Evaluate computer vision fairness'),
        ),
      ],
      style: MenuStyle(
        backgroundColor: WidgetStateProperty.all(const Color(0xFF1E1E2C)),
        shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        padding: WidgetStateProperty.all(const EdgeInsets.all(8)),
      ),
      builder: (context, controller, child) {
        return StatefulBuilder(
          builder: (context, setBtnState) {
            return MouseRegion(
              onEnter: (_) {
                setBtnState(() => isHover = true);
                if (!controller.isOpen) controller.open();
              },
              onExit: (_) => setBtnState(() => isHover = false),
              child: GestureDetector(
                onTap: () {
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isActive || controller.isOpen
                        ? Colors.white.withValues(alpha: 0.08)
                        : (isHover ? Colors.white.withValues(alpha: 0.04) : Colors.transparent),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Row(
                    children: [
                      Text('Tools', style: GoogleFonts.spaceGrotesk(
                        color: isActive || controller.isOpen ? Colors.white : (isHover ? Colors.white : Colors.white70),
                        fontSize: 14,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      )),
                      const SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: isActive || controller.isOpen ? Colors.white : Colors.white70),
                    ],
                  ),
                ),
              ),
            );
          }
        );
      },
    );
  }

  Widget _dropdownItem(IconData icon, String title, String description) {
    return Container(
      width: 250,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: const Color(0xFF8B5CF6), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(description, style: GoogleFonts.spaceGrotesk(color: Colors.white54, fontSize: 11)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _glowButton(String text, IconData icon, VoidCallback onTap) {
    bool isHover = false;
    return StatefulBuilder(
      builder: (context, setBtnState) {
        return MouseRegion(
          onEnter: (_) => setBtnState(() => isHover = true),
          onExit: (_) => setBtnState(() => isHover = false),
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                borderRadius: BorderRadius.circular(10),
                boxShadow: isHover ? [BoxShadow(color: const Color(0xFF8B5CF6).withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 4))] : [],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(text, style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
        );
      }
    );
  }

  Widget _buildProfileOption() {
    final user = AuthService().currentUser;
    final isDemo = user == null || user.isAnonymous;

    if (isDemo) {
      return IconButton(
        icon: const Icon(Icons.login_rounded, color: Colors.white70, size: 20),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
        },
        tooltip: 'Login',
      );
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.5), width: 1.5),
          image: user.photoURL != null 
              ? DecorationImage(image: NetworkImage(user.photoURL!), fit: BoxFit.cover)
              : null,
          color: user.photoURL == null ? const Color(0xFF8B5CF6) : null,
        ),
        child: user.photoURL == null
            ? Center(child: Text(user.displayName?.isNotEmpty == true ? user.displayName![0].toUpperCase() : 'U', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)))
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 768;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF04040C).withValues(alpha: 0.8),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Row(children: [
            // Logo
            GestureDetector(
              onTap: () {
                if (widget.activeItem != 'Home') {
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (route) => false);
                }
              },
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.5),
                    blurRadius: 16, spreadRadius: 1,
                  )],
                ),
                child: const Icon(Icons.lens_blur_rounded, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                if (widget.activeItem != 'Home') {
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (route) => false);
                }
              },
              child: Text('FairLens', style: GoogleFonts.spaceGrotesk(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            ),
            // Live badge
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                _pulseDot(const Color(0xFF10B981)),
                const SizedBox(width: 5),
                Text('LIVE', style: GoogleFonts.spaceGrotesk(
                  color: const Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.w700,
                  letterSpacing: 1)),
              ]),
            ),
            
            if (!isMobile) const SizedBox(width: 32),
            if (!isMobile) ...[
              _navItem('Dashboard', widget.activeItem == 'Dashboard', () {
                if (widget.activeItem == 'Dashboard') {
                  Navigator.pop(context);
                } else {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const GovDashboardScreen()));
                }
              }),
              _buildToolsDropdown(),
              _navItem('Docs', widget.activeItem == 'Docs', () {}),
            ],

            const Spacer(),
            
            if (isMobile) ...[
              PopupMenuButton<String>(
                icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
                color: const Color(0xFF1E1E2C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'Dashboard', child: Text('Dashboard', style: GoogleFonts.spaceGrotesk(color: Colors.white))),
                  PopupMenuItem(value: 'Tools', child: Text('Tools ▾', style: GoogleFonts.spaceGrotesk(color: Colors.white))),
                  PopupMenuItem(value: 'Docs', child: Text('Docs', style: GoogleFonts.spaceGrotesk(color: Colors.white))),
                ],
                onSelected: (value) {
                  if (value == 'Dashboard') Navigator.push(context, MaterialPageRoute(builder: (_) => const GovDashboardScreen()));
                  if (value == 'Tools') _toolsMenuController.open();
                },
              ),
            ],

            if (!isMobile) const SizedBox(width: 8),
            _buildProfileOption(),
            const SizedBox(width: 14),
            
            if (isMobile)
              IconButton(
                icon: const Icon(Icons.upload_rounded, color: Color(0xFF8B5CF6), size: 24),
                onPressed: () => _handleUpload(context),
              )
            else
              _glowButton('Analyse Dataset', Icons.upload_rounded, () => _handleUpload(context)),
          ]),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }
}
