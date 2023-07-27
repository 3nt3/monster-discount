import 'dart:convert';

import 'package:app/market.dart';
import 'package:app/rewe_api.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:app/main.dart';

import 'package:shared_preferences/shared_preferences.dart';

class MySettingsPage extends StatefulWidget {
  const MySettingsPage({super.key});

  @override
  State<MySettingsPage> createState() => _MySettingsPageState();
}

class _MySettingsPageState extends State<MySettingsPage> {
  final _storeValues = {};
  final _stores = ['REWE', 'ALDI Nord', 'trinkgut'];

  List<Market> _selectedMarkets = [];

  // whether the market info (address, name etc.) for already selected locations  is currently loading
  bool _marketsLoading = true;

  bool _searchLoading = false;
  // final bool _initLoading = false;
  final _reweSearchUrl =
      "https://mobile-api.rewe.de/mobile/markets/market-search";

  List<CompactMarket> _searchResults = [];
  // avoid slower requests overwriting newer results
  DateTime lastSearchResult = DateTime.now();

  @override
  void initState() {
    super.initState();

    SharedPreferences.getInstance().then((prefs) {
      for (var store in _stores) {
        _storeValues[store] = prefs.getBool(store) ?? false;
      }
      setState(() {});
      Future.wait<Market?>((prefs.getStringList("selectedReweMarkets") ?? [])
          .map((e) => fetchMarketById(e))).then((markets) {
        _selectedMarkets = markets.whereType<Market>().toList();
        _marketsLoading = false;
        setState(() {});
      });
    });
  }

  void _onStoreChange(bool newValue, String store) {
    _storeValues[store] = newValue;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool(store, newValue);
    });
    setState(() {});
  }

  Future<void> _selectReweMarket(String marketId) async {
    final market = await fetchMarketById(marketId);
    if (market != null && !_selectedMarkets.map((e) => e.id).contains(marketId)) {
      _selectedMarkets.add(market);
      SharedPreferences.getInstance().then((prefs) {
        prefs.setStringList(
            "selectedReweMarkets", _selectedMarkets.map((e) => e.id).toList());
      });
      setState(() {});
    }
  }

  void _onReweSearchChanged(String value) async {
    var startedAt = DateTime.now();
    var url = Uri.parse("$_reweSearchUrl?query=$value");
    _searchLoading = true;
    setState(() {});

    debugPrint("searching for $value");

    try {
      // make http2 request to rewe api
      final bodyString =
          await reweApiCall("GET", "/api/v3/market/search?search=$value");

      _searchLoading = false;

      if (startedAt.compareTo(lastSearchResult) > 0) {
        Map<String, dynamic> body = jsonDecode(bodyString!);
        _searchResults = Markets.fromJson(body).markets;
        lastSearchResult = startedAt;
        debugPrint(value);
        setState(() {});
      }
    } catch (e) {
      _searchLoading = false;
      debugPrint(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed querying rewe: ${e.toString()}")));
    }
  }

  void _unselectMarket(String marketId) {
    _selectedMarkets.removeWhere((element) => element.id == marketId);
    SharedPreferences.getInstance().then((prefs) {
      prefs.setStringList(
          "selectedReweMarkets", _selectedMarkets.map((e) => e.id).toList());
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text("Settings", style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 10),
          Text("Stores", style: Theme.of(context).textTheme.headlineSmall),
          ListView(
            shrinkWrap: true,
            children: _stores
                .map(
                  (store) => SwitchListTile(
                    title: Text(store),
                    value: _storeValues[store] ?? false,
                    onChanged: (newValue) => _onStoreChange(newValue, store),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          if (_storeValues['REWE'] ?? false) ...[
            Row(
              children: [
                Text("REWE Locations",
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(width: 5),
                if (_selectedMarkets.isNotEmpty)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: const BorderRadius.all(
                        Radius.circular(10),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(_selectedMarkets.length.toString(),
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge!
                              .copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSecondary)),
                    ),
                  ),
                const SizedBox(width: 10),
                if (_searchLoading || _marketsLoading)
                  const CupertinoActivityIndicator(),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                    children: _selectedMarkets.map((market) {
                  return ListTile(
                    title: Text(market.name, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                        "${market.address.street}, ${market.address.city}"),
                    trailing: IconButton(
                        onPressed: () => _unselectMarket(market.id),
                        icon: const Icon(Icons.delete)),
                  );
                }).toList()),
                CupertinoSearchTextField(onChanged: _onReweSearchChanged),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                      _searchResults.isNotEmpty
                          ? "${_searchResults.length} results"
                          : "",
                      style: Theme.of(context).textTheme.labelSmall),
                ),
                if (_searchResults.isNotEmpty)
                  SizedBox(
                    height: 200,
                    child: Scrollbar(
                      interactive: true,
                      child: ListView(
                          shrinkWrap: true,
                          children: _searchResults.map((market) {
                            return ListTile(
                                title: Text(market.name),
                                subtitle: Text(
                                    "${market.addressLine1}, ${market.addressLine2}"),
                                onTap: () => _selectReweMarket(market.id));
                          }).toList()),
                    ),
                  ),
              ],
            )
          ],
          Text("Reset App", style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 10),
          ElevatedButton(
            child: const Text("Reset App"),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => CupertinoAlertDialog(
                  title: const Text("Sure?"),
                  actions: [
                    CupertinoDialogAction(
                      child: const Text("Abort"),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    CupertinoDialogAction(
                      isDestructiveAction: true,
                      child: const Text("Reset"),
                      onPressed: () {
                        SharedPreferences.getInstance().then((prefs) {
                          prefs.clear();
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const MyApp()));
                        });
                      },
                    )
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
