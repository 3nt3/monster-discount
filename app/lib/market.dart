import 'package:json_annotation/json_annotation.dart';

/// This allows the `User` class to access private members in
/// the generated file. The value for this is *.g.dart, where
/// the star denotes the source file name.
part 'market.g.dart';

/// An annotation for the code generator to know that this class needs the
/// JSON serialization logic to be generated.
@JsonSerializable()
class Markets {
  Markets(this.items);

  List<Market> items;

  factory Markets.fromJson(Map<String, dynamic> json) =>
      _$MarketsFromJson(json);
  Map<String, dynamic> toJson() => _$MarketsToJson(this);
}

@JsonSerializable()
class Market {
  Market(this.id, this.name, this.address, this.type);

  String id;
  String name;
  Address address;
  MarketType type;

  factory Market.fromJson(Map<String, dynamic> json) => _$MarketFromJson(json);

  Map<String, dynamic> toJson() => _$MarketToJson(this);
}

@JsonSerializable()
class Address {
  Address(this.street, this.postalCode, this.city);

  String street;
  String postalCode;
  String city;

  factory Address.fromJson(Map<String, dynamic> json) =>
      _$AddressFromJson(json);
  Map<String, dynamic> toJson() => _$AddressToJson(this);
}

@JsonSerializable()
class MarketType {
  MarketType(this.name, this.id);

  String name;
  String id;

  factory MarketType.fromJson(Map<String, dynamic> json) =>
      _$MarketTypeFromJson(json);
  Map<String, dynamic> toJson() => _$MarketTypeToJson(this);
}
