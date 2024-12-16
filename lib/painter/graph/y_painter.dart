import 'dart:math';

import 'package:flutter/material.dart';
import 'package:multi_graph/painter/auto_mixin.dart';

import '../../widget/multi_graph_widget.dart';

// 그래프 y축 및 외곽선 커스텀 패인터
class YPainter extends CustomPainter with AutoMixin {
  YPainter({
    required this.parentWidth,
    required this.parentHeight,
    required this.yAxisStrs,
    required this.yTextStyle,
    required this.yAxisMaxSize,
    required this.outLinePaint,
    required this.inLinePaint,
    required this.autoTextMapY,
  }) {
    _graphHeight = parentHeight / MultiGraphWidget.ratioAll * MultiGraphWidget.ratioXW;
    _yAxisWidth = parentWidth / MultiGraphWidget.ratioAll;
    _yAxisSize = Size(_yAxisWidth, _graphHeight / yAxisStrs.length);
    _addX = parentWidth / 100;
  }

  final double parentWidth;
  final double parentHeight;
  final List<String> yAxisStrs;
  final TextStyle yTextStyle;
  final Size yAxisMaxSize;
  final Paint outLinePaint;
  final Paint inLinePaint;
  final Map<String, TextPainter?> autoTextMapY;

  late final double _graphHeight;
  late final double _yAxisWidth;
  late final Size _yAxisSize;
  late final double _addX;

  @override
  void paint(Canvas canvas, Size size) {
    _drawXYOutLine(canvas);
    _drawYAxisWithDiv(canvas);
  }

  // y축 텍스트 및 분할 라인 그리기
  _drawYAxisWithDiv(Canvas canvas) {
    final squareSize = Size(
      min(_yAxisSize.width * 3 / 5, yAxisMaxSize.width),
      min(_yAxisSize.height * 3 / 5, yAxisMaxSize.height),
    );
    for (int i = 0; i < yAxisStrs.length; i++) {
      final reverse = yAxisStrs.length - 1 - i;
      final textPosition = Offset(0, _yAxisSize.height * reverse);
      final text = yAxisStrs[i];
      final textPainter = autoTextPainter(text, squareSize, yTextStyle, autoTextMapY[text]);
      if (autoTextMapY[text]?.size != textPainter.size) {
        autoTextMapY[text] = textPainter;
      }
      textPainter.paint(
        canvas,
        Offset(
          _yAxisSize.width / 2 - textPainter.width / 2,
          textPosition.dy + _yAxisSize.height - textPainter.height / 2,
        ),
      );
      // y단위 분할 라인. 0번 인덱스는 제외
      if (i != 0) {
        canvas.drawLine(
          Offset(_yAxisWidth, textPosition.dy + _yAxisSize.height),
          Offset(parentWidth, textPosition.dy + _yAxisSize.height),
          inLinePaint,
        );
      }
      // y단위 서브 라인
      canvas.drawLine(
        Offset(_yAxisWidth - _addX, textPosition.dy + _yAxisSize.height),
        Offset(_yAxisWidth, textPosition.dy + _yAxisSize.height),
        outLinePaint,
      );
    }
  }

  // 그래프 외부 라인 그리기
  _drawXYOutLine(Canvas canvas) {
    canvas.drawLine(Offset(_yAxisWidth, 0), Offset(_yAxisWidth, _graphHeight), outLinePaint);
    canvas.drawLine(
        Offset(_yAxisWidth, _graphHeight), Offset(parentWidth, _graphHeight), outLinePaint);
    canvas.drawLine(Offset(_yAxisWidth, 0), Offset(parentWidth, 0), outLinePaint);
    canvas.drawLine(Offset(parentWidth, 0), Offset(parentWidth, _graphHeight), outLinePaint);
  }

  @override
  bool shouldRepaint(YPainter oldDelegate) {
    if (oldDelegate.yAxisStrs.length != yAxisStrs.length) {
      return true;
    }
    for (int i = 0; i < oldDelegate.yAxisStrs.length; i++) {
      if (oldDelegate.yAxisStrs[i] != yAxisStrs[i]) return true;
    }

    return oldDelegate.parentWidth != parentWidth ||
        oldDelegate.parentHeight != parentHeight ||
        oldDelegate.yTextStyle != yTextStyle ||
        oldDelegate.yAxisMaxSize != yAxisMaxSize ||
        oldDelegate.outLinePaint != outLinePaint ||
        oldDelegate.inLinePaint != inLinePaint;
  }
}
