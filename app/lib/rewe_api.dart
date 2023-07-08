import 'package:flutter_curl/flutter_curl.dart';
import 'package:flutter/material.dart';

// necessary because the http2 library needs a lot of "boilerplate"
Future<String?> reweApiCall(String method, String path) async {
  const reweApiBase = "https://mobile-api.rewe.de";

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
  }

  return null;
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
