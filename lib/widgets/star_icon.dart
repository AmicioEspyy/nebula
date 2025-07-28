import 'package:flutter/material.dart';
import 'dart:math' as math;

class StarIcon extends StatelessWidget {
  final double size;
  final Color color;
  
  const StarIcon({
    super.key,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: StarPainter(color: color),
    );
  }
}

class StarPainter extends CustomPainter {
  final Color color;
  
  StarPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width * 0.4;
    final innerRadius = size.width * 0.15;
    
    path.moveTo(centerX, centerY - radius); // Punta in alto
    
    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * (math.pi / 180); // Converti in radianti
      final currentRadius = i.isEven ? radius : innerRadius;
      
      final x = centerX + currentRadius * math.sin(angle);
      final y = centerY - currentRadius * math.cos(angle);
      
      path.lineTo(x, y);
    }
    
    path.close();
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
