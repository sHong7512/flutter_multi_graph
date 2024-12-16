import 'dart:math';

import 'package:flutter/material.dart';
import 'package:multi_graph/controller/multi_graph_controller.dart';
import 'package:multi_graph/painter/auto_mixin.dart';

import '../../model/models.dart';
import '../../widget/multi_graph_widget.dart';

// 그래프 x 축 및 value 그리기 커스텀 패인터
class XValuePainter extends CustomPainter with AutoMixin {
  XValuePainter({
    required this.controller,
    required this.multiValues,
    required this.parentWidth,
    required this.parentHeight,
    required this.yAxisValues,
    required this.xTextStyle,
    required this.dotRadius,
    required this.xAxisMaxSize,
    required this.maxBarWidth,
    required this.lineStroke,
    required this.outLinePaint,
    required this.inLinePaint,
    required this.maxCount,
  }) {
    _graphHeight = parentHeight / MultiGraphWidget.ratioAll * MultiGraphWidget.ratioXW;
    _xAxisHeight = parentHeight / MultiGraphWidget.ratioAll;
    _yAxisSize = Size(_yAxisWidth, _graphHeight / yAxisValues.length);
    _addY = parentHeight / 100;
    baseWidth = parentWidth / MultiGraphWidget.ratioAll * MultiGraphWidget.ratioXW / maxCount;
  }

  final MultiGraphController controller;
  final List<ValueSourceSet> multiValues;
  final double parentWidth;
  final double parentHeight;
  final List<double> yAxisValues;
  final TextStyle xTextStyle;
  final double dotRadius;
  final Size xAxisMaxSize;
  final double maxBarWidth;
  final double lineStroke;
  final Paint outLinePaint;
  final Paint inLinePaint;
  final int maxCount;

  late final double _graphHeight;
  late final double _xAxisHeight;
  late final Size _yAxisSize;
  late final double _addY;
  late final double baseWidth;

  final double _yAxisWidth = 0;

  late final List<List<_NameValueKeyOffset>> _valueLineStrs;
  late final List<List<_NameValueKeyOffset>> _valueBarStrs;

  @override
  void paint(Canvas canvas, Size size) {
    _drawXAxisWithBar(canvas);
    _drawLineValues(canvas);
    _drawValueShow(canvas);
  }

  // 값 표시
  _drawValueShow(Canvas canvas) {
    final List<_NameValueKeyOffset_Val> bufNewVals = [];
    for (int i = 0; i < multiValues.length; i++) {
      final value = multiValues[i];
      if (!value.showValue) continue;
      for (int j = 0; j < value.sources.length; j++) {
        // 막대 그래프 값표시
        final bar = value.sources[j].bar;
        if (bar != null) {
          final boxSize = Size(baseWidth / value.sources.length, parentHeight / yAxisValues.length);
          final text = controller.valFormat.format(bar.value);
          final textPainter = autoTextPainter(
            text,
            boxSize,
            controller.valTextStyle,
            bar.valueTextPainter,
          );
          if (bar.valueTextPainter != textPainter) {
            controller.updateBarValueStrTP(i, j, textPainter);
          }
          final offset =
              _valueBarStrs[i][j].offset - Offset(textPainter.width / 2, textPainter.height);
          bufNewVals.add(_NameValueKeyOffset_Val(bar, offset, textPainter));
        }

        // 선 그래프 값 표시
        final line = value.sources[j].line;
        if (line != null) {
          final boxSize = Size(baseWidth / value.sources.length, parentHeight / yAxisValues.length);
          final text = controller.valFormat.format(line.value);
          final textPainter = autoTextPainter(
            text,
            boxSize,
            controller.valTextStyle,
            line.valueTextPainter,
          );
          if (line.valueTextPainter != textPainter) {
            controller.updateLineValueStrTP(i, j, textPainter);
          }
          final offset = _valueLineStrs[i][j].offset -
              Offset(textPainter.width / 2, textPainter.height + dotRadius);
          bufNewVals.add(_NameValueKeyOffset_Val(line, offset, textPainter));
        }
      }
    }

    bufNewVals.sort((a, b) => b.nameKeyValue.value.compareTo(a.nameKeyValue.value));
    final color = controller.valColor;
    final List<Rect> drawnRects = [];
    for (final b in bufNewVals) {
      var offset = b.offset;
      final textPainter = b.textPainter;
      var textRect = Rect.fromLTWH(offset.dx, offset.dy, textPainter.width, textPainter.height);

      bool hasCollision;
      do {
        hasCollision = false;
        for (final rect in drawnRects) {
          if (textRect.overlaps(rect)) {
            offset = Offset(offset.dx, rect.bottom + 1);
            textRect = Rect.fromLTWH(offset.dx, offset.dy, textPainter.width, textPainter.height);
            hasCollision = true;
            break;
          }
        }
      } while (hasCollision);

      canvas.drawRect(
          textRect,
          Paint()
            ..color = color
            ..style = PaintingStyle.fill);

      // Paint the text
      textPainter.paint(canvas, offset);

      // Store the drawn rect
      drawnRects.add(textRect);
    }
  }

