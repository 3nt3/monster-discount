import 'package:app/intro.dart';
import 'package:app/settings.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:google_fonts/google_fonts.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'home.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();

  debugPrint("Handling a background message: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _isInitialLoad = true;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0x00b8e994), brightness: Brightness.light),
        fontFamily: GoogleFonts.ptSerif().fontFamily,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0x00b8e994), brightness: Brightness.dark),
        fontFamily: GoogleFonts.ptSerif().fontFamily,
      ),
      home: !_isInitialLoad
          ? MyMainScreen()
          : Scaffold(
              body: MyIntro(),
            ),
    );
  }
}

class MyMainScreen extends StatefulWidget {
  const MyMainScreen({super.key});

  @override
  State<MyMainScreen> createState() => _MyMainScreenState();
}

class _MyMainScreenState extends State<MyMainScreen> {
  final _pages = [const MyHomePage(), const MySettingsPage()];

  var _currentIndex = 0;
  var _isInitialLoad = true;

  void _onBottomBarTapped(int index) {
    _currentIndex = index;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Monster Dinge™️")),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: _onBottomBarTapped,
        currentIndex: _currentIndex,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "home"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "settings")
        ],
      ),
    );
  }
}

// class MyReweWidget extends StatefulWidget {
//   const MyReweWidget({Key? key}) : super(key: key);
//
//   @override
//   _MyReweWidgetState createState() => _MyReweWidgetState();
// }
//
// class _MyReweWidgetState extends State<MyReweWidget> {
//   List<Market> _selectedMarkets = [];
//
//   bool _searchLoading = false;
//   bool _initLoading = false;
//   final _url = "https://mobile-api.rewe.de/mobile/markets/market-search";
//   List<Market> _searchResults = [];
//   DateTime lastSearchResult = DateTime.now();
//
//   final TextEditingController _controller = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//
//   _fetchPrefs() async {
//     final prefs = await SharedPreferences.getInstance();
//
//     final maybeIds = prefs.getStringList("market_ids");
//     debugPrint(maybeIds.toString());
//     if (maybeIds == null) {
//       return;
//     }
//     _initLoading = true;
//     _selectedMarkets = [];
//     setState(() {});
//
//     for (var marketId in maybeIds) {
//       final market = await _fetchMarketById(marketId);
//       if (market == null) {
//         continue;
//       }
//       _selectedMarkets.add(market);
//       setState(() {});
//     }
//
//     Navigator.push(
//         context,
//         MaterialPageRoute(
//             builder: (context) => OffersPage(
//                 _selectedMarkets.map<String>((m) => m.id).toList())));
//
//     _initLoading = false;
//     setState(() {});
//   }
//
//   Future<Market?> _fetchMarketById(String marketId) async {
//     try {
//       final resp = await http.get(Uri.parse(
//           "https://mobile-api.rewe.de/mobile/markets/markets/$marketId"));
//
//       final marketJson = jsonDecode(resp.body);
//       return Market.fromJson(marketJson);
//     } catch (e) {
//       debugPrint("ASDF");
//       ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("error querying rewe: ${e.toString()}")));
//     }
//     return null;
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchPrefs();
//   }
//
//   _onSearchChange(String s) async {
//     var startedAt = DateTime.now();
//     var url = Uri.parse(_url + "?query=" + s);
//     _searchLoading = true;
//     setState(() {});
//
//     try {
//       var response = await http.get(url);
//       _searchLoading = false;
//
//       if (startedAt.compareTo(lastSearchResult) > 0) {
//         Map<String, dynamic> marketsJson = jsonDecode(response.body);
//         _searchResults = Markets.fromJson(marketsJson).items;
//         lastSearchResult = startedAt;
//         debugPrint(s);
//         setState(() {});
//       }
//     } catch (e) {
//       _searchLoading = false;
//       ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("error querying rewe: ${e.toString()}")));
//     }
//   }
//
//   _updateMarkets() async {
//     final prefs = await SharedPreferences.getInstance();
//     final success = await prefs.setStringList(
//         "market_ids", _selectedMarkets.map((e) => e.id).toList());
//     debugPrint(success.toString());
//
//     final token = await FirebaseMessaging.instance.getToken();
//
//     await http.post(Uri.parse(API_URL + "/watch-markets"),
//         body: jsonEncode({
//           "markets": _selectedMarkets.map((e) => int.parse(e.id)).toList(),
//           "token": token,
//           "wants_aldi": true
//         }));
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.only(top: 15),
//           child: (_initLoading
//               ? const Center(child: CircularProgressIndicator())
//               : Column(
//                   children: _selectedMarkets
//                       .map((loc) => Column(children: [
//                             Container(
//                               padding: const EdgeInsets.all(10),
//                               decoration: const BoxDecoration(
//                                 borderRadius:
//                                     BorderRadius.all(Radius.circular(10)),
//                                 color: Color(0xFF2B2C30),
//                               ),
//                               child: Row(
//                                 children: [
//                                   Expanded(
//                                     child: Column(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         Text(loc.name),
//                                         Text(loc.address.street +
//                                             ", " +
//                                             loc.address.city),
//                                       ],
//                                     ),
//                                   ),
//                                   IconButton(
//                                     onPressed: () {
//                                       _selectedMarkets.remove(loc);
//                                       setState(() {});
//                                     },
//                                     icon: const Icon(Icons.delete,
//                                         color: Colors.red),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                             const SizedBox(height: 10)
//                           ]))
//                       .toList())),
//         ),
//         SizedBox(
//           width: 200,
//           child: ElevatedButton(
//               onPressed: (_selectedMarkets.isEmpty
//                   ? null
//                   : () {
//                       _updateMarkets();
//
//                       Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                               builder: (context) => OffersPage(_selectedMarkets
//                                   .map<String>((m) => m.id)
//                                   .toList())));
//                     }),
//               child: const Text("Angebote checken")),
//         ),
//         TextFormField(
//           onChanged: _onSearchChange,
//           decoration: InputDecoration(
//             prefixIcon: const Icon(Icons.search),
//             prefixIconColor: Colors.white,
//             suffixIcon: _controller.text.isEmpty
//                 ? null
//                 : IconButton(
//                     onPressed: () {
//                       _controller.clear();
//                     },
//                     icon: const Icon(Icons.clear)),
//           ),
//         ),
//         (_searchResults.isNotEmpty
//             ? Padding(
//                 padding:
//                     const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
//                 child: Column(
//                   children: [
//                     Text("${_searchResults.length} Ergebnisse"),
//                   ],
//                 ),
//               )
//             : const SizedBox.shrink()),
//         (_searchLoading
//             ? const Center(child: CircularProgressIndicator())
//             : (_searchResults.isNotEmpty
//                 ? SizedBox(
//                     height: 300,
//                     child: Scrollbar(
//                       thumbVisibility: true,
//                       controller: _scrollController,
//                       child: ListView(
//                         controller: _scrollController,
//                         children: _searchResults
//                             .map((m) => MyMarketTile(m, () {
//                                   if (_selectedMarkets.indexWhere(
//                                           (element) => element.id == m.id) ==
//                                       -1) {
//                                     _selectedMarkets.add(m);
//                                   } else {
//                                     ScaffoldMessenger.of(context).showSnackBar(
//                                         const SnackBar(
//                                             content:
//                                                 Text("Bereits ausgewählt")));
//                                   }
//                                   setState(() {});
//                                 }))
//                             .toList(),
//                         scrollDirection: Axis.vertical,
//                         shrinkWrap: true,
//                       ),
//                     ),
//                   )
//                 : const Center(
//                     child: Text("Keine Ergebnisse"),
//                   ))),
//       ],
//     );
//   }
// }
//
// class MyMarketTile extends StatelessWidget {
//   const MyMarketTile(this.market, this.onTap, {Key? key}) : super(key: key);
//
//   final Market market;
//   final void Function() onTap;
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//       InkWell(
//         onTap: onTap,
//         child: Container(
//           width: 10000,
//           decoration: const BoxDecoration(
//               borderRadius: BorderRadius.all(Radius.circular(10)),
//               color: Color(0xFF2B2C30)),
//           child: Padding(
//             padding: const EdgeInsets.all(10),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(market.name),
//                 Text(market.address.street),
//                 Text(market.address.city),
//               ],
//             ),
//           ),
//         ),
//       ),
//       const SizedBox(height: 10),
//     ]);
//   }
// }
//
// class MyPrecariatWidget extends StatefulWidget {
//   const MyPrecariatWidget({
//     Key? key,
//   }) : super(key: key);
//
//   // This widget is the home page of your application. It is stateful, meaning
//   // that it has a State object (defined below) that contains fields that affect
//   // how it looks.
//
//   // This class is the configuration for the state. It holds the values (in this
//   // case the title) provided by the parent (in this case the App widget) and
//   // used by the build method of the State. Fields in a Widget subclass are
//   // always marked "final".
//
//   @override
//   State<MyPrecariatWidget> createState() => _MyPrecariatWidgetState();
// }
//
// class _MyPrecariatWidgetState extends State<MyPrecariatWidget> {
//   var stores = {
//     'trinkgut': true,
//   };
//
//   void _onPressed(String storeName) {
//     stores[storeName] = !stores[storeName]!;
//     setState(() {});
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return GridView.count(
//       crossAxisCount: 2,
//       shrinkWrap: true,
//       children: stores.entries
//           .map(
//             (entry) => TextButton(
//               onPressed: () => _onPressed(entry.key),
//               child: Text(entry.key,
//                   style: TextStyle(
//                     color: Color(0xfffffffff),
//                     fontSize: 40,
//                   )),
//             ),
//           )
//           .toList(),
//     );
//   }
// }
//
