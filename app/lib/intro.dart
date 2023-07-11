import 'dart:convert';

import 'package:app/main.dart';
import 'package:app/market.dart';
import 'package:app/rewe_api.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyIntro extends StatefulWidget {
  const MyIntro({super.key});

  @override
  State<MyIntro> createState() => _MyIntroState();
}

enum IntroStep { selection, rewe, trinkgut, done }

class _MyIntroState extends State<MyIntro> {
  final Map<String, bool> _storeValues = {};
  final _stores = ['REWE', 'ALDI Nord', 'trinkgut'];

  List<String> _reweLocations = [];
  List<String> _trinkgutLocations = [];

  void _onStoreChange(bool newValue, String store) {
    _storeValues[store] = newValue;
    setState(() {});
  }

  void _onReweLocationsChange(List<String> newLocations) {
    _reweLocations = newLocations;
    setState(() {});
  }

  void _onTrinkgutLocationsChange(List<String> newLocations) {
    _trinkgutLocations = newLocations;
    setState(() {});
  }

  void _onContinue(IntroStep fromStep) {
    if (fromStep == IntroStep.selection) {
      if (_storeValues['REWE'] ?? false) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ReweStep(
              _reweLocations,
              _onReweLocationsChange,
              () => _onContinue(IntroStep.rewe),
            ),
          ),
        );
      } else if (_storeValues['trinkgut'] ?? false) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TrinkgutStep(
              _trinkgutLocations,
              _onTrinkgutLocationsChange,
              () => _onContinue(IntroStep.trinkgut),
            ),
          ),
        );
      } else {
        done();
      }
    } else if (fromStep == IntroStep.rewe) {
      if (_storeValues['trinkgut'] ?? false) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TrinkgutStep(
              _trinkgutLocations,
              _onTrinkgutLocationsChange,
              () => _onContinue(IntroStep.trinkgut),
            ),
          ),
        );
      } else {
        done();
      }
    } else if (fromStep == IntroStep.trinkgut) {
      done();
    }
  }

  void done() {
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setBool("is_initial_load", false));
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MyMainScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return SelectionStep(_stores, _storeValues, _onStoreChange,
        () => _onContinue(IntroStep.selection));
  }
}

class SelectionStep extends StatelessWidget {
  final List<String> stores;
  final Map<String, bool> storeValues;
  final Function(bool, String) onStoreChange;
  final Function() onContinue;
  const SelectionStep(
      this.stores, this.storeValues, this.onStoreChange, this.onContinue,
      {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(50),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'What stores are you interested in?',
                  style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Card(
                  margin: const EdgeInsets.all(0),
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15))),
                  child: ListView(
                    shrinkWrap: true,
                    children: stores
                        .map(
                          (store) => SwitchListTile(
                            title: Text(store),
                            value: storeValues[store] ?? false,
                            onChanged: (newValue) =>
                                onStoreChange(newValue, store),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                ElevatedButton(
                  onPressed: onContinue,
                  style: const ButtonStyle(
                    padding: MaterialStatePropertyAll(
                      EdgeInsets.symmetric(horizontal: 100, vertical: 0),
                    ),
                  ),
                  child: const Text("Continue",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ReweStep extends StatefulWidget {
  final List<String> locations;
  final Function(List<String>) onLocationsChange;
  final Function() onContinue;

  const ReweStep(this.locations, this.onLocationsChange, this.onContinue,
      {super.key});

  @override
  State<ReweStep> createState() => _ReweStepState();
}

class _ReweStepState extends State<ReweStep> {
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

  Future<void> _toggleMarketSelected(String marketId) async {
    final market = await fetchMarketById(marketId);
    if (market == null) return;
    if (_selectedMarkets.map((e) => e.id).contains(marketId)) {
      _selectedMarkets.removeWhere((element) => element.id == marketId);
    } else {
      _selectedMarkets.add(market);
    }
    SharedPreferences.getInstance().then((prefs) {
      prefs.setStringList(
          "selectedReweMarkets", _selectedMarkets.map((e) => e.id).toList());
    });
    setState(() {});
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
    return Container(
      color: Theme.of(context).primaryColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(50),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'What REWE locations are you interested in?',
                  style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Card(
                  margin: const EdgeInsets.all(0),
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15))),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CupertinoSearchTextField(
                            onChanged: _onReweSearchChanged,
                            placeholder: "Search for a REWE location",
                          ),
                          const SizedBox(height: 5),
                          Wrap(
                              children: _selectedMarkets
                                  .map((market) => Chip(
                                        visualDensity: VisualDensity.compact,
                                        elevation: 2,
                                        label: Text(market.name,
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall),
                                        onDeleted: () =>
                                            _unselectMarket(market.id),
                                      ))
                                  .toList()),
                          SizedBox(
                            height: 200,
                            child: _searchLoading
                                ? const Center(child: CupertinoActivityIndicator())
                                : ListView(
                                    shrinkWrap: true,
                                    children: _searchResults.map((market) {
                                      return ListTile(
                                          title: Text(market.name,
                                              overflow: TextOverflow.ellipsis),
                                          subtitle: Text(
                                              "${market.addressLine1}, ${market.addressLine2}",
                                              overflow: TextOverflow.ellipsis),
                                          selected: _selectedMarkets
                                              .map((e) => e.id)
                                              .contains(market.id),
                                          onTap: () =>
                                              _toggleMarketSelected(market.id));
                                    }).toList()),
                          ),
                        ]),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                ElevatedButton(
                  onPressed: widget.onContinue,
                  style: const ButtonStyle(
                    padding: MaterialStatePropertyAll(
                      EdgeInsets.symmetric(horizontal: 100, vertical: 0),
                    ),
                  ),
                  child: const Text("Continue",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TrinkgutStep extends StatelessWidget {
  final List<String> locations;
  final Function(List<String>) onLocationsChange;
  final Function() onContinue;

  const TrinkgutStep(this.locations, this.onLocationsChange, this.onContinue,
      {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(50),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'What trinkgut locations are you interested in?',
                  style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Card(
                  margin: const EdgeInsets.all(0),
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15))),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(children: [
                      const CupertinoSearchTextField(),
                      SizedBox(
                        height: 200,
                        child: ListView(
                          shrinkWrap: true,
                          children: const [],
                        ),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                ElevatedButton(
                  onPressed: onContinue,
                  style: const ButtonStyle(
                    padding: MaterialStatePropertyAll(
                      EdgeInsets.symmetric(horizontal: 100, vertical: 0),
                    ),
                  ),
                  child: const Text("Continue",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
