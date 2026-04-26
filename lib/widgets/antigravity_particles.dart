import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class AntigravityParticles extends StatefulWidget {
  final Widget? child;
  const AntigravityParticles({super.key, this.child});

  @override
  State<AntigravityParticles> createState() => _AntigravityParticlesState();
}

class _AntigravityParticlesState extends State<AntigravityParticles>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  Offset _mousePos = const Offset(-1000, -1000);
  final List<Particle> _particles = [];
  final int _particleCount = 200;
  Size _lastSize = Size.zero;

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

  void _initParticles(Size size) {
    // Fallback if height is infinite (e.g., inside a Column)
    final actualHeight = size.height.isInfinite ? 800.0 : size.height;
    final actualSize = Size(size.width, actualHeight);
    
    if (actualSize == _lastSize && _particles.isNotEmpty) return;
    _lastSize = actualSize;
    _particles.clear();
    final random = math.Random();
    for (int i = 0; i < _particleCount; i++) {
      _particles.add(Particle(
        pos: Offset(random.nextDouble() * actualSize.width,
            random.nextDouble() * actualSize.height),
        velocity: Offset(random.nextDouble() * 2 - 1, random.nextDouble() * 2 - 1),
        angle: random.nextDouble() * math.pi * 2,
        color: Colors.white.withValues(alpha: 0.1 + random.nextDouble() * 0.2),
        speed: 1.0 + random.nextDouble() * 2.0,
      ));
    }
  }

  void _update(Duration elapsed) {
    if (_lastSize == Size.zero) return;
    setState(() {
      for (var p in _particles) {
        p.update(_mousePos, _lastSize);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _initParticles(constraints.biggest);
        final paintSize = Size(
          constraints.biggest.width,
          constraints.biggest.height.isInfinite ? _lastSize.height : constraints.biggest.height,
        );
        return MouseRegion(
          onHover: (event) => _mousePos = event.localPosition,
          onExit: (event) => _mousePos = const Offset(-1000, -1000),
          child: Stack(
            children: [
              CustomPaint(
                size: paintSize,
                painter: ParticlePainter(particles: _particles),
              ),
              if (widget.child != null) widget.child!,
            ],
          ),
        );
      },
    );
  }
}

class Particle {
  Offset pos;
  Offset velocity;
  double angle;
  final Color color;
  final double speed;
  double _noiseOffset = 0;

  Particle({
    required this.pos,
    required this.velocity,
    required this.angle,
    required this.color,
    required this.speed,
  }) {
    _noiseOffset = math.Random().nextDouble() * 1000;
  }

  void update(Offset mousePos, Size size) {
    _noiseOffset += 0.01;
    final diff = mousePos - pos;
    final distance = diff.distance;
    
    Offset acceleration = Offset.zero;

    // Schooling / Antigravity behavior
    const minDistance = 140.0;
    const maxInfluence = 700.0;

    if (distance < minDistance) {
      // Repulsion
      final force = (1.0 - distance / minDistance) * 4.0;
      acceleration -= (diff / distance) * force;
    } else if (distance < maxInfluence) {
      // Attraction
      final force = ((distance - minDistance) / (maxInfluence - minDistance)) * 0.5;
      acceleration += (diff / distance) * force;
    }

    // Organic sway
    acceleration += Offset(
      math.cos(_noiseOffset) * 0.15,
      math.sin(_noiseOffset * 1.3) * 0.15,
    );

    velocity += acceleration;

    // Speed limits
    final currentSpeed = velocity.distance;
    final limit = speed + 1.5;
    if (currentSpeed > limit) {
      velocity = (velocity / currentSpeed) * limit;
    }

    // Friction
    velocity *= 0.95;

    // Apply motion
    pos += velocity;

    // Smooth angle update
    if (velocity.distance > 0.1) {
      final targetAngle = math.atan2(velocity.dy, velocity.dx);
      double diff = targetAngle - angle;
      while (diff > math.pi) {
        diff -= 2 * math.pi;
      }
      while (diff < -math.pi) {
        diff += 2 * math.pi;
      }
      angle += diff * 0.12;
    }

    // Screen wrapping
    if (pos.dx < -50) pos = Offset(size.width + 40, pos.dy);
    if (pos.dx > size.width + 50) pos = Offset(-40, pos.dy);
    if (pos.dy < -50) pos = Offset(pos.dx, size.height + 40);
    if (pos.dy > size.height + 50) pos = Offset(pos.dx, -40);
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  ParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var p in particles) {
      paint.color = p.color;
      canvas.save();
      canvas.translate(p.pos.dx, p.pos.dy);
      canvas.rotate(p.angle);
      // Rectangle 2x7px
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-3.5, -1, 7, 2),
          const Radius.circular(0.5),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) => true;
}
