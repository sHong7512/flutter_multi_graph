import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:multi_graph/multi_graph.dart';

// 그래프 컨트롤러 클래스
class MultiGraphController extends ChangeNotifier {
  final double? initialMinY;
  final double? initialMaxY;
  final int showingCount;
  final int maxStoreCount;
  final int onePointMillis;

  MultiGraphController({
    required List<ValueSourceSet> multiValues,
    required this.showingCount,
    required this.maxStoreCount,
    this.onePointMillis = 1000,
    int? yDivLen,
    this.initialMinY,
    this.initialMaxY,
  }) {
    if (multiValues.isEmpty) {
      _exception('multiValues must not be empty');
    }
    if (yDivLen != null) {
      if (yDivLen < 1) {
        _exception('yDivLen must be bigger than 0');
      } else {
        _yDivLen = yDivLen;
      }
    }
    if (showingCount < 1) _exception('showingCount must be bigger than 0');
    if (maxStoreCount < 1) _exception('maxStoreCount must be bigger than 0');
    if (onePointMillis < updateMillis) {
      _exception('maxStoreCount must be bigger than updateMillis($updateMillis)');
    }
    _multiValues = multiValues;
    _removeOverPreValue();
    _calculateYDivisions();
  }

  // 컨트롤러 dispose
  bool _disposed = false;

  // 그래프 요소 리스트
  List<ValueSourceSet> _multiValues = [];

  List<ValueSourceSet> get multiValues => _multiValues;

  set multiValues(List<ValueSourceSet> multiValues) {
    _multiValues = multiValues;
    notifyListeners();
  }

