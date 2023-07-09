import 'dart:convert';

import 'package:app/api.dart';
import 'package:app/market.dart';
import 'package:app/offers.dart';
import 'package:app/rewe_api.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
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
                  IconButton(onPressed: () {}, icon: const Icon(Icons.edit))
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
  double? _bestPrice = 0.0;
  List<String> _marketIds = [];
  List<Market> _markets = [];

  Map<String, double?> _monsterPrices = {};
  List<Offer> _reweOffers = [];
  bool _offersLoading = true;
  bool _marketsLoading = true;

  @override
  void initState() {
    super.initState();

    () async {
      await _fetchMarketIds();
      _fetchOffers();
      _fetchMarkets();
    }();
  }

  void _fetchOffers() async {
    _offersLoading = true;
    _reweOffers = [];
    setState(() {});
    for (var marketCode in _marketIds) {
      try {
        _monsterPrices[marketCode] = await fetchMonsterPrice(marketCode);

        var response = await fetchOffersByMarketId(marketCode);
        if (response == null) {
          debugPrint("no response from rewe");
          _offersLoading = false;
          return;
        }

        _reweOffers += response.categories
            .fold<List<Offer>>(
                [], (List<Offer> prev, elem) => prev + elem.offers)
            .where((element) => element.title.toLowerCase().contains('monster'))
            .toList();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error querying rewe: ${e.toString()}")));
        _offersLoading = false;
      }
    }
    _offersLoading = false;
    debugPrint("rewe offers: $_reweOffers");
    setState(() {});
  }

  void _fetchMarkets() async {
    _markets = [];
    _marketsLoading = true;
    setState(() {});
    for (var marketCode in _marketIds) {
      try {
        var response = await fetchMarketById(marketCode);
        if (response == null) {
          debugPrint("no response from rewe");
          return;
        }
        _markets.add(response);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error querying rewe: ${e.toString()}")));
      }
    }
    _marketsLoading = false;
    setState(() {});
  }

  Future<void> _fetchMarketIds() async {
    final prefs = await SharedPreferences.getInstance();
    final marketIds = prefs.getStringList("selectedReweMarkets");
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
      child: (_offersLoading || _marketsLoading)
          ? const CupertinoActivityIndicator()
          : ListView(
              shrinkWrap: false,
              scrollDirection: Axis.horizontal,
              children: _monsterPrices.entries
                  .map(
                    (entry) => MyPriceTile(
                        price: entry.value,
                        market: _markets
                            .firstWhere((element) => element.id == entry.key),
                        isOptimal: entry.value ==
                            _monsterPrices.values.reduce((value, element) =>
                                (value != null && element != null)
                                    ? value < element
                                        ? value
                                        : element
                                    : value)),
                  )
                  .toList(),
            ),
    );
  }
}

class MyPriceTile extends StatelessWidget {
  final double? price;
  final bool isOptimal;
  final Market market;
  const MyPriceTile(
      {super.key,
      required this.price,
      required this.market,
      required this.isOptimal});

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
                        price != null ? "${price!.toStringAsFixed(2)} €" : "N/A",
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                                color: isOptimal ? Colors.white : null,
                                fontWeight: isOptimal ? FontWeight.bold : null),
                      )),
                  Text("${market.address.street}, ${market.address.city}",
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall),
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
  final List<CompactMarket> _selectedMarkets = [];

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
