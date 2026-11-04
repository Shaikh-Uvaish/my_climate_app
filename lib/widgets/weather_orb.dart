import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'weather_style.dart';

/// The hero of the app: a lit sphere that floats, with a tilted ring
/// orbiting it. Drag to spin it; it eases back when released.
class WeatherOrb extends StatefulWidget {
  final WeatherStyle style;
  final double size;

  const WeatherOrb({super.key, required this.style, this.size = 200});

  @override
  State<WeatherOrb> createState() => _WeatherOrbState();
}

class _WeatherOrbState extends State<WeatherOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  double _dragX = 0; // rotation around X from user drag
  double _dragY = 0; // rotation around Y from user drag
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final reduce = MediaQuery.of(context).disableAnimations;

    return GestureDetector(
      onPanStart: (_) => setState(() => _dragging = true),
      onPanUpdate: (d) => setState(() {
        _dragY += d.delta.dx * 0.012;
        _dragX -= d.delta.dy * 0.012;
        _dragX = _dragX.clamp(-0.8, 0.8);
      }),
      onPanEnd: (_) => setState(() {
        _dragging = false;
        _dragX = 0;
        _dragY = 0;
      }),
      child: TweenAnimationBuilder<Offset>(
        tween: Tween(begin: Offset.zero, end: Offset(_dragX, _dragY)),
        duration: _dragging
            ? const Duration(milliseconds: 60)
            : const Duration(milliseconds: 700),
        curve: _dragging ? Curves.linear : Curves.elasticOut,
        builder: (context, drag, _) {
          return AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              final t = reduce ? 0.0 : _ctrl.value * 2 * math.pi;
              final bob = math.sin(t) * 10;
              final sway = math.sin(t) * 0.18;

              return SizedBox(
                width: s * 1.5,
                height: s * 1.35,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Ground shadow shrinks as the orb rises.
                    Positioned(
                      bottom: 0,
                      child: Container(
                        width: s * (0.62 - bob.abs() * 0.004 + (bob < 0 ? -0.04 : 0)),
                        height: s * 0.09,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.30),
                              blurRadius: 26,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Transform.translate(
                      offset: Offset(0, -bob - 8),
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.0011)
                          ..rotateX(drag.dx - 0.12)
                          ..rotateY(drag.dy + sway),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            _ring(s, t, back: true),
                            _sphere(s),
                            _ring(s, t, back: false),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _sphere(double s) {
    final st = widget.style;
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.45, -0.55),
          radius: 1.05,
          colors: [
            Colors.white.withOpacity(0.95),
            st.accent,
            st.accentDeep,
            Color.lerp(st.accentDeep, Colors.black, 0.55)!,
          ],
          stops: const [0.0, 0.28, 0.72, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: st.accentDeep.withOpacity(0.55),
            blurRadius: 60,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Specular highlight.
          Positioned(
            top: s * 0.12,
            left: s * 0.20,
            child: Container(
              width: s * 0.26,
              height: s * 0.15,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                color: Colors.white.withOpacity(0.45),
              ),
            ),
          ),
          Icon(
            st.icon,
            size: s * 0.46,
            color: Color.lerp(st.accentDeep, Colors.black, 0.45),
          ),
        ],
      ),
    );
  }

  /// Tilted ring. The back half is drawn behind the sphere, the front half
  /// in front, which sells the depth. Clipping happens in screen space
  /// (outside the tilt) so the split always lines up with the sphere.
  Widget _ring(double s, double t, {required bool back}) {
    final ringW = s * 1.42;
    return IgnorePointer(
      child: SizedBox(
        width: ringW,
        height: ringW,
        child: ClipRect(
          clipper: _HalfClipper(top: back),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX(1.2),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(back ? 0.30 : 0.75),
                  width: 3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HalfClipper extends CustomClipper<Rect> {
  final bool top;
  const _HalfClipper({required this.top});

  @override
  Rect getClip(Size size) => top
      ? Rect.fromLTWH(0, 0, size.width, size.height / 2)
      : Rect.fromLTWH(0, size.height / 2, size.width, size.height / 2);

  @override
  bool shouldReclip(covariant _HalfClipper old) => old.top != top;
}