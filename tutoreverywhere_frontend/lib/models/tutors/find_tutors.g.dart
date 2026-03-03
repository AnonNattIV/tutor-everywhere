// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'find_tutors.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FindTutors _$FindTutorsFromJson(Map<String, dynamic> json) => FindTutors(
  userUuid: json['user_uuid'] as String,
  firstname: json['firstname'] as String,
  lastname: json['lastname'] as String,
  dateofbirth: DateTime.parse(json['dateofbirth'] as String),
  gender: json['gender'] as String,
  profilePicture: json['profile_picture'] as String,
  verified: json['verified'] as bool,
  province: json['province'] as String?,
  location: json['location'] as String?,
  avgRating: json['avg_rating'] as String,
  reviewCount: json['review_count'] as String,
  subjectByPrice: Map<String, int>.from(json['subject_by_price'] as Map),
);

Map<String, dynamic> _$FindTutorsToJson(FindTutors instance) =>
    <String, dynamic>{
      'user_uuid': instance.userUuid,
      'firstname': instance.firstname,
      'lastname': instance.lastname,
      'dateofbirth': instance.dateofbirth.toIso8601String(),
      'gender': instance.gender,
      'profile_picture': instance.profilePicture,
      'verified': instance.verified,
      'province': instance.province,
      'location': instance.location,
      'avg_rating': instance.avgRating,
      'review_count': instance.reviewCount,
      'subject_by_price': instance.subjectByPrice,
    };
