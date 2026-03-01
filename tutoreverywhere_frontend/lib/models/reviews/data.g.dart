// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Review _$ReviewFromJson(Map<String, dynamic> json) => Review(
  reviewer: json['reviewer'] as String,
  reviewee: json['reviewee'] as String,
  rating: (json['rating'] as num).toInt(),
  reviewDate: DateTime.parse(json['review_date'] as String),
  subject: json['subject'] as String,
  comment: json['comment'] as String?,
  reviewerFirstname: json['reviewer_firstname'] as String,
  reviewerLastname: json['reviewer_lastname'] as String,
  reviewerGender: json['reviewer_gender'] as String,
  reviewerProfilePicture: json['reviewer_profile_picture'] as String,
  reviewerVerified: json['reviewer_verified'] as bool,
  revieweeFirstname: json['reviewee_firstname'] as String,
  revieweeLastname: json['reviewee_lastname'] as String,
  revieweeGender: json['reviewee_gender'] as String,
  revieweeProfilePicture: json['reviewee_profile_picture'] as String,
  revieweeVerified: json['reviewee_verified'] as bool,
);

Map<String, dynamic> _$ReviewToJson(Review instance) => <String, dynamic>{
  'reviewer': instance.reviewer,
  'reviewee': instance.reviewee,
  'rating': instance.rating,
  'review_date': instance.reviewDate.toIso8601String(),
  'subject': instance.subject,
  'comment': instance.comment,
  'reviewer_firstname': instance.reviewerFirstname,
  'reviewer_lastname': instance.reviewerLastname,
  'reviewer_gender': instance.reviewerGender,
  'reviewer_profile_picture': instance.reviewerProfilePicture,
  'reviewer_verified': instance.reviewerVerified,
  'reviewee_firstname': instance.revieweeFirstname,
  'reviewee_lastname': instance.revieweeLastname,
  'reviewee_gender': instance.revieweeGender,
  'reviewee_profile_picture': instance.revieweeProfilePicture,
  'reviewee_verified': instance.revieweeVerified,
};
