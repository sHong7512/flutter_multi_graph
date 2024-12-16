import 'dart:math';

import 'package:flutter/material.dart';
import 'package:multi_graph/multi_graph.dart';
import 'package:provider/provider.dart';

import '../painter/legend/legend_color_painter.dart';
import '../painter/legend/legend_text_painter.dart';

class MultiGraphLegendWidget extends StatelessWidget {
  final MultiGraphController graphController;
  final Axis axis;
  final InfoValue infoValue;
  final Size itemSize;
  final double? width;
  final double? height;
  final bool showInitAnimation;
  final Curve curve;
  final Duration duration;
  final TextStyle itemTextStyle;

  const MultiGraphLegendWidget({
    super.key,
    required this.graphController,
    required this.axis,
    required this.infoValue,
    this.width,
    this.height,
    this.itemSize = const Size(50, 20),
    this.itemTextStyle = const TextStyle(fontSize: 10, color: Colors.black),
    this.showInitAnimation = true,
    this.curve = Curves.linear,
    this.duration = const Duration(milliseconds: 1000),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ChangeNotifierProvider<MultiGraphController>(
        create: (_) => graphController,
        child: LayoutBuilder(builder: (context, constraint) {
          graphController.yAutoTextMap.clear();
          final maxWidth = constraint.maxWidth == double.infinity
              ? MediaQuery.sizeOf(context).width
              : constraint.maxWidth;
          final maxHeight = constraint.maxWidth == double.infinity
              ? MediaQuery.sizeOf(context).height
              : constraint.maxHeight;
          final maxItemSize = Size(min(maxWidth, itemSize.width), min(maxHeight, itemSize.height));
          return _legend(maxItemSize);
        }),
      ),
    );
  }

  _legend(Size maxItemSize) {
    return Consumer<MultiGraphController>(
      builder: (_, controller, __) {
        return SizedBox(
          width: axis == Axis.vertical ? maxItemSize.width : null,
          height: axis == Axis.horizontal ? maxItemSize.height : null,
          child: Center(
            child: SingleChildScrollView(
              scrollDirection: axis,
              child: Consumer<MultiGraphController>(
                builder: (_, controller, __) {
                  final values = <String, NameKeyValue>{};
                  for (final inside in controller.multiValues.reversed) {
                    for (final s in inside.sources) {
                      final v = infoValue == InfoValue.line ? s.line : s.bar;
                      if (v != null && !values.containsKey(v.stringNameKey)) {
                        values[v.stringNameKey] = v;
                      }
                    }
                  }
                  final children = values.entries
                      .map((e) => _Item(
                            nameKeyValue: e.value,
                            axis: axis,
                            maxSize: maxItemSize,
                            curve: curve,
                            duration: duration,
                            itemTextStyle: itemTextStyle,
                            autoTextMap: controller.yAutoTextMap,
                          ))
                      .toList();
                  return axis == Axis.horizontal
                      ? Row(children: children)
                      : Column(children: children);
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Item extends StatefulWidget {
  final NameKeyValue nameKeyValue;
  final Axis axis;
  final Size maxSize;
  final Curve curve;
  final Duration duration;
  final TextStyle itemTextStyle;
  final Map<String, double?> autoTextMap;

  const _Item({
    super.key,
    required this.nameKeyValue,
    required this.axis,
    required this.maxSize,
    required this.curve,
    required this.duration,
    required this.itemTextStyle,
    required this.autoTextMap,
  });

  @override
  State<_Item> createState() => _ItemState();
}

class _ItemState extends State<_Item> with SingleTickerProviderStateMixin {
  late final AnimationController animationController;
  late final Animation<double> animation;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(duration: widget.duration, vsync: this);
    animation = CurvedAnimation(parent: animationController, curve: widget.curve);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      animationController.reset();
      animationController.forward();
    });
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: Row(
        children: [
          SizedBox(
            width: widget.maxSize.width / 2,
            height: widget.maxSize.height,
            child: RepaintBoundary(
              child: CustomPaint(
                painter: LegendColorPainter(
                  parentSize: Size(widget.maxSize.width / 2, widget.maxSize.height),
                  valueColor: widget.nameKeyValue.color,
                ),
              ),
            ),
          ),
          SizedBox(
            width: widget.maxSize.width / 2,
            height: widget.maxSize.height,
            child: RepaintBoundary(
              child: CustomPaint(
                painter: LegendTextPainter(
                  text: widget.nameKeyValue.stringNameKey,
                  parentSize: Size(widget.maxSize.width / 2, widget.maxSize.height),
                  style: widget.itemTextStyle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