  set animMultiValues(List<ValueSourceSet> multiValues) {
    _multiValues = multiValues;
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  // y축 넘버 포맷
  NumberFormat _yFormat = NumberFormat('###,###,###,###,###,###.##');

  NumberFormat get yFormat => _yFormat;

  set yFormat(NumberFormat format) {
    _yFormat = format;
    notifyListeners();
  }

  // 값 보이기 넘버 포맷
  NumberFormat _valFormat = NumberFormat('###,###,###,###,###,###.##');

  NumberFormat get valFormat => _valFormat;

  set valFormat(NumberFormat format) {
    _valFormat = format;
    notifyListeners();
  }

  // y분할 라인 갯수
  int _yDivLen = 5;

  int get yDivLen => _yDivLen;

  set yDivLen(int yDivLen) {
    if (yDivLen < 1) {
      _warning('yDivLen must be bigger than 0');
      return;
    }
    _yDivLen = yDivLen;
    _calculateYDivisions();
    notifyListeners();
  }

  // y최소값 (값에 따라 자동 조정)
  double _minY = double.maxFinite;

  double get minY => _minY;

  // y최대값 (값에 따라 자동 조정)
  double _maxY = -double.maxFinite;

  double get maxY => _maxY;

  // y축 나눠진 값 리스트. 외부 세팅 불가
  List<double> _yAxisValues = [];

  List<double> get yAxisValues => _yAxisValues;

  // y축 나눠진 값 글자 리스트. 외부 세팅 불가
  List<String> _yAxisStrs = [];

  List<String> get yAxisStrs => _yAxisStrs;

  // x축 텍스트 스타일
  TextStyle _xTextStyle = const TextStyle(fontSize: 12, color: Colors.black);

  TextStyle get xTextStyle => _xTextStyle;

  set xTextStyle(TextStyle style) {
    _xTextStyle = style;
    clearXFittedSize();
    notifyListeners();
  }

  // y축 텍스트 스타일
  TextStyle _yTextStyle = const TextStyle(fontSize: 12, color: Colors.black);

  TextStyle get yTextStyle => _yTextStyle;

  set yTextStyle(TextStyle style) {
    _yTextStyle = style;
    yAutoTextMap.clear();
    notifyListeners();
  }

  // 그래프 값 표시 텍스트 스타일
  TextStyle _valTextStyle = const TextStyle(fontSize: 12, color: Colors.black);

  TextStyle get valTextStyle => _valTextStyle;

  set valTextStyle(TextStyle style) {
    _valTextStyle = style;
    notifyListeners();
  }

  // 그래프 값 표시 박스 색상
  Color _valColor = Colors.transparent;

  Color get valColor => _valColor;

  set valColor(Color color) {
    _valColor = color;
    notifyListeners();
  }

  // 바깥 라인, xy축 분할 라인 패인트
  Paint _outLinePaint = Paint()
    ..color = Colors.black.withOpacity(0.3)
    ..strokeWidth = 1
    ..style = PaintingStyle.fill;

  Paint get outLinePaint => _outLinePaint;

  set outLinePaint(Paint outLinePaint) {
    _outLinePaint = outLinePaint;
    notifyListeners();
  }

  // 내부 xy축 분할 라인 패인트
  Paint _inLinePaint = Paint()
    ..color = Colors.black.withOpacity(0.1)
    ..strokeWidth = 1
    ..style = PaintingStyle.fill;

  Paint get inLinePaint => _inLinePaint;

  set inLinePaint(Paint inLinePaint) {
    _inLinePaint = inLinePaint;
    notifyListeners();
  }

  // 라인 그래프 점 크기
  double _dotRadius = 3;

  double get dotRadius => _dotRadius;

  set dotRadius(double dotRadius) {
    _dotRadius = dotRadius;
    notifyListeners();
  }

  // x축 위젯(글자) 맥스 사이즈
  Size _xAxisMaxSize = Size.infinite;

  Size get xAxisMaxSize => _xAxisMaxSize;

  set xAxisMaxSize(Size xAxisMaxSize) {
    _xAxisMaxSize = xAxisMaxSize;
    notifyListeners();
  }

  // y축 위젯(글자) 맥스 사이즈
  Size _yAxisMaxSize = Size.infinite;

  Size get yAxisMaxSize => _yAxisMaxSize;

  set yAxisMaxSize(Size yAxisMaxSize) {
    _yAxisMaxSize = yAxisMaxSize;
    notifyListeners();
  }

  // 막대 그래프 최대 크기
  double _maxBarWidth = 50;

  double get maxBarWidth => _maxBarWidth;

  set maxBarWidth(double maxBarWidth) {
    _maxBarWidth = maxBarWidth;
    notifyListeners();
  }

  // 라인 굵기
  double _lineStroke = 1;

  double get lineStroke => _lineStroke;

  set lineStroke(double lineStroke) {
    _lineStroke = lineStroke;
    notifyListeners();
  }

  // y오토 텍스트 맵핑
  final yAutoTextMap = <String, double?>{};

  @override
  void dispose() {
    if (!_disposed) {
      _disposed = true;
      super.dispose();
    }
    disConnectController();
  }

  @override
  notifyListeners() {
    if (!_disposed) {
      if (_animController?.value != 1) {
        _animController?.value = 1;
      }

      if (timer?.isActive == true) {
        if (bufferValue != null) {
          _multiValues[_multiValues.length - 1] = bufferValue!;
        }
        timer?.cancel();
        notifyListeners();
        _scrollForceLast();
      }
      super.notifyListeners();
    }
  }

  // y 분할 기준 자동으로 잡아줌
  // 최소, 최대값 찾아서 세팅해줌
  _calculateYDivisions() {
    double minYBuf = initialMinY ?? double.maxFinite;
    double maxYBuf = initialMaxY ?? -double.maxFinite;

    for (final mv in _multiValues) {
      for (final m in mv.sources) {
        minYBuf = min(minYBuf, m.bar?.value ?? double.maxFinite);
        minYBuf = min(minYBuf, m.line?.value ?? double.maxFinite);
        maxYBuf = max(maxYBuf, m.bar?.value ?? -double.maxFinite);
        maxYBuf = max(maxYBuf, m.line?.value ?? -double.maxFinite);
      }
    }
    final start = minYBuf;
    final end = maxYBuf;
    final ran = (end - start) / _yDivLen.toDouble();
    final list = <double>[];
    final listStr = <String>[];
    list.add(start);
    listStr.add(_yFormat.format(start));
    for (int i = 1; i < _yDivLen; i++) {
      list.add(start + ran * i);
      listStr.add(_yFormat.format(start + ran * i));
    }
    list.add(end);
    listStr.add(_yFormat.format(end));
    _yAxisValues = list;
    _yAxisStrs = listStr;
    _minY = minYBuf;
    _maxY = maxYBuf;
  }

  // 가장 오래된 그래프 제거
  _removeOverPreValue() {
    if (_multiValues.length > maxStoreCount) {
      _multiValues.removeRange(0, _multiValues.length - maxStoreCount);
    }
  }

  // 그래프 업데이트 관련 변수들
  static const int updateMillis = 1000 ~/ 60;

  double lastScrollWidth = 0;

  int lastValueLength = 0;

  ValueSourceSet? bufferValue;

  Timer? timer;

  double maxWidth = 0;

  // 최근 ValueSourceSet 추가. 애니메이션 옵션
  addLastValue(ValueSourceSet value, {bool showAnimation = true}) {
    if (_animController?.value != 1) {
      _animController?.value = 1;
    }

    if (timer?.isActive == true) {
      if (bufferValue != null) {
        _multiValues[_multiValues.length - 1] = bufferValue!;
      }
      timer?.cancel();
      notifyListeners();
    }

    bufferValue = value;
    _multiValues.add(value.copyWith(sources: []));
    _removeOverPreValue();
    _calculateYDivisions();
    lastValueLength = _multiValues.length;
    lastScrollWidth = _scrollController?.position.maxScrollExtent ?? 0;

    if (showAnimation) {
      _runAnimUpdate();
    } else {
      _multiValues[_multiValues.length - 1] = bufferValue!;
      notifyListeners();

      _scrollForceLast();
    }
  }

  _scrollForceLast() async {
    for (int i = 0; i < 100; i++) {
      if (_multiValues.length > showingCount) {
        if (_scrollController?.position.maxScrollExtent != null &&
            !(lastScrollWidth == _scrollController!.position.maxScrollExtent &&
                lastValueLength < maxStoreCount)) {
          _scrollController?.jumpTo(_scrollController!.position.maxScrollExtent);
          return;
        }
      }
      await Future.delayed(const Duration(milliseconds: 10));
    }
  }

  _runAnimUpdate() {
    int curMillis = 0;
    int lastCurTime = (DateTime.now()).millisecondsSinceEpoch;
    timer = Timer.periodic(const Duration(milliseconds: updateMillis), (t) {
      final bufTime = (DateTime.now()).millisecondsSinceEpoch;
      curMillis += bufTime - lastCurTime;
      lastCurTime = bufTime;

      if (bufferValue == null) {
        t.cancel();
        return;
      }

      final sourcesBuf = <ValueSource>[];
      for (final source in bufferValue!.sources) {
        NameKeyValue? bar;
        NameKeyValue? line;
        // 막대 그래프 애니메이션
        final transAnimValue = min(curMillis / onePointMillis, 1.0);
        bar = source.bar?.copyWith(
          value: _minY * (1 - transAnimValue) + source.bar!.value * transAnimValue,
        );
        // 선 그래프 애니메이션
        line = source.line?.copyWith(lineAnimValue: transAnimValue);
        sourcesBuf.add(ValueSource(bar: bar, line: line));
      }
      _multiValues[_multiValues.length - 1] = bufferValue!.copyWith(sources: sourcesBuf);

      if (_multiValues.length > showingCount) {
        if (_scrollController?.position.maxScrollExtent != null &&
            !(lastScrollWidth == _scrollController!.position.maxScrollExtent &&
                lastValueLength < maxStoreCount)) {
          final transAnimValue = min(curMillis / onePointMillis, 1.0);
          final baseWidth =
              maxWidth / MultiGraphWidget.ratioAll * MultiGraphWidget.ratioXW / showingCount;
          _scrollController?.jumpTo(
              _scrollController!.position.maxScrollExtent - (1 - transAnimValue) * baseWidth);
        }
      }

      if (!_disposed) {
        super.notifyListeners();
      } else {
        bufferValue = null;
        t.cancel();
      }

      if (curMillis >= onePointMillis) {
        bufferValue = null;
        t.cancel();
      }
    });
  }

  updateLineFittedTP(int valuesIndex, int sourcesIndex, TextPainter textPainter) {
    multiValues[valuesIndex].sources[sourcesIndex].line?.fixedTextPainter = textPainter;
    if (valuesIndex == multiValues.length - 1) {
      bufferValue?.sources[sourcesIndex].line?.fixedTextPainter = textPainter;
    }
  }

  updateBarFittedTP(int valuesIndex, int sourcesIndex, TextPainter textPainter) {
    multiValues[valuesIndex].sources[sourcesIndex].bar?.fixedTextPainter = textPainter;
    if (valuesIndex == multiValues.length - 1) {
      bufferValue?.sources[sourcesIndex].bar?.fixedTextPainter = textPainter;
    }
  }

  updateLineValueStrTP(int valuesIndex, int sourcesIndex, TextPainter textPainter) {
    multiValues[valuesIndex].sources[sourcesIndex].line?.valueTextPainter = textPainter;
    if (valuesIndex == multiValues.length - 1) {
      bufferValue?.sources[sourcesIndex].line?.valueTextPainter = textPainter;
    }
  }

  updateBarValueStrTP(int valuesIndex, int sourcesIndex, TextPainter textPainter) {
    multiValues[valuesIndex].sources[sourcesIndex].bar?.valueTextPainter = textPainter;
    if (valuesIndex == multiValues.length - 1) {
      bufferValue?.sources[sourcesIndex].bar?.valueTextPainter = textPainter;
    }
  }

  clearXFittedSize() {
    final listBuf = <ValueSourceSet>[];
    for (final values in _multiValues) {
      final sourceBuf = <ValueSource>[];
      for (final source in values.sources) {
        sourceBuf.add(
          ValueSource(
            bar: source.bar?.copyWith(fixedTextPainter: null),
            line: source.line?.copyWith(fixedTextPainter: null),
          ),
        );
      }
      listBuf.add(values.copyWith(sources: sourceBuf, fixedTextPainter: null));
    }
    _multiValues = listBuf;
  }

  clearValFittedSize() {
    final listBuf = <ValueSourceSet>[];
    for (final values in _multiValues) {
      final sourceBuf = <ValueSource>[];
      for (final source in values.sources) {
        sourceBuf.add(
          ValueSource(
            bar: source.bar?.copyWithRemovePainter(),
            line: source.line?.copyWithRemovePainter(),
          ),
        );
      }
      listBuf.add(values.copyWith(sources: sourceBuf));
    }
    _multiValues = listBuf;
  }

  changeShowValue(int index) {
    for (int i = 0; i < _multiValues.length; i++) {
      if (i == index) {
        _multiValues[index].showValue = !_multiValues[index].showValue;
      } else {
        _multiValues[i].showValue = false;
      }
    }
    if (index == _multiValues.length - 1) {
      bufferValue?.showValue = !(bufferValue?.showValue ?? false);
    }
    notifyListeners();
  }

  // 위젯 에니메이션 컨트롤러
  AnimationController? _animController;
  ScrollController? _scrollController;

  // 컨트롤러 연결
  connectController(AnimationController? controller, ScrollController controller2) {
    _animController = controller;
    _scrollController = controller2;
  }

  // 컨트롤러 연결 해제
  disConnectController() {
    _animController = null;
    _scrollController = null;
  }

  // 로그. exception
  _exception(String msg) {
    throw Exception('<MultiGraph> Error! $msg');
  }

  // 로그. warning
  _warning(String msg) {
    print('<MultiGraph> Error! $msg');
  }
}
