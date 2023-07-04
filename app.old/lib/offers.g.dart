// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offers.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Offers _$OffersFromJson(Map<String, dynamic> json) => Offers(
      (json['categories'] as List<dynamic>)
          .map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$OffersToJson(Offers instance) => <String, dynamic>{
      'categories': instance.categories,
    };

Category _$CategoryFromJson(Map<String, dynamic> json) => Category(
      json['title'] as String,
      (json['offers'] as List<dynamic>)
          .map((e) => Offer.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CategoryToJson(Category instance) => <String, dynamic>{
      'title': instance.title,
      'offers': instance.offers,
    };

Offer _$OfferFromJson(Map<String, dynamic> json) => Offer(
      json['title'] as String,
      json['subtitle'] as String,
      (json['images'] as List<dynamic>).map((e) => e as String).toList(),
      PriceData.fromJson(json['priceData'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$OfferToJson(Offer instance) => <String, dynamic>{
      'title': instance.title,
      'subtitle': instance.subtitle,
      'images': instance.images,
      'priceData': instance.priceData,
    };

PriceData _$PriceDataFromJson(Map<String, dynamic> json) => PriceData(
      json['price'] as String?,
      json['regularPrice'] as String?,
    );

Map<String, dynamic> _$PriceDataToJson(PriceData instance) => <String, dynamic>{
      'price': instance.price,
      'regularPrice': instance.regularPrice,
    };
