import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class RadialParticles extends StatefulWidget {
  final Animation<Color?> colorAnimation;
  final double maxRadius;

  const RadialParticles({
    super.key,
    required this.colorAnimation,
    required this.maxRadius,
  });

  @override
  State<RadialParticles> createState() => _RadialParticlesState();
}

class _RadialParticlesState extends State<RadialParticles>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final List<_StreamParticle> _particles = [];
  final int _maxParticles = 150;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_update);
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _update(Duration elapsed) {
    setState(() {
      // Spawn new particles
      if (_particles.length < _maxParticles && _random.nextDouble() < 0.3) {
        final angle = _random.nextDouble() * 2 * math.pi;
        final speed = 1.0 + _random.nextDouble() * 2.0;
        final length = 10.0 + _random.nextDouble() * 30.0;
        
        // Spawn slightly offset from absolute center
        final spawnRadius = _random.nextDouble() * 20.0;

        _particles.add(_StreamParticle(
          pos: Offset(math.cos(angle) * spawnRadius, math.sin(angle) * spawnRadius),
          velocity: Offset(math.cos(angle) * speed, math.sin(angle) * speed),
          angle: angle,
          length: length,
          maxLife: 100.0 + _random.nextDouble() * 150.0,
          colorOffset: _random.nextDouble(),
        ));
      }

      // Update existing particles
      for (int i = _particles.length - 1; i >= 0; i--) {
        final p = _particles[i];
        p.pos += p.velocity;
        p.life += 1.0;

        // Remove if too far or out of life
        if (p.life > p.maxLife || p.pos.distance > widget.maxRadius) {
          _particles.removeAt(i);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.colorAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _RadialParticlePainter(
            particles: _particles,
            baseColor: widget.colorAnimation.value ?? Colors.deepPurple,
            maxRadius: widget.maxRadius,
          ),
        );
      },
    );
  }
}

class _StreamParticle {
  Offset pos;
  Offset velocity;
  double angle;
  double length;
  double life = 0.0;
  double maxLife;
  double colorOffset;

  _StreamParticle({
    required this.pos,
    required this.velocity,
    required this.angle,
    required this.length,
    required this.maxLife,
    required this.colorOffset,
  });
}

class _RadialParticlePainter extends CustomPainter {
  final List<_StreamParticle> particles;
  final Color baseColor;
  final double maxRadius;

  _RadialParticlePainter({
    required this.particles,
    required this.baseColor,
    required this.maxRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // We can extract HSL from baseColor to vary it slightly based on colorOffset
    final hsl = HSLColor.fromColor(baseColor);

    for (var p in particles) {
      // Calculate opacity based on life and distance
      final distanceFade = 1.0 - (p.pos.distance / maxRadius).clamp(0.0, 1.0);
      final lifeFade = math.sin((p.life / p.maxLife) * math.pi); // Fade in and out
      final opacity = (distanceFade * lifeFade).clamp(0.0, 1.0);

      if (opacity <= 0.01) continue;

      // Slightly shift hue and lightness for variety among particles
      final pColor = hsl.withHue((hsl.hue + (p.colorOffset * 40 - 20)) % 360)
                       .withLightness((hsl.lightness + (p.colorOffset * 0.2 - 0.1)).clamp(0.0, 1.0))
                       .toColor()
                       .withValues(alpha: opacity * 0.7);

      paint.color = pColor;
      paint.strokeWidth = 1.5 + p.colorOffset;

      canvas.save();
      canvas.translate(center.dx + p.pos.dx, center.dy + p.pos.dy);
      canvas.rotate(p.angle);
      
      // Draw elongated particle (line)
      canvas.drawLine(Offset.zero, Offset(p.length, 0), paint);
      
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _RadialParticlePainter oldDelegate) => true;
}
