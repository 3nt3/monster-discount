// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'market.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Markets _$MarketsFromJson(Map<String, dynamic> json) => Markets(
      (json['items'] as List<dynamic>)
          .map((e) => Market.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$MarketsToJson(Markets instance) => <String, dynamic>{
      'items': instance.items,
    };

Market _$MarketFromJson(Map<String, dynamic> json) => Market(
      json['id'] as String,
      json['name'] as String,
      Address.fromJson(json['address'] as Map<String, dynamic>),
      MarketType.fromJson(json['type'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MarketToJson(Market instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'address': instance.address,
      'type': instance.type,
    };

Address _$AddressFromJson(Map<String, dynamic> json) => Address(
      json['street'] as String,
      json['postalCode'] as String,
      json['city'] as String,
    );

Map<String, dynamic> _$AddressToJson(Address instance) => <String, dynamic>{
      'street': instance.street,
      'postalCode': instance.postalCode,
      'city': instance.city,
    };

MarketType _$MarketTypeFromJson(Map<String, dynamic> json) => MarketType(
      json['name'] as String,
      json['id'] as String,
    );

Map<String, dynamic> _$MarketTypeToJson(MarketType instance) =>
    <String, dynamic>{
      'name': instance.name,
      'id': instance.id,
    };
