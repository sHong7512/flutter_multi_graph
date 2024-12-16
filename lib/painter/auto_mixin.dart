import 'package:flutter/material.dart';

mixin AutoMixin {
  TextPainter autoTextPainter(
      String text, Size parentSize, TextStyle style, TextPainter? fixedTextPainter) {
    var textPainter = fixedTextPainter ??
        TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        )
      ..layout();

    if (textPainter.size.height >= parentSize.height ||
        textPainter.size.width >= parentSize.width) {
      double max = style.fontSize ?? 40;
      double min = 1;
      double mid;
      while (true) {
        if ((max - min) < 1) {
          return TextPainter(
            text: TextSpan(text: text, style: style.copyWith(fontSize: min)),
            textDirection: TextDirection.ltr,
          )..layout();
        }
        mid = (min + max) / 2;
        textPainter = TextPainter(
          text: TextSpan(text: text, style: style.copyWith(fontSize: mid)),
          textDirection: TextDirection.ltr,
        )..layout();

        if (textPainter.size.height <= parentSize.height &&
            textPainter.size.width <= parentSize.width) {
          min = mid;
        } else {
          max = mid;
        }
      }
    }

    return textPainter;
  }
}
