import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../controllers/dashboard_controller.dart';

class TrendChart extends StatelessWidget {
  const TrendChart({super.key, required this.months, required this.locale});

  final List<MonthlyTotals> months;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 200,
      child: CustomPaint(
        size: Size.infinite,
        painter: _TrendPainter(
          months: months,
          locale: locale,
          lineColor: scheme.primary,
          fillColor: scheme.primary,
          gridColor: scheme.outlineVariant.withValues(alpha: 0.5),
          labelColor: scheme.onSurfaceVariant,
          dotFillColor: scheme.surface,
        ),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.months,
    required this.locale,
    required this.lineColor,
    required this.fillColor,
    required this.gridColor,
    required this.labelColor,
    required this.dotFillColor,
  });

  final List<MonthlyTotals> months;
  final String locale;
  final Color lineColor;
  final Color fillColor;
  final Color gridColor;
  final Color labelColor;
  final Color dotFillColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (months.isEmpty) return;

    const labelArea = 26.0;
    const topPadding = 12.0;
    final chartHeight = size.height - labelArea - topPadding;
    final n = months.length;
    if (n < 1) return;

    final maxVal = months
        .map((m) => m.totalKhr)
        .fold<double>(0, (a, b) => a > b ? a : b);
    final effectiveMax = maxVal == 0 ? 1.0 : maxVal;

    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int i = 0; i <= 3; i++) {
      final y = topPadding + (chartHeight * i / 3);
      final path = Path()
        ..moveTo(0, y)
        ..lineTo(size.width, y);
      canvas.drawPath(_dashed(path), grid);
    }

    final slot = n == 1 ? size.width : size.width / (n - 1);
    final pts = <Offset>[];
    for (int i = 0; i < n; i++) {
      final ratio = months[i].totalKhr / effectiveMax;
      final x = n == 1 ? size.width / 2 : slot * i;
      final y = topPadding + chartHeight - (ratio * chartHeight);
      pts.add(Offset(x, y));
    }

    if (n >= 2) {
      final fillPath = Path()..moveTo(pts.first.dx, topPadding + chartHeight);
      _addSmoothPath(fillPath, pts);
      fillPath
        ..lineTo(pts.last.dx, topPadding + chartHeight)
        ..close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            fillColor.withValues(alpha: 0.28),
            fillColor.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawPath(fillPath, fillPaint);

      final linePath = Path()..moveTo(pts.first.dx, pts.first.dy);
      _addSmoothPath(linePath, pts);

      final linePaint = Paint()
        ..color = lineColor
        ..strokeWidth = 2.6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(linePath, linePaint);
    }

    final dotStroke = Paint()
      ..color = lineColor
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;
    final dotFill = Paint()
      ..color = dotFillColor
      ..style = PaintingStyle.fill;

    for (int i = 0; i < n; i++) {
      canvas.drawCircle(pts[i], 4.5, dotFill);
      canvas.drawCircle(pts[i], 4.5, dotStroke);
    }

    for (int i = 0; i < n; i++) {
      final label = DateFormat.MMM(locale).format(months[i].month);
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: labelColor,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 80);
      final cx = n == 1 ? size.width / 2 : slot * i;
      tp.paint(
        canvas,
        Offset(
          (cx - tp.width / 2).clamp(0, size.width - tp.width),
          topPadding + chartHeight + 8,
        ),
      );
    }
  }

  /// Catmull-Rom-ish smooth path through the given points.
  void _addSmoothPath(Path path, List<Offset> pts) {
    if (pts.length < 2) return;
    for (int i = 0; i < pts.length - 1; i++) {
      final p0 = i > 0 ? pts[i - 1] : pts[i];
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final p3 = i + 2 < pts.length ? pts[i + 2] : p2;
      final c1 = Offset(
        p1.dx + (p2.dx - p0.dx) / 6,
        p1.dy + (p2.dy - p0.dy) / 6,
      );
      final c2 = Offset(
        p2.dx - (p3.dx - p1.dx) / 6,
        p2.dy - (p3.dy - p1.dy) / 6,
      );
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
  }

  Path _dashed(Path source, {double dashWidth = 4, double dashSpace = 4}) {
    final result = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        result.addPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          Offset.zero,
        );
        distance = next + dashSpace;
      }
    }
    return result;
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) =>
      old.months != months ||
      old.locale != locale ||
      old.lineColor != lineColor;
}
