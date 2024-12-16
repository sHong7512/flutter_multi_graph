import 'package:flutter/material.dart';

import '../auto_mixin.dart';

// 범례 페인터
class LegendTextPainter extends CustomPainter with AutoMixin {
  LegendTextPainter({required this.text, required this.style, required this.parentSize}){
    paddingSize = Size(parentSize.width / 10, parentSize.height / 10);
    innerSize = Size(
      parentSize.width - paddingSize.width * 2,
      parentSize.height - paddingSize.height * 2,
    );
  }

  final String text;
  final TextStyle style;
  final Size parentSize;

  late final Size paddingSize;
  late final Size innerSize;

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = autoTextPainter(text, innerSize, style, null);
    textPainter.paint(
      canvas,
      Offset(
        innerSize.width / 2 - textPainter.width / 2,
        innerSize.height / 2 - textPainter.height / 2 + paddingSize.height,
      ),
    );
  }

  @override
  bool shouldRepaint(LegendTextPainter oldDelegate) =>
      oldDelegate.text != text ||
      oldDelegate.style != style ||
      oldDelegate.parentSize != parentSize;
}