  // 선 그래프 그리기
  _drawLineValues(Canvas canvas) {
    final dots = <String, List<_NameValueKeyOffset>>{};
    _valueLineStrs = List.generate(multiValues.length, (i) => []);

    // 순서대로 그리기 위해. 좌표값만 먼저 뽑음
    for (int i = 0; i < multiValues.length; i++) {
      final value = multiValues[i];
      for (int j = 0; j < value.sources.length; j++) {
        final inside = value.sources[j];
        if (inside.line == null) continue;

        final yPosition = _getYPosition(inside.line!.value);
        if (yPosition == null) continue;
        final dotOffset = Offset(baseWidth * i + baseWidth / 2 + _yAxisWidth, yPosition);

        final key = inside.line!.stringNameKey;
        if (!dots.containsKey(key)) dots[key] = [];
        dots[key]!.add(_NameValueKeyOffset(inside.line!, dotOffset));

        _valueLineStrs[i].add(_NameValueKeyOffset(inside.line!, dotOffset));
      }
    }

    // 뽑은 좌표값으로 선 그래프 그리기
    for (final e in dots.entries) {
      if (e.value.length < 2) {
        final paint = Paint()
          ..color = e.value[0].nameKeyValue.color
          ..strokeWidth = lineStroke
          ..style = PaintingStyle.fill;
        canvas.drawCircle(e.value[0].offset, dotRadius, paint);
        continue;
      }
      for (int i = 0; i < e.value.length - 1; i++) {
        final paint = Paint()
          ..color = e.value[i].nameKeyValue.color
          ..strokeWidth = lineStroke
          ..style = PaintingStyle.fill;
        final start = e.value[i].offset;
        final end = e.value[i + 1].offset;
        final animValue = e.value[i + 1].nameKeyValue.lineAnimValue;
        canvas.drawLine(start, start + (end - start) * animValue, paint);
        canvas.drawCircle(start, dotRadius, paint);

        if (animValue < 1) {
          canvas.drawCircle(
              start + (end - start) * e.value[i + 1].nameKeyValue.lineAnimValue, dotRadius, paint);
        }

        if (i == e.value.length - 2 && animValue >= 1) {
          final paint = Paint()
            ..color = e.value[i + 1].nameKeyValue.color
            ..strokeWidth = lineStroke
            ..style = PaintingStyle.fill;
          canvas.drawCircle(e.value[i + 1].offset, dotRadius, paint);
        }
      }
    }
  }

