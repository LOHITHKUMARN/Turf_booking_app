import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final identifier = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      _showSnackBar('PLEASE FILL ALL FIELDS', Colors.redAccent);
      return;
    }

    final success = await authProvider.login(identifier, password);
    if (success) {
      if (authProvider.user?.role != 'admin') {
        authProvider.logout();
        _showSnackBar('ACCESS DENIED: ADMIN ONLY', Colors.redAccent);
      } else {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } else {
      _showSnackBar('INVALID CREDENTIALS', Colors.redAccent);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: AppTheme.softShadow,
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: const Icon(Icons.shield_rounded, size: 48, color: AppTheme.primaryColor),
              ),
              const SizedBox(height: 48),
              Text(
                'CENTRAL COMMAND',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryColor,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'ADMINISTRATIVE ACCESS',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textMain,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 48),
              _buildExecutiveField(_emailController, 'IDENTIFIER', Icons.alternate_email_rounded),
              const SizedBox(height: 20),
              _buildExecutiveField(
                _passwordController, 
                'SECURITY KEY', 
                Icons.lock_rounded,
                isPassword: true,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shadowColor: AppTheme.primaryColor.withOpacity(0.4),
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: authProvider.isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('AUTHORIZE SESSION', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5)),
                ),
              ),
              const SizedBox(height: 32),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/signup'),
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 12),
                    children: [
                      const TextSpan(text: "Unregistered? "),
                      TextSpan(
                        text: "REQUEST ACCESS",
                        style: GoogleFonts.outfit(color: AppTheme.primaryColor, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExecutiveField(TextEditingController controller, String hint, IconData icon, {bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && _obscurePassword,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textMain),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 20),
          suffixIcon: isPassword ? IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18, color: AppTheme.textSecondary.withOpacity(0.3)),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ) : null,
        ),
      ),
    );
  }
}
