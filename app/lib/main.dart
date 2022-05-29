import 'dart:convert';

import 'package:app/market.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

import 'offers_page.dart';
import './api.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();

  debugPrint("Handling a background message: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
          bodyMedium: TextStyle(color: Colors.white, fontSize: 16),
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
                Text('sagt dir, wenn Monster discountet ist.',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 50),
                Text('REWE DEIN MARKT??',
                    style: Theme.of(context).textTheme.headlineSmall),
                const MyReweWidget(),
                const SizedBox(height: 40),
                Text('SUPERMÄRKTE FÜR GERINGVERDIENENDE',
                    style: Theme.of(context).textTheme.headlineSmall),
                const Text("coming soon (nie)")
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
  List<Market> _selectedMarkets = [];

  bool _searchLoading = false;
  bool _initLoading = true;
  final _url = "https://mobile-api.rewe.de/mobile/markets/market-search";
  List<Market> _searchResults = [];
  DateTime lastSearchResult = DateTime.now();

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  _fetchPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    final maybeIds = prefs.getStringList("market_ids");
    debugPrint(maybeIds.toString());
    if (maybeIds == null) {
      return;
    }
    _selectedMarkets = [];
    setState(() {});

    for (var marketId in maybeIds) {
      _selectedMarkets.add(await _fetchMarketById(marketId));
      setState(() {});
    }

    _initLoading = false;
    setState(() {});
  }

  Future<Market> _fetchMarketById(String marketId) async {
    final resp = await http.get(Uri.parse(
        "https://mobile-api.rewe.de/mobile/markets/markets/$marketId"));
    final marketJson = jsonDecode(resp.body);
    return Market.fromJson(marketJson);
  }

  @override
  void initState() {
    super.initState();
    _fetchPrefs();
  }

  _onSearchChange(String s) async {
    var startedAt = DateTime.now();
    var url = Uri.parse(_url + "?query=" + s);
    _searchLoading = true;
    setState(() {});

    var response = await http.get(url);
    _searchLoading = false;

    if (startedAt.compareTo(lastSearchResult) > 0) {
      Map<String, dynamic> marketsJson = jsonDecode(response.body);
      _searchResults = Markets.fromJson(marketsJson).items;
      lastSearchResult = startedAt;
      debugPrint(s);
      setState(() {});
    }
  }

  _updateMarkets() async {
    final prefs = await SharedPreferences.getInstance();
    final success = await prefs.setStringList(
        "market_ids", _selectedMarkets.map((e) => e.id).toList());
    debugPrint(success.toString());

    final token = await FirebaseMessaging.instance.getToken();

    await http.post(Uri.parse(API_URL + "/watch-markets"),
        body: jsonEncode({
          "markets": _selectedMarkets.map((e) => int.parse(e.id)).toList(),
          "token": token
        }));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 15),
          child: (_initLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: _selectedMarkets
                      .map((loc) => Column(children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10)),
                                color: Color(0xFF2B2C30),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(loc.name),
                                        Text(loc.address.street +
                                            ", " +
                                            loc.address.city),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      _selectedMarkets.remove(loc);
                                      setState(() {});
                                    },
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10)
                          ]))
                      .toList())),
        ),
        SizedBox(
          width: 200,
          child: ElevatedButton(
              onPressed: (_selectedMarkets.isEmpty
                  ? null
                  : () {
                      _updateMarkets();

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
          onChanged: _onSearchChange,
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
        (_searchResults.isNotEmpty
            ? Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                child: Column(
                  children: [
                    Text("${_searchResults.length} Ergebnisse"),
                  ],
                ),
              )
            : const SizedBox.shrink()),
        (_searchLoading
            ? const Center(child: CircularProgressIndicator())
            : (_searchResults.isNotEmpty
                ? SizedBox(
                    height: 300,
                    child: Scrollbar(
                      thumbVisibility: true,
                      controller: _scrollController,
                      child: ListView(
                        controller: _scrollController,
                        children: _searchResults
                            .map((m) => MyMarketTile(m, () {
                                  if (_selectedMarkets.indexWhere(
                                          (element) => element.id == m.id) ==
                                      -1) {
                                    _selectedMarkets.add(m);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content:
                                                Text("Bereits ausgewählt")));
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
      ],
    );
  }
}

class MyMarketTile extends StatelessWidget {
  MyMarketTile(this.market, this.onTap, {Key? key}) : super(key: key);

  final Market market;
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
      const SizedBox(height: 10),
    ]);
  }
}
