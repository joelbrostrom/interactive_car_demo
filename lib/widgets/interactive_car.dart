import 'package:flutter/material.dart';

class CarStatus {
  final bool frontLeftDoor;
  final bool frontRightDoor;
  final bool rearLeftDoor;
  final bool rearRightDoor;
  final bool trunk;
  final bool hood;
  final bool lights;
  final bool wipers;

  const CarStatus({
    this.frontLeftDoor = false,
    this.frontRightDoor = false,
    this.rearLeftDoor = false,
    this.rearRightDoor = false,
    this.trunk = false,
    this.hood = false,
    this.lights = false,
    this.wipers = false,
  });

  factory CarStatus.fromJson(Map<String, dynamic> json) {
    return CarStatus(
      frontLeftDoor: json['front_left_door'] ?? false,
      frontRightDoor: json['front_right_door'] ?? false,
      rearLeftDoor: json['rear_left_door'] ?? false,
      rearRightDoor: json['rear_right_door'] ?? false,
      trunk: json['trunk'] ?? false,
      hood: json['hood'] ?? false,
      lights: json['lights'] ?? false,
      wipers: json['wipers'] ?? false,
    );
  }
}

enum CarPart {
  frontLeftDoor,
  frontRightDoor,
  rearLeftDoor,
  rearRightDoor,
  trunk,
  hood,
  lights,
  wipers,
}

class InteractiveCar extends StatelessWidget {
  final CarStatus status;
  final Function(CarPart) onPartTapped;

