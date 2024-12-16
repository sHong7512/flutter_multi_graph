import 'package:flutter/material.dart';

// 한 단위의 그래프 요소
class ValueSourceSet {
  ValueSourceSet({
    required this.name,
    required this.useMainTitle,
    required this.sources,
    this.showValue = false,
  });

  final String name;
  final bool useMainTitle;
  final List<ValueSource> sources;
  TextPainter? fixedTextPainter;
  bool showValue;

  ValueSourceSet copyWith({
    String? name,
    bool? useMainTitle,
    List<ValueSource>? sources,
    TextPainter? fixedTextPainter,
    bool? showValue,
  }) {
    return ValueSourceSet(
      name: name ?? this.name,
      useMainTitle: useMainTitle ?? this.useMainTitle,
      sources: sources ?? this.sources,
      showValue: showValue ?? this.showValue,
    )..fixedTextPainter = fixedTextPainter ?? this.fixedTextPainter;
  }
}

// 내부 x, y 요소
class ValueSource {
  ValueSource({this.bar, this.line});

  final NameKeyValue? bar;
  final NameKeyValue? line;
}

// 한 포인트 값 및 정보
class NameKeyValue {
  NameKeyValue(
      {required this.stringNameKey,
      required this.value,
      this.color = const Color(0xff000000),
      this.lineAnimValue = 1,
      this.fixedTextPainter});

  final String stringNameKey;
  final double value;
  final Color color;
  final double lineAnimValue;
  TextPainter? fixedTextPainter;
  TextPainter? valueTextPainter;

  NameKeyValue copyWith({
    String? stringNameKey,
    double? value,
    Color? color,
    double? lineAnimValue,
    TextPainter? fixedTextPainter,
    TextPainter? valueTextPainter,
  }) {
    return NameKeyValue(
      stringNameKey: stringNameKey ?? this.stringNameKey,
      value: value ?? this.value,
      color: color ?? this.color,
      lineAnimValue: lineAnimValue ?? this.lineAnimValue,
    )
      ..fixedTextPainter = fixedTextPainter ?? this.fixedTextPainter
      ..valueTextPainter = valueTextPainter ?? this.valueTextPainter;
  }

  NameKeyValue copyWithRemovePainter({
    String? stringNameKey,
    double? value,
    Color? color,
    double? lineAnimValue,
  }) {
    return NameKeyValue(
      stringNameKey: stringNameKey ?? this.stringNameKey,
      value: value ?? this.value,
      color: color ?? this.color,
      lineAnimValue: lineAnimValue ?? this.lineAnimValue,
    )
      ..fixedTextPainter = null
      ..valueTextPainter = null;
  }
}

// 범례 설정시 나타낼 데이터
enum InfoValue { line, bar }
