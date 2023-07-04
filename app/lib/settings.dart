import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class MySettingsPage extends StatefulWidget {
  const MySettingsPage({super.key});

  @override
  State<MySettingsPage> createState() => _MySettingsPageState();
}

class _MySettingsPageState extends State<MySettingsPage> {
  var _storeValues = {};
  final _stores = ['REWE', 'ALDI Nord', 'trinkgut'];

  void _onStoreChange(bool newValue, String store) {
    _storeValues[store] = newValue;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(20),
      children: [
        Text("Settings", style: Theme.of(context).textTheme.headlineMedium),
        SizedBox(height: 10),
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
        // children: [
        //   CupertinoListTile(
        //       title: Text("REWE"),
        //       trailing:
        //           CupertinoSwitch(value: false, onChanged: _onStoreChange)),
        //   CupertinoListTile(title: Text("ALDI Nord")),
        //   CupertinoListTile(title: Text("Trinkgut")),
        // ],
      ],
    );
  }
}
