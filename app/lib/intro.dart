import 'package:app/home.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
              _reweLocations,
              _onReweLocationsChange,
              () => _onContinue(IntroStep.trinkgut),
            ),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const MyHomePage(),
          ),
        );
      }
    } else if (fromStep == IntroStep.rewe) {
      if (_storeValues['trinkgut'] ?? false) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TrinkgutStep(
              _reweLocations,
              _onReweLocationsChange,
              () => _onContinue(IntroStep.trinkgut),
            ),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const MyHomePage(),
          ),
        );
      }
    } else if (fromStep == IntroStep.trinkgut) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const MyHomePage(),
        ),
      );
    }
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

class ReweStep extends StatelessWidget {
  final List<String> locations;
  final Function(List<String>) onLocationsChange;
  final Function() onContinue;

  const ReweStep(this.locations, this.onLocationsChange, this.onContinue,
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
                    padding: EdgeInsets.all(10),
                    child: Column(children: [
                      CupertinoSearchTextField(),
                      SizedBox(
                        height: 200,
                        child: ListView(
                          shrinkWrap: true,
                          children: [],
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
                    padding: EdgeInsets.all(10),
                    child: Column(children: [
                      CupertinoSearchTextField(),
                      SizedBox(
                        height: 200,
                        child: ListView(
                          shrinkWrap: true,
                          children: [],
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
