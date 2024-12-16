import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controller/multi_graph_controller.dart';
import '../model/models.dart';
import '../painter/graph/x_value_painter.dart';
import '../painter/graph/y_painter.dart';

// 그래프 위젯 클래스
class MultiGraphWidget extends StatefulWidget {
  final MultiGraphController graphController;
  final String? graphTitle;
  final bool showInitAnimation;
  final Duration duration;
  final Curve curve;
  final double? width;
  final double? height;
  final Text? titleTextView;
  final bool showTouchValue;

  static const int ratioYW = 1;
  static const int ratioXW = 9;
  static const int ratioAll = 10;

  const MultiGraphWidget({
    super.key,
    required this.graphController,
    this.width,
    this.height,
    this.graphTitle,
    this.showInitAnimation = true,
    this.duration = const Duration(milliseconds: 1000),
    this.curve = Curves.linear,
    this.titleTextView,
    this.showTouchValue = true,
  });

  @override
  State<MultiGraphWidget> createState() => _MultiGraphWidgetState();
}

class _MultiGraphWidgetState extends State<MultiGraphWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _animation;
  final _scrollController = ScrollController();
  final _autoTextMapY = <String, TextPainter?>{};

  late final List<ValueSourceSet> initialValues;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: widget.duration, vsync: this);
    _animation = CurvedAnimation(parent: _animationController, curve: widget.curve);

    widget.graphController.connectController(_animationController, _scrollController);

    initialValues = widget.graphController.multiValues;
    _animation.addListener(() {
      _animationPainting();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.showInitAnimation) {
        _animationController.forward();
      } else {
        _animationController.value = 1;
      }
    });
  }

  // 최초 애니메이션 처리
  _animationPainting() {
    final showingCount = widget.graphController.showingCount;
    final div = initialValues.length;

    int alreadyCount = 0;
    final List<ValueSourceSet> list = [];
    for (int i = 0; i < initialValues.length; i++) {
      final v = initialValues[i];
      final sourcesBuf = <ValueSource>[];
      if (_animation.value >= i / div) {
        for (final source in v.sources) {
          NameKeyValue? bar;
          NameKeyValue? line;
          // 막대 그래프 애니메이션
          final transAnimValue = min((_animation.value - i / div) * div, 1.0);
          bar = source.bar?.copyWith(
            value: widget.graphController.minY * (1 - transAnimValue) +
                source.bar!.value * transAnimValue,
          );
          // 선 그래프 애니메이션
          line = source.line?.copyWith(lineAnimValue: transAnimValue);
          sourcesBuf.add(ValueSource(bar: bar, line: line));
        }
        alreadyCount++;
      }
      list.add(v.copyWith(sources: sourcesBuf));
    }
    widget.graphController.animMultiValues = list;

    if (alreadyCount > showingCount) {
      if (widget.graphController.lastScrollWidth == _scrollController.position.maxScrollExtent &&
          widget.graphController.lastValueLength < widget.graphController.maxStoreCount) {
        return;
      }

      final transAnimValue = min((_animation.value - (initialValues.length - 1) / div) * div, 1.0);
      final baseWidth = widget.graphController.maxWidth /
          MultiGraphWidget.ratioAll *
          MultiGraphWidget.ratioXW /
          widget.graphController.showingCount;
      final jump = _scrollController.position.maxScrollExtent - (1 - transAnimValue) * baseWidth;
      _scrollController.jumpTo(jump);
    }
  }

  @override
  void dispose() {
    widget.graphController.disConnectController();
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Column(
        children: [
          if (widget.titleTextView != null)
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                const Expanded(flex: MultiGraphWidget.ratioYW, child: SizedBox()),
                Expanded(
                    flex: MultiGraphWidget.ratioXW, child: Center(child: widget.titleTextView!)),
              ],
            ),
          Expanded(child: _graph()),
        ],
      ),
    );
  }

  Widget _graph() {
    return LayoutBuilder(
      builder: (context, constraint) {
        widget.graphController.clearXFittedSize();
        widget.graphController.clearValFittedSize();
        _autoTextMapY.clear();
        widget.graphController.maxWidth = constraint.maxWidth == double.infinity
            ? MediaQuery.sizeOf(context).width
            : constraint.maxWidth;
        final maxHeight = constraint.maxWidth == double.infinity
            ? MediaQuery.sizeOf(context).height
            : constraint.maxHeight;
        final xBaseWidth =
            widget.graphController.maxWidth / MultiGraphWidget.ratioAll * MultiGraphWidget.ratioXW;
        return SizedBox(
          width: widget.graphController.maxWidth,
          height: maxHeight,
          child: ChangeNotifierProvider<MultiGraphController>(
            create: (_) => widget.graphController,
            child: Stack(
              children: [
                _outside(widget.graphController.maxWidth, maxHeight),
                Align(
                  alignment: Alignment.centerRight,
                  child: Listener(
                    onPointerDown: (detail) {
                      if(!widget.showTouchValue) return;
                      final box = context.findRenderObject() as RenderBox?;
                      if (box == null) return;

                      final unit = xBaseWidth / widget.graphController.showingCount;
                      final yWidth = widget.graphController.maxWidth / MultiGraphWidget.ratioAll;
                      final xPosition = box.globalToLocal(detail.position).dx - yWidth;
                      final extractIndex =
                          (xPosition / unit + _scrollController.offset / unit).toInt();
                      widget.graphController.changeShowValue(extractIndex);
                    },
                    child: SizedBox(
                      width: xBaseWidth,
                      height: maxHeight,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        child: _inside(xBaseWidth, maxHeight),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _inside(double xBaseWidth, double maxHeight) {
    return Consumer<MultiGraphController>(builder: (_, controller, __) {
      final xOverWidth =
          max(xBaseWidth, xBaseWidth / controller.showingCount * controller.multiValues.length);
      return SizedBox(
        width: xOverWidth,
        height: maxHeight,
        child: RepaintBoundary(
          child: CustomPaint(
            painter: XValuePainter(
              controller: controller,
              multiValues: controller.multiValues,
              parentWidth: controller.maxWidth,
              parentHeight: maxHeight,
              yAxisValues: controller.yAxisValues,
              xTextStyle: controller.xTextStyle,
              dotRadius: controller.dotRadius,
              xAxisMaxSize: controller.xAxisMaxSize,
              maxBarWidth: controller.maxBarWidth,
              lineStroke: controller.lineStroke,
              outLinePaint: controller.outLinePaint,
              inLinePaint: controller.inLinePaint,
              maxCount: controller.showingCount,
            ),
          ),
        ),
      );
    });
  }

  Widget _outside(double maxWidth, double maxHeight) {
    return Consumer<MultiGraphController>(builder: (_, controller, __) {
      return RepaintBoundary(
        child: CustomPaint(
          painter: YPainter(
            parentWidth: maxWidth,
            parentHeight: maxHeight,
            yAxisStrs: controller.yAxisStrs,
            yTextStyle: controller.yTextStyle,
            yAxisMaxSize: controller.yAxisMaxSize,
            outLinePaint: controller.outLinePaint,
            inLinePaint: controller.inLinePaint,
            autoTextMapY: _autoTextMapY,
          ),
        ),
      );
    });
  }
}
