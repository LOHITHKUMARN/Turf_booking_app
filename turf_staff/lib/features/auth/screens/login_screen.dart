import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/widgets/common_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  void _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    final errorMessage = await Provider.of<AuthProvider>(context, listen: false)
        .login(email, password);

    if (!mounted) return;

    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } else {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color kTitleColor = Color(0xFF1B5E20);
    const Color kSubtitleColor = Color(0xFF4E5D52);
    const Color kInputBgColor = Colors.white;

    const List<Color> kBgGradient = [
      Color(0xFFE8F5E9), // light green
      Color(0xFFC8E6C9), // medium
      Color(0xFFA5D6A7), // deeper green
    ];

    const List<Color> kButtonGradient = [
      Color(0xFF2E7D32),
      Color(0xFF43A047),
    ];

    final isLoading = Provider.of<AuthProvider>(context).isLoading;

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
            child: Column(
              children: [
                // 🔙 Back Button
                AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: kTitleColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                // 📱 Content
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(minHeight: constraints.maxHeight),
                          child: IntrinsicHeight(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 32),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  // 🔝 Top Section
                                  Column(
                                    children: [
                                      const SizedBox(height: 40),

                                      // ✨ Logo with glow
                                      Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF43A047)
                                                  .withOpacity(0.15),
                                              blurRadius: 40,
                                              spreadRadius: 10,
                                            )
                                          ],
                                        ),
                                        child: Hero(
                                          tag: 'app_logo',
                                          child: ClipRRect(
                                            child: Align(
                                              alignment: Alignment.center,
                                              widthFactor: 0.7,
                                              heightFactor: 0.7,
                                              child: Image.asset(
                                                'assets/app_logo.png',
                                                height: 200,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 12),

                                      // 🟢 Title
                                      Text(
                                        'Welcome Back',
                                        style: GoogleFonts.poppins(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: kTitleColor,
                                        ),
                                      ),

                                      const SizedBox(height: 6),

                                      // 🔤 Subtitle
                                      Text(
                                        'Sign in to continue to your account',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: kSubtitleColor
                                              .withOpacity(0.95),
                                        ),
                                      ),

                                      const SizedBox(height: 28),

                                      // 📧 Email Field
                                      _buildField(
                                        controller: _emailController,
                                        hint: 'Enter your email or phone',
                                        icon: Icons.person_outline,
                                        color: kTitleColor,
                                      ),

                                      const SizedBox(height: 18),

                                      // 🔒 Password Field
                                      _buildField(
                                        controller: _passwordController,
                                        hint: 'Enter your password',
                                        icon: Icons.lock_outline,
                                        color: kTitleColor,
                                        isPassword: true,
                                        obscure: _obscurePassword,
                                        toggle: () => setState(() =>
                                            _obscurePassword =
                                                !_obscurePassword),
                                      ),

                                      const SizedBox(height: 12),

                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: () {},
                                          child: Text(
                                            'Forgot password?',
                                            style: GoogleFonts.poppins(
                                              color: kTitleColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // 🔽 Bottom Section
                                  Column(
                                    children: [
                                      // 🚀 Button
                                      PressableScaleButton(
                                        onPressed:
                                            isLoading ? null : _login,
                                        child: Container(
                                          width: double.infinity,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: kButtonGradient,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(30),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF2E7D32)
                                                    .withOpacity(0.3),
                                                blurRadius: 12,
                                                offset: const Offset(0, 6),
                                              )
                                            ],
                                          ),
                                          child: Center(
                                            child: isLoading
                                                ? const CircularProgressIndicator(
                                                    color: Colors.white)
                                                : Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        'Login to Staff Portal',
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      const Icon(
                                                        Icons
                                                            .arrow_forward_rounded,
                                                        color: Colors.white,
                                                      )
                                                    ],
                                                  ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 24),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✨ Input Field Widget
  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color color,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? toggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && obscure,
        style: GoogleFonts.poppins(
          color: color,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              GoogleFonts.poppins(color: color.withOpacity(0.3)),
          prefixIcon: Icon(icon, color: color.withOpacity(0.4)),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscure
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: color.withOpacity(0.4),
                  ),
                  onPressed: toggle,
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        ),
      ),
    );
  }
}
