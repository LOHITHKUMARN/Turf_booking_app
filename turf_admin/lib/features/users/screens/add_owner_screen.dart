import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

class AddOwnerScreen extends StatefulWidget {
  const AddOwnerScreen({super.key});

  @override
  _AddOwnerScreenState createState() => _AddOwnerScreenState();
}

class _AddOwnerScreenState extends State<AddOwnerScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  void _addOwner() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PLEASE FILL ALL FIELDS', style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('MINIMUM 6 CHARACTERS REQUIRED', style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final result = await authProvider.signup(
      name: name,
      email: email,
      phone: phone,
      password: password,
      role: 'owner',
    );

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OWNER ONBOARDED SUCCESSFULLY!', style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
          backgroundColor: AppTheme.primaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'].toUpperCase(), style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = Provider.of<AuthProvider>(context).isLoading;

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: Text('PROVISION ACCESS', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2, color: Colors.white)),
        elevation: 0,
        backgroundColor: AppTheme.headerGreen,
        surfaceTintColor: AppTheme.headerGreen,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white, size: 18),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: AppTheme.softShadow,
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: const Icon(Icons.key_rounded, size: 40, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 48),
            _buildSectionHeader("COMMERCIAL PROFILE"),
            const SizedBox(height: 20),
            _buildExecutiveField(_nameController, "Owner Full Name", Icons.person_rounded),
            const SizedBox(height: 16),
            _buildExecutiveField(_emailController, "Business Email", Icons.email_rounded, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 16),
            _buildExecutiveField(_phoneController, "Contact Primary", Icons.phone_rounded, keyboardType: TextInputType.phone),
            const SizedBox(height: 32),
            _buildSectionHeader("SECURITY PROTOCOL"),
            const SizedBox(height: 20),
            _buildExecutiveField(
              _passwordController, 
              "Secure Password", 
              Icons.shield_rounded,
              isPassword: true,
            ),
            const SizedBox(height: 56),
            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                onPressed: isLoading ? null : _addOwner,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  elevation: 8,
                  shadowColor: AppTheme.primaryColor.withOpacity(0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('AUTHORIZE & DEPLOY', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.5)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(width: 12, height: 2, decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.outfit(
            color: AppTheme.textMain.withOpacity(0.4),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildExecutiveField(TextEditingController controller, String hint, IconData icon, {TextInputType? keyboardType, bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && _obscurePassword,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textMain),
        keyboardType: keyboardType,
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
