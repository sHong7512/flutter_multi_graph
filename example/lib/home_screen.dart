import 'dart:math';

import 'package:flutter/material.dart';
import 'package:multi_graph/multi_graph.dart';

final rainbow = [
  Colors.red,
  Colors.orange,
  Colors.yellow,
  Colors.green,
  Colors.blue,
  Colors.indigo,
  Colors.purple,
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final MultiGraphController _controller;
  static const int baseMillis = 500;

  @override
  void initState() {
    super.initState();
    _controller = MultiGraphController(
      multiValues: initialData,
      showingCount: 10,
      maxStoreCount: 100,
      yDivLen: 10,
      initialMaxY: 100,
      initialMinY: -100,
      onePointMillis: baseMillis,
    );

    randRepeat();
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraint) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  MultiGraphLegendWidget(
                    itemSize: Size(constraint.maxWidth / 20, constraint.maxHeight / 30),
                    graphController: _controller,
                    axis: Axis.horizontal,
                    infoValue: InfoValue.line,
                  ),
                  MultiGraphWidget(
                    graphController: _controller,
                    width: constraint.maxWidth / 1.5,
                    height: constraint.maxHeight / 1.5,
                    duration: Duration(milliseconds: baseMillis * _controller.multiValues.length),
                    titleTextView: const Text(
                      "타이틀",
                      style: TextStyle(fontSize: 20, color: Colors.black),
                    ),
                  ),
                ],
              ),
              MultiGraphLegendWidget(
                itemSize: Size(constraint.maxWidth / 20, constraint.maxHeight / 30),
                graphController: _controller,
                axis: Axis.vertical,
                infoValue: InfoValue.bar,
              ),
            ],
          );
        }
      ),
    );
  }

  randRepeat() async {
    await Future.delayed(Duration(milliseconds: baseMillis * _controller.multiValues.length));
    for (int i = 0; i < 10000; i++) {
      await Future.delayed(const Duration(milliseconds: baseMillis * 2));
      _controller.addLastValue(randSourceSet('랜덤$i', Random().nextBool()));
    }
  }

  List<ValueSourceSet> get initialData {
    final list = [
      ValueSourceSet(
        name: '고정',
        useMainTitle: true,
        sources: [
          ValueSource(
              bar: NameKeyValue(stringNameKey: "br1", value: -100),
              line: NameKeyValue(stringNameKey: "lr1", value: -100)),
          ValueSource(
              bar: NameKeyValue(stringNameKey: "br2", value: -50),
              line: NameKeyValue(stringNameKey: "lr2", value: -50)),
          ValueSource(
              bar: NameKeyValue(stringNameKey: "br3", value: 0),
              line: NameKeyValue(stringNameKey: "lr3", value: 0)),
          ValueSource(
              bar: NameKeyValue(stringNameKey: "br4", value: 50),
              line: NameKeyValue(stringNameKey: "lr4", value: 50)),
          ValueSource(
              bar: NameKeyValue(stringNameKey: "br5", value: 100),
              line: NameKeyValue(stringNameKey: "lr5", value: 100)),
        ],
      ),
    ];
    for(int i = 0; i < 10; i++){
      list.add(randSourceSet("랜덤", true));
    }
    return list;
  }

  ValueSourceSet randSourceSet(String name, bool useMainTitle) {
    final rand = Random();
    return ValueSourceSet(
      name: name,
      useMainTitle: useMainTitle,
      sources: [
        ValueSource(
            bar: NameKeyValue(
                stringNameKey: "br1", value: -rand.nextDouble() * 100, color: rainbow[0]),
            line: NameKeyValue(
              stringNameKey: "lr1",
              value: rand.nextDouble() * 100,
              color: rainbow[0],
            )),
        ValueSource(
            bar: NameKeyValue(
              stringNameKey: "br2",
              value: -rand.nextDouble() * 100,
              color: rainbow[1],
            ),
            line: NameKeyValue(
              stringNameKey: "lr2",
              value: rand.nextDouble() * 100,
              color: rainbow[1],
            )),
        ValueSource(
            bar: NameKeyValue(
              stringNameKey: "br3",
              value: -rand.nextDouble() * 100,
              color: rainbow[2],
            ),
            line: NameKeyValue(
              stringNameKey: "lr3",
              value: rand.nextDouble() * 100,
              color: rainbow[2],
            )),
        ValueSource(
            bar: NameKeyValue(
              stringNameKey: "br4",
              value: -rand.nextDouble() * 100,
              color: rainbow[3],
            ),
            line: NameKeyValue(
              stringNameKey: "lr4",
              value: rand.nextDouble() * 100,
              color: rainbow[3],
            )),
        ValueSource(
            bar: NameKeyValue(
              stringNameKey: "br5",
              value: -rand.nextDouble() * 100,
              color: rainbow[4],
            ),
            line: NameKeyValue(
              stringNameKey: "lr5",
              value: rand.nextDouble() * 100,
              color: rainbow[5],
            )),
      ],
    );
  }
}
