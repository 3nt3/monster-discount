import 'dart:convert';

import 'package:app/market.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'offers_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'asdf',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        fontFamily: 'Open Sans',
        scaffoldBackgroundColor: const Color(0xFF202124),
        brightness: Brightness.dark,
        primarySwatch: Colors.green,
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
              color: Colors.white,
              fontFamily: 'Nunito',
              fontWeight: FontWeight.bold),
          headlineSmall: TextStyle(
              color: Colors.white,
              fontFamily: 'Nunito',
              fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(color: Colors.white),
        ),
      ),
      home: const MyHomePage(),
    );
  }
}

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
    return Scaffold(
      body: SafeArea(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Column(
              // Column is also a layout widget. It takes a list of children and
              // arranges them vertically. By default, it sizes itself to fit its
              // children horizontally, and tries to be as tall as its parent.
              //
              // Invoke "debug painting" (press "p" in the console, choose the
              // "Toggle Debug Paint" action from the Flutter Inspector in Android
              // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
              // to see the wireframe for each widget.
              //
              // Column has various properties to control how it sizes itself and
              // how it positions its children. Here we use mainAxisAlignment to
              // center the children vertically; the main axis here is the vertical
              // axis because Columns are vertical (the cross axis would be
              // horizontal).
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                    'Monster ⁠Discount — sagt dir wenn Monster discountet ist.',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 50),
                Text('REWE DEIN MARKT??',
                    style: Theme.of(context).textTheme.headlineSmall),
                const MyReweWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyReweWidget extends StatefulWidget {
  const MyReweWidget({Key? key}) : super(key: key);

  @override
  _MyReweWidgetState createState() => _MyReweWidgetState();
}

class _MyReweWidgetState extends State<MyReweWidget> {
  final List<Market> _selectedMarkets = [];

  bool _loading = false;
  final _url = "https://mobile-api.rewe.de/mobile/markets/market-search";
  List<Market> _searchResults = [];
  DateTime lastSearchResult = DateTime.now();

  final TextEditingController _controller = TextEditingController();

  _onSearchChange(String s) async {
    var startedAt = DateTime.now();
    var url = Uri.parse(_url + "?query=" + s);
    debugPrint(url.toString());
    _loading = true;
    setState(() {});

    var response = await http.get(url);
    _loading = false;

    if (startedAt.compareTo(lastSearchResult) > 0) {
      Map<String, dynamic> marketsJson = jsonDecode(response.body);
      _searchResults = Markets.fromJson(marketsJson).items;
      lastSearchResult = startedAt;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(
          children: _selectedMarkets
              .map(
                (loc) => Row(
                  children: [
                    Expanded(child: Text(loc.name)),
                    IconButton(
                      onPressed: () {
                        _selectedMarkets.remove(loc);
                        setState(() {});
                      },
                      icon: const Icon(Icons.delete, color: Colors.red),
                    ),
                  ],
                ),
              )
              .toList()),
      SizedBox(
        width: 200,
        child: ElevatedButton(
            onPressed: (_selectedMarkets.isEmpty
                ? null
                : () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => OffersPage(_selectedMarkets
                                .map<String>((m) => m.id)
                                .toList())));
                  }),
            child: const Text("OKÉ SO?")),
      ),
      TextFormField(
        keyboardType: TextInputType.number,
        onChanged: _onSearchChange,
        maxLength: 5,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          prefixIconColor: Colors.white,
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _controller.clear();
                  },
                  icon: const Icon(Icons.clear)),
        ),
      ),
      (_loading
          ? const Center(child: CircularProgressIndicator())
          : (_searchResults.isNotEmpty
              ? SizedBox(
                  height: 300,
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: ListView(
                      children: _searchResults
                          .map((m) => MyMarketTile(m, () {
                                if (_selectedMarkets.indexWhere(
                                        (element) => element.id == m.id) ==
                                    -1) {
                                  _selectedMarkets.add(m);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text("Bereits ausgewählt")));
                                }
                                setState(() {});
                              }))
                          .toList(),
                      scrollDirection: Axis.vertical,
                      shrinkWrap: true,
                    ),
                  ),
                )
              : const Center(
                  child: Text("Keine Ergebnisse"),
                ))),
    ]);
  }
}

class MyMarketTile extends StatelessWidget {
  MyMarketTile(this.market, this.onTap, {Key? key}) : super(key: key);

  Market market;
  void Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      InkWell(
        onTap: onTap,
        child: Container(
          width: 10000,
          decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              color: Color(0xFF2B2C30)),
          child: Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(market.name),
                Text(market.address.street),
                Text(market.address.city),
              ],
            ),
          ),
        ),
      ),
      SizedBox(height: 10),
    ]);
  }
}
