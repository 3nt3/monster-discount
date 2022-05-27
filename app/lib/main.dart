import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
              Text('Monster ⁠Discount — sagt dir wenn Monster discountet ist.',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 100),
              Text('REWE DEIN MARKT??',
                  style: Theme.of(context).textTheme.headlineSmall),
              MyReweWidget(),
            ],
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
  final List<ReweLocation> _locations = [
    const ReweLocation('REWE Dieker Straße', 'asdf')
  ];

  bool _loading = false;
  final _url = "https://mobile-api.rewe.de/mobile/markets/market-search";

  _onSearchChange(String s) async {
    var url = Uri.parse(_url + "?query=" + s);
    debugPrint(url.toString());
    _loading = true;
    setState(() {});

    var response = await http.get(url);
    _loading = false;
    setState(() {});
    debugPrint(response.body);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Column(
          children: _locations
              .map(
                (loc) => Row(
                  children: [
                    Expanded(child: Text(loc.name)),
                    IconButton(
                      onPressed: () {
                        setState(() {});
                        _locations.remove(loc);
                      },
                      icon: const Icon(Icons.delete, color: Colors.red),
                    ),
                  ],
                ),
              )
              .toList()),
      TextFormField(
        keyboardType: TextInputType.number,
        onChanged: _onSearchChange,
        maxLength: 5,
        decoration: InputDecoration(
          label: Row(
            children: const [
              Icon(Icons.search),
              Text('Suchen (PLZ)'),
            ],
          ),
        ),
      ),
      (_loading
          ? const CircularProgressIndicator()
          : ListView(children: [], shrinkWrap: true))
    ]);
  }
}

class MyReweLocationItem extends StatelessWidget {
  MyReweLocationItem(this.location, {Key? key}) : super(key: key);

  ReweLocation location;

  @override
  Widget build(BuildContext context) {
    return Container(child: Text(location.name));
  }
}

class ReweLocation {
  final String name;
  final String url;
  const ReweLocation(this.name, this.url);
}
