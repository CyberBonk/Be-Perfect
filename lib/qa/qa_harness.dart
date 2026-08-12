import 'package:flutter/material.dart';

class QaHarness extends StatefulWidget {
  const QaHarness({super.key, required this.child});

  final Widget child;

  @override
  State<QaHarness> createState() => _QaHarnessState();
}

class _QaHarnessState extends State<QaHarness> {
  Offset? _lastTap;
  int _tapCount = 0;
  bool _enabled = true;

  void _recordTap(PointerDownEvent event) {
    if (!_enabled) return;
    setState(() {
      _lastTap = event.position;
      _tapCount++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.maybeOf(context)?.padding.top ?? 0;

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _recordTap,
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.topLeft,
        children: [
          widget.child,
          IgnorePointer(
            child: CustomPaint(
              painter: _CrosshairPainter(position: _enabled ? _lastTap : null),
            ),
          ),
          Positioned(
            top: topPadding + 8,
            right: 8,
            child: Material(
              color:
                  Theme.of(context).colorScheme.surface.withValues(alpha: .94),
              elevation: 4,
              borderRadius: BorderRadius.circular(14),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        _enabled ? Icons.gps_fixed : Icons.gps_off,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _enabled = !_enabled),
                    ),
                    if (_enabled && _lastTap != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          'Tap $_tapCount  ${_lastTap!.dx.round()}, ${_lastTap!.dy.round()}',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                    if (_lastTap != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () => setState(() {
                          _lastTap = null;
                          _tapCount = 0;
                        }),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CrosshairPainter extends CustomPainter {
  const _CrosshairPainter({required this.position});

  final Offset? position;

  @override
  void paint(Canvas canvas, Size size) {
    final point = position;
    if (point == null) return;

    final paint = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(point, 18, paint);
    canvas.drawLine(point.translate(-34, 0), point.translate(34, 0), paint);
    canvas.drawLine(point.translate(0, -34), point.translate(0, 34), paint);
    canvas.drawCircle(
      point,
      3,
      Paint()
        ..color = Colors.redAccent
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_CrosshairPainter oldDelegate) =>
      oldDelegate.position != position;
}
