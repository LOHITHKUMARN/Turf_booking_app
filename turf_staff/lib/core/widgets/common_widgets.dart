import 'package:flutter/material.dart';

class FieldLinesPainter extends CustomPainter {
  final double opacity;

  FieldLinesPainter({this.opacity = 0.05});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Subtle curved lines
    final path1 = Path();
    path1.moveTo(0, size.height * 0.3);
    path1.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.45,
      size.width,
      size.height * 0.25,
    );

    final path2 = Path();
    path2.moveTo(0, size.height * 0.5);
    path2.quadraticBezierTo(
      size.width * 0.4,
      size.height * 0.65,
      size.width,
      size.height * 0.55,
    );

    final path3 = Path();
    path3.moveTo(0, size.height * 0.7);
    path3.quadraticBezierTo(
      size.width * 0.6,
      size.height * 0.8,
      size.width,
      size.height * 0.75,
    );
    
    final path4 = Path();
    path4.moveTo(size.width * 0.2, 0);
    path4.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.5,
      size.width * 0.8,
      size.height,
    );

    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);
    canvas.drawPath(path3, paint);
    canvas.drawPath(path4, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PressableScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;

  const PressableScaleButton({
    super.key,
    required this.child,
    this.onPressed,
  });

  @override
  State<PressableScaleButton> createState() => _PressableScaleButtonState();
}

class _PressableScaleButtonState extends State<PressableScaleButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed == null ? null : (_) => setState(() => _isPressed = true),
      onTapUp: widget.onPressed == null ? null : (_) {
        setState(() => _isPressed = false);
        widget.onPressed!();
      },
      onTapCancel: widget.onPressed == null ? null : () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: widget.child,
      ),
    );
  }
}
