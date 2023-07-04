import 'package:flutter/material.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    Key? key,
  }) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return SafeArea(
      child: SizedBox.expand(
        child: ListView(
          padding: EdgeInsets.all(20),
          shrinkWrap: true,
          children: [
            Text('Monster Prices',
                style: Theme.of(context).textTheme.headlineMedium),
            MyPricesWidget()
          ],
        ),
      ),
    );
  }
}

class MyPricesWidget extends StatefulWidget {
  const MyPricesWidget({super.key});

  @override
  State<MyPricesWidget> createState() => _MyPricesWidgetState();
}

class _MyPricesWidgetState extends State<MyPricesWidget> {
  var _prices = [0.99, 1.49, 1.19];
  var _bestPrice = 0.0;

  @override
  void initState() {
    super.initState();
    _prices.sort((a, b) => a.compareTo(b));
    _bestPrice = _prices[0] ?? 0.0;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView(
        shrinkWrap: false,
        scrollDirection: Axis.horizontal,
        children: _prices
            .map(
              (price) => MyPriceTile(price, _bestPrice >= price),
            )
            .toList(),
      ),
    );
  }
}

class MyPriceTile extends StatelessWidget {
  final double price;
  final bool isOptimal;
  const MyPriceTile(this.price, this.isOptimal, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Card(
          child: SizedBox(
            height: 100,
            width: 120,
            child: Padding(
              padding: EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      padding: EdgeInsets.all(isOptimal ? 5 : 0),
                      child: Text(
                        "$price €",
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                                color: isOptimal ? Colors.white : null,
                                fontWeight: isOptimal ? FontWeight.bold : null),
                      ),
                      decoration: BoxDecoration(
                        color: isOptimal ? Colors.red.shade300 : null,
                        borderRadius: BorderRadius.all(
                          Radius.circular(8),
                        ),
                      )),
                  Text("REWE Haan"),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
      ],
    );
  }
}
