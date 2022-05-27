import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:transparent_image/transparent_image.dart';

import 'offers.dart';

class OffersPage extends StatefulWidget {
  final List<String> marketCodes;

  const OffersPage(this.marketCodes, {Key? key}) : super(key: key);

  @override
  _OffersPageState createState() => _OffersPageState();
}

class _OffersPageState extends State<OffersPage> {
  @override
  void initState() {
    super.initState();

    _getOffers();
  }

  List<Offer> _offers = [];
  final _url = "https://mobile-api.rewe.de/api/v3/all-offers";
  bool _loading = false;

  void _getOffers() async {
    _loading = true;
    _offers = [];
    setState(() {});
    for (var marketCode in widget.marketCodes) {
      var uri = Uri.parse(_url + "?marketCode=" + marketCode);
      var response = await http.get(uri);
      var offersJson = jsonDecode(response.body);
      _offers += Offers.fromJson(offersJson)
          .categories
          .fold<List<Offer>>([], (List<Offer> prev, elem) => prev + elem.offers)
          .where((element) => element.title.toLowerCase().contains('monster'))
          .toList();
      debugPrint(_offers.toString());
      setState(() {});
    }
    _loading = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Column(
              children: [
                Text('Anjebóte (nur monster)',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 50),
                _loading
                    ? Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: () async {
                          _getOffers();
                        },
                        child: _offers.isNotEmpty
                            ? GridView.count(
                                crossAxisCount: 2,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                shrinkWrap: true,
                                childAspectRatio: 0.7,
                                children: _offers
                                    .map(
                                      (e) => (Container(
                                        decoration: BoxDecoration(
                                            color: Color(0xFF2B2C30),
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        padding: EdgeInsets.all(20),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            (e.images.isNotEmpty
                                                ? Image.network(
                                                    e.images[0],
                                                    loadingBuilder: (context,
                                                        child,
                                                        loadingProgress) {
                                                      if (loadingProgress ==
                                                          null) {
                                                        return child;
                                                      } else {
                                                        return CircularProgressIndicator();
                                                      }
                                                    },
                                                  )
                                                : Text("no image")),
                                            Text(e.title),
                                            Text(
                                              (e.priceData.price ??
                                                  "NaN") + "€",
                                              style: TextStyle(
                                                  fontFamily: 'Nunito',
                                                  fontSize: 24),
                                            ),
                                          ],
                                        ),
                                      )),
                                    )
                                    .toList())
                            : Center(
                                child: Text('monster is nicht im angebot :('))),
              ],
            )),
      ),
    );
  }
}
