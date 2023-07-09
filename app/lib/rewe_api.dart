import 'dart:convert';

import 'package:app/market.dart';
import 'package:app/offers.dart';
import 'package:flutter_curl/flutter_curl.dart';
import 'package:flutter/material.dart';

// necessary because the http2 library needs a lot of "boilerplate"
Future<String?> reweApiCall(String method, String path,
    {bool noApiBase = false, Map<String, String>? headers}) async {
  const reweApiBase = "https://mobile-api.rewe.de";
  // const reweApiBase = "https://google.com";

  Client client = Client(
    verbose: true,
    interceptors: [
      // HTTPCaching(),
    ],
    timeout: const Duration(seconds: 10),
  );
  await client.init();

  final url = (noApiBase ? "" : reweApiBase) + path;

  final res = await client.send(
    Request(
      verbose: true,
      method: "GET",
      url: url,
      verifySSL: false, // something seems to be broken here lol
      headers: {
        "user-agent": "REWE-Mobile-App/3.4.56 Android/11 (Smartphone)",
        ...?headers
      },
    ),
  );

  // Read response
  if (res.statusCode == 200) {
    return res.text();
  } else {
    debugPrint("Error while fetching $url");
    debugPrint("Error: ${res.errorMessage}");
    debugPrint("Status: ${res.statusCode}");

    // print all headers
    res.headers.forEach((key, value) {
      debugPrint("$key: $value");
    });

    throw Exception(res.errorMessage ?? "Error while fetching $path");
  }
}

Future<Market?> fetchMarketById(String marketId) async {
  final body = await reweApiCall("GET", "/mobile/markets/markets/$marketId");
  debugPrint(body);
  return Market.fromJson(jsonDecode(body!));
}

Future<Offers?> fetchOffersByMarketId(String marketId) async {
  // let http_builder = http_client
  //     .get("https://mobile-api.rewe.de/api/v3/all-offers")
  //     .query(&[("marketCode", market_id)])
  //     .header("ruleversion", "3")
  //     .header("rd-market-id", market_id)
  //     // .header("accept-encoding", "gzip")
  //     .header(
  //         "User-Agent",
  //         "REWE-Mobile-App/3.4.56 Android/11 (Smartphone)",
  //     );
  final body = await reweApiCall(
      "GET", "/api/v3/all-offers?marketCode=$marketId",
      headers: {
        "ruleversion": "3",
        "rd-market-id": marketId,
        "User-Agent": "REWE-Mobile-App/3.4.56 Android/11 (Smartphone)",
      });
  var decoded = jsonDecode(body!);

  // print all keys
  decoded.keys.forEach((key) {
    debugPrint(key);
  });

  return Offers.fromJson(jsonDecode(body));
}

Future<double?> fetchMonsterPrice(String marketId) async {
  final body = await reweApiCall("GET",
      "/api/v3/product-search?searchTerm=monster&page=1&sorting=RELEVANCE_DESC&objectsPerPage=20&marketCode=$marketId&serviceTypes=PICKUP",
      // "/api/v3/product-search?searchTerm=monster&marketCode=$marketId&page=1&sorting=RELEVANCE_DESC&objectsPerPage=20&serviceTypes=PICKUP",
      headers: {
        "rd-market-id": marketId,
        "rd-service-types": "PICKUP",
        "x-rd-service-types": "PICKUP",
        "rd-customer-zip": "42781", // rewe doesn't seem to care about this
        "x-rd-customer-zip": "42781",
        "User-Agent": "REWE-Mobile-App/3.4.56 Android/11 (Smartphone)",
      });

  final searchResults = SearchResults.fromJson(jsonDecode(body!));

  // return first products price
  if (searchResults.products.isEmpty) {
    return null;
  }
  final priceString = searchResults.products[0].currentPrice;
  final price =
      double.tryParse(priceString.replaceAll(",", ".").replaceAll("€", ""));

  debugPrint("Monster price: $price");

  return price;
}



// Future<List<Market>?> _searchMarkets(String query) async {
//   return reweApiCall("GET", "/mobile/markets/market-search?query=$query");
// }
//
// Future<Market?> _fetchMarketById(String marketId) async {
//   return reweApiCall(
//       "https://mobile-api.rewe.de/mobile/markets/markets/$marketId",
//       (json) => Market.fromJson(json));
// }
