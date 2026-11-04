import 'dart:ui';

import 'package:flutter/material.dart';

/// Frosted-glass surface.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final double opacity;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 24,
    this.opacity = 0.14,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(opacity + 0.08),
                Colors.white.withOpacity(opacity - 0.06),
              ],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.22)),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Wraps a child in a perspective tilt that follows a finger drag or
/// mouse hover, then springs back to rest.
class Tilt3D extends StatefulWidget {
  final Widget child;
  final double maxAngle;
  final double lift;

  const Tilt3D({
    super.key,
    required this.child,
    this.maxAngle = 0.28,
    this.lift = 10,
  });

  @override
  State<Tilt3D> createState() => _Tilt3DState();
}

class _Tilt3DState extends State<Tilt3D> {
  double _rx = 0;
  double _ry = 0;
  bool _active = false;

  void _update(Offset local) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final size = box.size;
    final dx = (local.dx / size.width - 0.5) * 2; // -1..1
    final dy = (local.dy / size.height - 0.5) * 2;
    setState(() {
      _active = true;
      _ry = (dx * widget.maxAngle).clamp(-widget.maxAngle, widget.maxAngle);
      _rx = (-dy * widget.maxAngle).clamp(-widget.maxAngle, widget.maxAngle);
    });
  }

  void _reset() {
    setState(() {
      _active = false;
      _rx = 0;
      _ry = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final matrix = Matrix4.identity()
      ..setEntry(3, 2, 0.0014)
      ..rotateX(_rx)
      ..rotateY(_ry)
      ..translate(0.0, _active ? -widget.lift * 0.4 : 0.0, _active ? widget.lift : 0.0);

    return MouseRegion(
      onHover: (e) => _update(e.localPosition),
      onExit: (_) => _reset(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (d) => _update(d.localPosition),
        onPanUpdate: (d) => _update(d.localPosition),
        onPanEnd: (_) => _reset(),
        onPanCancel: _reset,
        onTapDown: (d) => _update(d.localPosition),
        onTapUp: (_) => _reset(),
        onTapCancel: _reset,
        child: AnimatedContainer(
          duration: _active
              ? const Duration(milliseconds: 90)
              : const Duration(milliseconds: 500),
          curve: _active ? Curves.easeOut : Curves.elasticOut,
          transformAlignment: Alignment.center,
          transform: matrix,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_active ? 0.35 : 0.18),
                blurRadius: _active ? 34 : 20,
                offset: Offset(-_ry * 40, 14 + _rx * 30),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}