  // x축 텍스트 및 분할라인 및 막대 그래프 그리기
  _drawXAxisWithBar(Canvas canvas) {
    _valueBarStrs = List.generate(multiValues.length, (i) => []);

    for (int i = 0; i < multiValues.length; i++) {
      final value = multiValues[i];
      final inSize = Size(baseWidth / value.sources.length, _xAxisHeight);

      final paint = Paint()
        ..strokeWidth = min(inSize.width * 4 / 5, maxBarWidth)
        ..style = PaintingStyle.fill;
      for (int j = 0; j < value.sources.length; j++) {
        final inside = value.sources[j];
        if (inside.bar == null) continue;
        paint.color = inside.bar!.color;

        final yPosition = _getYPosition(inside.bar!.value);
        if (yPosition == null) continue;
        final start =
            Offset(baseWidth * i + inSize.width * j + inSize.width / 2 + _yAxisWidth, _graphHeight);
        final end = Offset(start.dx, yPosition);
        canvas.drawLine(start, end, paint);

        _valueBarStrs[i].add(_NameValueKeyOffset(inside.bar!, end));

        // 서브 타이틀 사용시 텍스트
        if (!value.useMainTitle) {
          final squareSize = Size(min(inSize.width * 4 / 5, xAxisMaxSize.width),
              min(inSize.height * 4 / 5, xAxisMaxSize.height));
          final textPainter = autoTextPainter(
              inside.bar!.stringNameKey, squareSize, xTextStyle, inside.bar!.fixedTextPainter);
          if (inside.bar!.fixedTextPainter != textPainter) {
            controller.updateBarFittedTP(i, j, textPainter);
          }

          final textOffset = Offset(
            start.dx - textPainter.width / 2,
            _graphHeight + _xAxisHeight / 2 - textPainter.height / 2,
          );
          textPainter.paint(canvas, textOffset);
        }
      }

      // 메인 타이틀 사용시 텍스트
      if (value.useMainTitle) {
        final inSize = Size(baseWidth, _xAxisHeight);
        final squareSize = Size(min(inSize.width * 4 / 5, xAxisMaxSize.width),
            min(inSize.height * 4 / 5, xAxisMaxSize.height));
        final textPainter =
            autoTextPainter(value.name, squareSize, xTextStyle, value.fixedTextPainter);
        if (value.fixedTextPainter != textPainter) {
          value.fixedTextPainter = textPainter;
        }
        final textOffset = Offset(
          baseWidth * i + baseWidth / 2 - textPainter.width / 2 + _yAxisWidth,
          _graphHeight + _xAxisHeight / 2 - textPainter.height / 2,
        );
        textPainter.paint(canvas, textOffset);
      }
      // x 단위 분할 라인
      canvas.drawLine(
        Offset(baseWidth * i + _yAxisWidth, _graphHeight),
        Offset(baseWidth * i + _yAxisWidth, 0),
        inLinePaint,
      );
      // x 단위 서브 라인
      canvas.drawLine(
        Offset(baseWidth * i + _yAxisWidth, _graphHeight),
        Offset(baseWidth * i + _yAxisWidth, _graphHeight + _addY),
        outLinePaint,
      );
    }
    // x 단위 분할 라인. 끝부분
    canvas.drawLine(
      Offset(baseWidth * multiValues.length + _yAxisWidth, _graphHeight),
      Offset(baseWidth * multiValues.length + _yAxisWidth, 0),
      inLinePaint,
    );
    // x 단위 서브 라인. 끝부분
    canvas.drawLine(
      Offset(baseWidth * multiValues.length + _yAxisWidth, _graphHeight),
      Offset(baseWidth * multiValues.length + _yAxisWidth, _graphHeight + _addY),
      outLinePaint,
    );
  }

  // y축 값에 맞는 변환 값 가져오기
  double? _getYPosition(double value) {
    if (yAxisValues.isEmpty) return null;
    final startValue = yAxisValues.first;
    final lastValue = yAxisValues.last;
    return _graphHeight -
        (value - startValue) * (_graphHeight - _yAxisSize.height) / (lastValue - startValue);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

// 라인 그래프 전용. 그래프 값(한 점) + 오프셋
class _NameValueKeyOffset {
  _NameValueKeyOffset(this.nameKeyValue, this.offset);

  final NameKeyValue nameKeyValue;
  final Offset offset;
}

class _NameValueKeyOffset_Val {
  _NameValueKeyOffset_Val(this.nameKeyValue, this.offset, this.textPainter);

  final NameKeyValue nameKeyValue;
  final Offset offset;
  final TextPainter textPainter;
}
