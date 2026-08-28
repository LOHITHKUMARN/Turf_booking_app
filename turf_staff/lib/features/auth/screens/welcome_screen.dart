import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';
import '../../../core/widgets/common_widgets.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Precise Colors
    const Color kTitleColor = Color(0xFF1B5E20);
    const Color kSubtitleColor = Color(0xFF4E5D52);
    const List<Color> kBgGradient = [
      Color(0xFFE8F5E9), // light green
      Color(0xFFC8E6C9), // medium
      Color(0xFFA5D6A7), // deeper green
    ];
    const List<Color> kButtonGradient = [
      Color(0xFF2E7D32),
      Color(0xFF43A047),
    ];

    return Scaffold(
      body: Stack(
        children: [
          // 🌈 Base Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFFFFF), // white top
                  Color(0xFFF3F9F4), // soft green tint
                  Color(0xFFCDE7D0), // proper green bottom
                ],
              ),
            ),
          ),

          // ✨ Top Glow Effect
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.0,
                colors: [
                  Colors.white.withOpacity(0.35),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // 🌿 Bottom Green Depth
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 250,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Color(0xFF4CAF50).withOpacity(0.20),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ⚽ Field Lines (very subtle)
          CustomPaint(
            size: Size.infinite,
            painter: FieldLinesPainter(opacity: 0.03), // reduced visibility
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Top Section: Logo and Text
                  Column(
                    children: [
                      const SizedBox(height: 60),
                      Hero(
                        tag: 'app_logo',
                        child: ClipRRect(
                          child: Align(
                            alignment: Alignment.center,
                            widthFactor: 0.7,
                            heightFactor: 0.7,
                            child: Image.asset(
                              'assets/app_logo.png',
                              height: 280,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Turf Pro',
                        style: GoogleFonts.poppins(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: kTitleColor,
                          letterSpacing: 0.5,
                          shadows: [
                            const Shadow(
                              color: Colors.black12,
                              offset: Offset(0, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Staff Portal Management',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: kSubtitleColor.withOpacity(0.85),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  // Bottom Section: Button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: PressableScaleButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      ),
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: kButtonGradient,
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2E7D32).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Login to Staff Portal',
                              style: GoogleFonts.poppins(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
