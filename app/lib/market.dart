import 'package:json_annotation/json_annotation.dart';

/// This allows the `User` class to access private members in
/// the generated file. The value for this is *.g.dart, where
/// the star denotes the source file name.
part 'market.g.dart';

/// An annotation for the code generator to know that this class needs the
/// JSON serialization logic to be generated.
@JsonSerializable()
class Markets {
  Markets(this.markets);

  List<CompactMarket> markets;

  factory Markets.fromJson(Map<String, dynamic> json) =>
      _$MarketsFromJson(json);
  Map<String, dynamic> toJson() => _$MarketsToJson(this);
}

@JsonSerializable()
class CompactMarket {
  CompactMarket(this.id, this.name, this.addressLine1, this.addressLine2);

  // {
  //    "id": "1470067",
  //    "name": "Frank Conrad Einzelhandels oHG",
  //    "typeId": "MARKET",
  //    "addressLine1": "Hochdahler Str. 2",
  //    "addressLine2": "42781 Haan",
  //    "location": {
  //      "latitude": 51.18723,
  //      "longitude": 6.99009
  //    },
  //    "featureTypes": [],
  //    "rawValues": {
  //      "attributes": [],
  //      "postalCode": "42781",
  //      "city": "Haan"
  //    }
  //  }

  String id;
  String name;
  String addressLine1;
  String addressLine2;

  factory CompactMarket.fromJson(Map<String, dynamic> json) => _$CompactMarketFromJson(json);

  Map<String, dynamic> toJson() => _$CompactMarketToJson(this);
}

@JsonSerializable()
class Market {
  Market(this.id, this.name, this.address);

// {"id":"1940156","name":"REWE Markt GmbH","type":{"name":"REWE Markt","id":"rewe"},"address":{"street":"Dieker Str. 101","postalCode":"42781","city":"Haan"},"phone":"02129-957453","geoLocation":{"latitude":51.19405,"longitude":7.01176},"company":{"name":"REWE Markt GmbH - West -","city":"Hürth","zipCode":"50354","street":"Rewestr. 8"},"advertisingCounty":"DO","regionShort":"WE","marketNumber":"43400156","infoItems":[{"title":"In Bedienung & Service","type":"service","color":"#00a7a9","contents":[]},{"title":"Sortimentshighlights","type":"highlights","color":"#f07d1b","contents":[]}],"openingHours":{"condensed":[{"days":"Mo-Sa","hours":"07:00 - 22:00"}]},"specialOpeningHours":{"wwIdent":1940156,"specialOpeningTimes":[]},"marketRatingUrl":"https://meinfeedback.rewe.de/app/?p1=1940156&p2=2023-07-08T17:05:44Z&app=android"}

  String id;
  String name;
  Address address;

  factory Market.fromJson(Map<String, dynamic> json) => _$MarketFromJson(json);

  Map<String, dynamic> toJson() => _$MarketToJson(this);
}

@JsonSerializable()
class Address {
  Address(this.street, this.postalCode, this.city);

  String street;
  String postalCode;
  String city;

  factory Address.fromJson(Map<String, dynamic> json) => _$AddressFromJson(json);

  Map<String, dynamic> toJson() => _$AddressToJson(this);
}