  const InteractiveCar({
    super.key,
    required this.status,
    required this.onPartTapped,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final carWidth = constraints.maxWidth.clamp(300.0, 500.0);
        final carHeight = carWidth * 2.2;

        return Center(
          child: SizedBox(
            width: carWidth,
            height: carHeight,
            child: Stack(
              children: [
                CustomPaint(
                  size: Size(carWidth, carHeight),
                  painter: CarPainter(status: status),
                ),
                // Hood zone (top)
                _buildTappableZone(
                  left: carWidth * 0.20,
                  top: carHeight * 0.04,
                  width: carWidth * 0.60,
                  height: carHeight * 0.05,
                  part: CarPart.hood,
                  isActive: status.hood,
                  label: 'Hood',
                ),
                // Lights zone (headlights)
                _buildTappableZone(
                  left: carWidth * 0.20,
                  top: carHeight * 0.09,
                  width: carWidth * 0.60,
                  height: carHeight * 0.030,
                  part: CarPart.lights,
                  isActive: status.lights,
                  label: 'Lights',
                ),
                // Wipers zone (windshield area)
                _buildTappableZone(
                  left: carWidth * 0.24,
                  top: carHeight * 0.12,
                  width: carWidth * 0.52,
                  height: carHeight * 0.06,
                  part: CarPart.wipers,
                  isActive: status.wipers,
                  label: 'Wipers',
                ),
                // Front left door (aligned with front wheel at 0.28)
                _buildTappableZone(
                  left: carWidth * 0.01,
                  top: carHeight * 0.18,
                  width: carWidth * 0.13,
                  height: carHeight * 0.10,
                  part: CarPart.frontLeftDoor,
                  isActive: status.frontLeftDoor,
                  label: 'FL',
                ),
                // Front right door
                _buildTappableZone(
                  left: carWidth * 0.86,
                  top: carHeight * 0.18,
                  width: carWidth * 0.13,
                  height: carHeight * 0.10,
                  part: CarPart.frontRightDoor,
                  isActive: status.frontRightDoor,
                  label: 'FR',
                ),
                // Rear left door (next to rear wheel)
                _buildTappableZone(
                  left: carWidth * 0.01,
                  top: carHeight * 0.28,
                  width: carWidth * 0.13,
                  height: carHeight * 0.10,
                  part: CarPart.rearLeftDoor,
                  isActive: status.rearLeftDoor,
                  label: 'RL',
                ),
                // Rear right door
                _buildTappableZone(
                  left: carWidth * 0.86,
                  top: carHeight * 0.28,
                  width: carWidth * 0.13,
                  height: carHeight * 0.10,
                  part: CarPart.rearRightDoor,
                  isActive: status.rearRightDoor,
                  label: 'RR',
                ),
                // Trunk zone (bottom)
                _buildTappableZone(
                  left: carWidth * 0.22,
                  top: carHeight * 0.40,
                  width: carWidth * 0.56,
                  height: carHeight * 0.12,
                  part: CarPart.trunk,
                  isActive: status.trunk,
                  label: 'Trunk',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTappableZone({
    required double left,
    required double top,
    required double width,
    required double height,
    required CarPart part,
    required bool isActive,
    required String label,
  }) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: GestureDetector(
        onTap: () => onPartTapped(part),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient:
                isActive
                    ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFFFAB00).withValues(alpha: 0.4),
                        const Color(0xFFFF6D00).withValues(alpha: 0.3),
                      ],
                    )
                    : null,
            color:
                isActive
                    ? null
                    : const Color(0xFF00E5FF).withValues(alpha: 0.05),
            border: Border.all(
              color:
                  isActive
                      ? const Color(0xFFFFAB00)
                      : const Color(0xFF00E5FF).withValues(alpha: 0.3),
              width: isActive ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow:
                isActive
                    ? [
                      BoxShadow(
                        color: const Color(0xFFFFAB00).withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                    ]
                    : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color:
                    isActive
                        ? const Color(0xFFFFAB00)
                        : const Color(0xFF00E5FF).withValues(alpha: 0.7),
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CarPainter extends CustomPainter {
  final CarStatus status;

  CarPainter({required this.status});

  @override
  void paint(Canvas canvas, Size size) {
    final bodyPaint =
        Paint()
          ..color = const Color(0xFF2D3748)
          ..style = PaintingStyle.fill;

    final outlinePaint =
        Paint()
          ..color = const Color(0xFF00E5FF).withAlpha(100)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

    final windowPaint =
        Paint()
          ..color = const Color(0xFF1A365D)
          ..style = PaintingStyle.fill;

    final wheelPaint =
        Paint()
          ..color = const Color(0xFF1A1A2E)
          ..style = PaintingStyle.fill;

    final lightOnPaint =
        Paint()
          ..color = const Color(0xFFFFAB00)
          ..style = PaintingStyle.fill;

    final lightOffPaint =
        Paint()
          ..color = const Color(0xFF4A5568)
          ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Car body (top-down view)
    final bodyPath = Path();
    bodyPath.moveTo(w * 0.2, h * 0.05);
    bodyPath.quadraticBezierTo(w * 0.5, h * 0.02, w * 0.8, h * 0.05);
    bodyPath.lineTo(w * 0.85, h * 0.2);
    bodyPath.lineTo(w * 0.85, h * 0.8);
    bodyPath.quadraticBezierTo(w * 0.5, h * 0.98, w * 0.15, h * 0.8);
    bodyPath.lineTo(w * 0.15, h * 0.2);
    bodyPath.close();

    canvas.drawPath(bodyPath, bodyPaint);
    canvas.drawPath(bodyPath, outlinePaint);

    // Hood area
    final hoodPath = Path();
    hoodPath.moveTo(w * 0.22, h * 0.08);
    hoodPath.quadraticBezierTo(w * 0.5, h * 0.05, w * 0.78, h * 0.08);
    hoodPath.lineTo(w * 0.8, h * 0.18);
    hoodPath.lineTo(w * 0.2, h * 0.18);
    hoodPath.close();

    canvas.drawPath(hoodPath, Paint()..color = const Color(0xFF3D4A5C));
    canvas.drawPath(hoodPath, outlinePaint..strokeWidth = 1);

    // Windshield
    final windshieldPath = Path();
    windshieldPath.moveTo(w * 0.22, h * 0.22);
    windshieldPath.lineTo(w * 0.78, h * 0.22);
    windshieldPath.lineTo(w * 0.75, h * 0.32);
    windshieldPath.lineTo(w * 0.25, h * 0.32);
    windshieldPath.close();
    canvas.drawPath(windshieldPath, windowPaint);

    // Wipers (if on)
    if (status.wipers) {
      final wiperPaint =
          Paint()
            ..color = Colors.black
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2;
      canvas.drawLine(
        Offset(w * 0.35, h * 0.30),
        Offset(w * 0.5, h * 0.24),
        wiperPaint,
      );
      canvas.drawLine(
        Offset(w * 0.65, h * 0.30),
        Offset(w * 0.5, h * 0.24),
        wiperPaint,
      );
    }

    // Roof / interior
    final roofPath = Path();
    roofPath.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.25, h * 0.35, w * 0.5, h * 0.3),
        const Radius.circular(8),
      ),
    );
    canvas.drawPath(roofPath, Paint()..color = const Color(0xFF252D3A));

    // Rear window
    final rearWindowPath = Path();
    rearWindowPath.moveTo(w * 0.25, h * 0.68);
    rearWindowPath.lineTo(w * 0.75, h * 0.68);
    rearWindowPath.lineTo(w * 0.78, h * 0.78);
    rearWindowPath.lineTo(w * 0.22, h * 0.78);
    rearWindowPath.close();
    canvas.drawPath(rearWindowPath, windowPaint);

    // Trunk area
    final trunkPath = Path();
    trunkPath.moveTo(w * 0.2, h * 0.82);
    trunkPath.lineTo(w * 0.8, h * 0.82);
    trunkPath.quadraticBezierTo(w * 0.5, h * 0.95, w * 0.2, h * 0.82);
    canvas.drawPath(trunkPath, Paint()..color = const Color(0xFF3D4A5C));

    // Headlights
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.25, h * 0.19),
        width: w * 0.12,
        height: h * 0.03,
      ),
      status.lights ? lightOnPaint : lightOffPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.75, h * 0.19),
        width: w * 0.12,
        height: h * 0.03,
      ),
      status.lights ? lightOnPaint : lightOffPaint,
    );

    // Tail lights
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.22, h * 0.82),
        width: w * 0.08,
        height: h * 0.025,
      ),
      status.lights ? (Paint()..color = Colors.red) : lightOffPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.78, h * 0.82),
        width: w * 0.08,
        height: h * 0.025,
      ),
      status.lights ? (Paint()..color = Colors.red) : lightOffPaint,
    );

    // Wheels
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.1, h * 0.28),
        width: w * 0.12,
        height: h * 0.08,
      ),
      wheelPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.9, h * 0.28),
        width: w * 0.12,
        height: h * 0.08,
      ),
      wheelPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.1, h * 0.72),
        width: w * 0.12,
        height: h * 0.08,
      ),
      wheelPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.9, h * 0.72),
        width: w * 0.12,
        height: h * 0.08,
      ),
      wheelPaint,
    );

    // Door indicators when open
    if (status.frontLeftDoor) {
      _drawOpenDoor(canvas, Offset(w * 0.00, h * 0.35), -0.3, w * 0.15);
    }
    if (status.frontRightDoor) {
      _drawOpenDoor(canvas, Offset(w * 0.85, h * 0.32), 0.3, w * 0.15);
    }
    if (status.rearLeftDoor) {
      _drawOpenDoor(canvas, Offset(w * 0.00, h * 0.60), -0.3, w * 0.15);
    }
    if (status.rearRightDoor) {
      _drawOpenDoor(canvas, Offset(w * 0.85, h * 0.58), 0.3, w * 0.15);
    }
    if (status.hood) {
      _drawOpenHood(canvas, w, h);
    }
    if (status.trunk) {
      _drawOpenTrunk(canvas, w, h);
    }
  }

  void _drawOpenDoor(Canvas canvas, Offset pivot, double angle, double length) {
    final doorPaint =
        Paint()
          ..color = const Color(0xFF2D3748)
          ..style = PaintingStyle.fill;
    final doorOutline =
        Paint()
          ..color = const Color(0xFFFFAB00)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
    final doorGlow =
        Paint()
          ..color = const Color(0xFFFFAB00).withAlpha(50)
          ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(angle);

    final doorRect = Rect.fromLTWH(0, 0, length, length * 0.8);
    canvas.drawRect(doorRect.inflate(3), doorGlow);
    canvas.drawRect(doorRect, doorPaint);
    canvas.drawRect(doorRect, doorOutline);

    canvas.restore();
  }

  void _drawOpenHood(Canvas canvas, double w, double h) {
    final hoodPaint =
        Paint()
          ..color = const Color(0xFFFFAB00).withAlpha(80)
          ..style = PaintingStyle.fill;
    final hoodOutline =
        Paint()
          ..color = const Color(0xFFFFAB00)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

    final path = Path();
    path.moveTo(w * 0.2, h * 0.02);
    path.lineTo(w * 0.8, h * 0.02);
    path.lineTo(w * 0.5, h * -0.08);
    path.close();

    canvas.drawPath(path, hoodPaint);
    canvas.drawPath(path, hoodOutline);
  }

  void _drawOpenTrunk(Canvas canvas, double w, double h) {
    final trunkPaint =
        Paint()
          ..color = const Color(0xFFFFAB00).withAlpha(80)
          ..style = PaintingStyle.fill;
    final trunkOutline =
        Paint()
          ..color = const Color(0xFFFFAB00)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

    final path = Path();
    path.moveTo(w * 0.2, h * 0.95);
    path.lineTo(w * 0.8, h * 0.95);
    path.lineTo(w * 0.5, h * 1.05);
    path.close();

    canvas.drawPath(path, trunkPaint);
    canvas.drawPath(path, trunkOutline);
  }

  @override
  bool shouldRepaint(covariant CarPainter oldDelegate) {
    return oldDelegate.status != status;
  }
}
