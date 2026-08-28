import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class TurfTypeBadge extends StatelessWidget {
  final String type;
  final bool showLabel;

  const TurfTypeBadge({
    super.key,
    required this.type,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedType = type.toLowerCase();
    
    Color baseColor;
    IconData icon;
    String label;
    List<Color> gradientColors;

    switch (normalizedType) {
      case 'indoor':
        baseColor = Colors.blueAccent;
        icon = Icons.roofing_rounded;
        label = 'INDOOR';
        gradientColors = [
          Colors.blue[700]!,
          Colors.blue[400]!,
        ];
        break;
      case 'outdoor':
        baseColor = Colors.orangeAccent;
        icon = Icons.wb_sunny_rounded;
        label = 'OUTDOOR';
        gradientColors = [
          Colors.orange[700]!,
          Colors.orange[400]!,
        ];
        break;
      default: // 'both'
        baseColor = Colors.purpleAccent;
        icon = Icons.layers_rounded;
        label = 'HYBRID';
        gradientColors = [
          Colors.purple[700]!,
          Colors.purple[400]!,
        ];
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                gradientColors[0].withOpacity(0.8),
                gradientColors[1].withOpacity(0.6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: baseColor.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: Colors.white,
              ),
              if (showLabel) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
