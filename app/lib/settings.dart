import 'dart:convert';

import 'package:app/market.dart';
import 'package:app/rewe_api.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;

class MySettingsPage extends StatefulWidget {
  const MySettingsPage({super.key});

  @override
  State<MySettingsPage> createState() => _MySettingsPageState();
}

class _MySettingsPageState extends State<MySettingsPage> {
  final _storeValues = {};
  final _stores = ['REWE', 'ALDI Nord', 'trinkgut'];

  bool _searchLoading = false;
  final bool _initLoading = false;
  final _reweSearchUrl =
      "https://mobile-api.rewe.de/mobile/markets/market-search";

  List<Market> _searchResults = [];
  // avoid slower requests overwriting newer results
  DateTime lastSearchResult = DateTime.now();
  DateTime lastSearchQuery = DateTime.now();

  void _onStoreChange(bool newValue, String store) {
    _storeValues[store] = newValue;
    setState(() {});
  }

  void _onReweSearchChanged(String value) async {
    if (lastSearchQuery.difference(DateTime.now()).inMilliseconds > -700) {
      lastSearchQuery = DateTime.now();
      debugPrint("skipping search for $value");
      return;
    }
    lastSearchQuery = DateTime.now();

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

  Future<Market?> _fetchMarketById(String marketId) async {
    try {
      final resp = await http.get(Uri.parse(
          "https://mobile-api.rewe.de/mobile/markets/markets/$marketId"));

      final marketJson = jsonDecode(resp.body);
      return Market.fromJson(marketJson);
    } catch (e) {
      debugPrint(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed querying rewe: ${e.toString()}")));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text("Settings", style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 10),
        Text("Active Stores", style: Theme.of(context).textTheme.headlineSmall),
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
        Row(
          children: [
            Text("REWE Locations",
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(width: 10),
            if (_searchLoading) const CupertinoActivityIndicator(),
          ],
        ),
        const SizedBox(height: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CupertinoSearchTextField(onChanged: _onReweSearchChanged),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                  _searchResults.isNotEmpty
                      ? "${_searchResults.length} results"
                      : "",
                  style: Theme.of(context).textTheme.labelSmall),
            ),
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
                        onTap: () async {
                          // var marketDetails = await _fetchMarketById(market.id);
                          // Navigator.of(context).pushNamed('/market',
                          //     arguments: {'market': marketDetails});
                        },
                      );
                    }).toList()),
              ),
            ),
          ],
        ),

        // Text("Reset App", style: Theme.of(context).textTheme.headlineSmall),
        // const SizedBox(height: 10),
        // ElevatedButton(
        //   child: const Text("Reset App"),
        //   onPressed: () {
        //     showDialog(
        //       context: context,
        //       builder: (context) => CupertinoAlertDialog(
        //         title: const Text("Sure?"),
        //         actions: [
        //           CupertinoDialogAction(
        //             child: const Text("Abort"),
        //             onPressed: () => Navigator.of(context).pop(),
        //           ),
        //           const CupertinoDialogAction(
        //             isDestructiveAction: true,
        //             child: Text("Reset"),
        //           )
        //         ],
        //       ),
        //     );
        //   },
        // ),
      ],
    );
  }
}
