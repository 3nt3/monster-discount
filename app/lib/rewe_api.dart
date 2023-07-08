import 'dart:convert';

import 'package:app/market.dart';
import 'package:flutter_curl/flutter_curl.dart';
import 'package:flutter/material.dart';

// necessary because the http2 library needs a lot of "boilerplate"
Future<String?> reweApiCall(String method, String path) async {
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

  final res = await client.send(
    Request(
      verbose: true,
      method: "GET",
      url: reweApiBase + path,
      verifySSL: false, // something seems to be broken here lol
      headers: {
        "user-agent":
            "REWE-Mobile-Client/3.10.2.27236 Android/10 Phone/Google_Android_SDK_built_for_arm64"
      },
    ),
  );

  // Read response
  if (res.statusCode == 200) {
    return res.text();
  } else {
    debugPrint("Error while fetching $reweApiBase$path");
    debugPrint("Error: ${res.errorMessage}");
    debugPrint("Status: ${res.statusCode}");
    debugPrint(res.text());

    throw Exception(res.errorMessage ?? "Error while fetching $path");
  }

  return null;
}

Future<Market?> fetchMarketById(String marketId) async {
  final body = await reweApiCall("GET", "/mobile/markets/markets/$marketId");
  debugPrint(body);
  return Market.fromJson(jsonDecode(body!));
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
