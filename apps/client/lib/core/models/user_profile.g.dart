// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => _UserProfile(
  id: json['id'] as String,
  plan: $enumDecode(_$SubscriptionPlanEnumMap, json['plan']),
);

Map<String, dynamic> _$UserProfileToJson(_UserProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'plan': _$SubscriptionPlanEnumMap[instance.plan]!,
    };

const _$SubscriptionPlanEnumMap = {
  SubscriptionPlan.free: 'FREE',
  SubscriptionPlan.premium: 'PREMIUM',
};
