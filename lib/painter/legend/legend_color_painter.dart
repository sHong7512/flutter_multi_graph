import 'package:flutter/material.dart';

import '../auto_mixin.dart';

// 범례 페인터
class LegendColorPainter extends CustomPainter with AutoMixin {
  LegendColorPainter({required this.parentSize, required this.valueColor}) {
    paddingSize = Size(parentSize.width / 5, parentSize.height / 5);
    innerSize = Size(
      parentSize.width - paddingSize.width * 2,
      parentSize.height - paddingSize.height * 2,
    );
  }

  final Size parentSize;
  final Color valueColor;

  late final Size paddingSize;
  late final Size innerSize;

  @override
  void paint(Canvas canvas, Size size) {
    drawLineColor(canvas);
  }

  drawLineColor(Canvas canvas) {
    final paint = Paint()
      ..color = valueColor
      ..strokeWidth = innerSize.height
      ..style = PaintingStyle.fill;

    final start = Offset(paddingSize.width, innerSize.height / 2 + paddingSize.height);
    final end =
        Offset(innerSize.width + paddingSize.width, innerSize.height / 2 + paddingSize.height);
    canvas.drawLine(start, end, paint);
  }

  @override
  bool shouldRepaint(LegendColorPainter oldDelegate) =>
      oldDelegate.parentSize != parentSize || oldDelegate.valueColor != valueColor;
}
