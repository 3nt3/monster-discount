import 'dart:convert';

import 'package:app/api.dart';
import 'package:app/market.dart';
import 'package:app/offers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

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
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: SizedBox.expand(
          child: ListView(
            padding: const EdgeInsets.all(20),
            shrinkWrap: true,
            children: [
              Text('Monster Prices',
                  style: Theme.of(context).textTheme.headlineMedium),
              const MyPricesWidget(),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text('REWE Locations',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const Spacer(),
                  IconButton(
                      onPressed: () {
                        // TODO: actually navigate to settings or something
                      },
                      icon: const Icon(Icons.edit))
                ],
              ),
              const MyReweLocations(),
              const SizedBox(height: 20),
              // Text('Trinkgut Locations',
              //     style: Theme.of(context).textTheme.headlineMedium),
            ],
          ),
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
  final _prices = [0.99, 1.49, 1.19];
  final _bestPrice = 0.0;
  List<String> _marketIds = [];

  // FIXME: don't hardcode this
  final _regularRewePrice = 1.69;
  List<Offer> _reweOffers = [];
  final _reweUrl = "https://mobile-api.rewe.de/api/v3/all-offers";
  bool _loading = false;

  void _fetchOffers() async {
    _loading = true;
    _reweOffers = [];
    setState(() {});
    for (var marketCode in _marketIds) {
      try {
        var uri = Uri.parse("$_reweUrl?marketCode=$marketCode");
        var response = await http.get(uri);
        var offersJson = jsonDecode(response.body);
        _reweOffers += Offers.fromJson(offersJson)
            .categories
            .fold<List<Offer>>(
                [], (List<Offer> prev, elem) => prev + elem.offers)
            .where((element) => element.title.toLowerCase().contains('monster'))
            .toList();
        debugPrint(_reweOffers.toString());
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("error querying rewe: ${e.toString()}")));
        _loading = false;
      } finally {
        setState(() {});
      }
    }
    _loading = false;
  }

  @override
  void initState() {
    super.initState();

    _fetchMarketIds();
  }

  void _fetchMarketIds() async {
    final prefs = await SharedPreferences.getInstance();
    final marketIds = prefs.getStringList("market_ids");
    if (marketIds != null) {
      _marketIds = marketIds;
    }
    debugPrint("market ids: $_marketIds");

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
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      padding: EdgeInsets.all(isOptimal ? 5 : 0),
                      decoration: BoxDecoration(
                        color: isOptimal ? Colors.red.shade300 : null,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(8),
                        ),
                      ),
                      child: Text(
                        "$price €",
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                                color: isOptimal ? Colors.white : null,
                                fontWeight: isOptimal ? FontWeight.bold : null),
                      )),
                  const Text("REWE Haan"),
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

class MyReweLocations extends StatefulWidget {
  const MyReweLocations({super.key});

  @override
  State<MyReweLocations> createState() => _MyReweLocationsState();
}

class _MyReweLocationsState extends State<MyReweLocations> {
  // final _locations = ['dieker strasse', 'unten'];
  final List<Market> _selectedMarkets = [];

  _updateLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final success = await prefs.setStringList(
        "market_ids", _selectedMarkets.map((e) => e.id).toList());
    debugPrint(success.toString());

    final token = await FirebaseMessaging.instance.getToken();

    await http.post(Uri.parse("$API_URL/watch-markets"),
        body: jsonEncode({
          "markets": _selectedMarkets.map((e) => int.parse(e.id)).toList(),
          "token": token,
          "wants_aldi": true
        }));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: _selectedMarkets
          .map(
            (location) => Card(
              child: ListTile(
                title: Text(location.name),
              ),
            ),
          )
          .toList(),
    );
  }
}
