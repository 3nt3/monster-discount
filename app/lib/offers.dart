import 'package:json_annotation/json_annotation.dart';

/// This allows the `User` class to access private members in
/// the generated file. The value for this is *.g.dart, where
/// the star denotes the source file name.
part 'offers.g.dart';

/// An annotation for the code generator to know that this class needs the
/// JSON serialization logic to be generated.
@JsonSerializable()
class Offers {
  Offers(this.categories);

  List<Category> categories = [];

  /// A necessary factory constructor for creating a new User instance
  /// from a map. Pass the map to the generated `_$UserFromJson()` constructor.
  /// The constructor is named after the source class, in this case, User.
  factory Offers.fromJson(Map<String, dynamic> json) => _$OffersFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$UserToJson`.
  Map<String, dynamic> toJson() => _$OffersToJson(this);
}

@JsonSerializable()
class Category {
  Category(this.id, this.offers);
  String id;
  List<Offer> offers;

  /// A necessary factory constructor for creating a new User instance
  /// from a map. Pass the map to the generated `_$UserFromJson()` constructor.
  /// The constructor is named after the source class, in this case, User.
  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$UserToJson`.
  Map<String, dynamic> toJson() => _$CategoryToJson(this);
}

@JsonSerializable()
class Offer {
  Offer(this.title, this.subtitle, this.images, this.priceData);

  String title;
  String subtitle;
  List<String> images;
  PriceData priceData;

  factory Offer.fromJson(Map<String, dynamic> json) => _$OfferFromJson(json);

  Map<String, dynamic> toJson() => _$OfferToJson(this);
}

@JsonSerializable()
class PriceData {
  PriceData(this.price, this.regularPrice);

  String? price;
  String? regularPrice;

  factory PriceData.fromJson(Map<String, dynamic> json) =>
      _$PriceDataFromJson(json);

  Map<String, dynamic> toJson() => _$PriceDataToJson(this);
}
