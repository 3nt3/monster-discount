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

  List<Market> markets;

  factory Markets.fromJson(Map<String, dynamic> json) =>
      _$MarketsFromJson(json);
  Map<String, dynamic> toJson() => _$MarketsToJson(this);
}

@JsonSerializable()
class Market {
  Market(this.id, this.name, this.addressLine1, this.addressLine2);

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

  factory Market.fromJson(Map<String, dynamic> json) => _$MarketFromJson(json);

  Map<String, dynamic> toJson() => _$MarketToJson(this);
}

