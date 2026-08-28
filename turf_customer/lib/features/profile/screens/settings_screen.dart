import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Appearance'),
            SwitchListTile(
              title: Text('Dark Mode', style: GoogleFonts.outfit(fontWeight: FontWeight.w500)),
              subtitle: Text('Enable dark theme for the app', style: GoogleFonts.outfit(fontSize: 12)),
              value: settings.themeMode == ThemeMode.dark,
              onChanged: (value) => settings.toggleTheme(value),
              activeColor: Colors.green[800],
            ),
            const Divider(),
            _buildSectionHeader('Language'),
            ListTile(
              title: Text('App Language', style: GoogleFonts.outfit(fontWeight: FontWeight.w500)),
              subtitle: Text(settings.locale.languageCode == 'en' ? 'English' : 'Hindi', style: GoogleFonts.outfit(fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showLanguageDialog(context, settings),
            ),
            const Divider(),
            _buildSectionHeader('About'),
            ListTile(
              title: Text('Version', style: GoogleFonts.outfit(fontWeight: FontWeight.w500)),
              trailing: Text('1.0.0', style: GoogleFonts.outfit(color: Colors.grey)),
            ),
            ListTile(
              title: Text('Privacy Policy', style: GoogleFonts.outfit(fontWeight: FontWeight.w500)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
            ListTile(
              title: Text('Terms of Service', style: GoogleFonts.outfit(fontWeight: FontWeight.w500)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[500],
          letterSpacing: 1,
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Language', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption(context, settings, 'English', 'en'),
            _buildLanguageOption(context, settings, 'Hindi', 'hi'),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(BuildContext context, SettingsProvider settings, String name, String code) {
    final isSelected = settings.locale.languageCode == code;
    return ListTile(
      title: Text(name, style: GoogleFonts.outfit(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: isSelected ? Icon(Icons.check_circle, color: Colors.green[800]) : null,
      onTap: () {
        settings.setLocale(code);
        Navigator.pop(context);
      },
    );
  }
}
