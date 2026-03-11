// lib/models/review/review_model.dart
import 'package:json_annotation/json_annotation.dart';

part 'data.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Review {
  final String reviewer;
  final String reviewee;
  final int rating;
  final DateTime reviewDate;
  final String subject;
  final String? comment;

  @JsonKey(name: 'reviewer_firstname')
  final String reviewerFirstname;
  @JsonKey(name: 'reviewer_lastname')
  final String reviewerLastname;
  @JsonKey(name: 'reviewer_gender')
  final String reviewerGender;
  @JsonKey(name: 'reviewer_profile_picture')
  final String reviewerProfilePicture;
  @JsonKey(name: 'reviewer_verified')
  final bool reviewerVerified;

  @JsonKey(name: 'reviewee_firstname')
  final String revieweeFirstname;
  @JsonKey(name: 'reviewee_lastname')
  final String revieweeLastname;
  @JsonKey(name: 'reviewee_gender')
  final String revieweeGender;
  @JsonKey(name: 'reviewee_profile_picture')
  final String revieweeProfilePicture;
  @JsonKey(name: 'reviewee_verified')
  final bool revieweeVerified;

  Review({
    required this.reviewer,
    required this.reviewee,
    required this.rating,
    required this.reviewDate,
    required this.subject,
    this.comment,
    required this.reviewerFirstname,
    required this.reviewerLastname,
    required this.reviewerGender,
    required this.reviewerProfilePicture,
    required this.reviewerVerified,
    required this.revieweeFirstname,
    required this.revieweeLastname,
    required this.revieweeGender,
    required this.revieweeProfilePicture,
    required this.revieweeVerified,
  });

  factory Review.fromJson(Map<String, dynamic> json) => _$ReviewFromJson(json);
  Map<String, dynamic> toJson() => _$ReviewToJson(this);

  // Helper getters for display
  String get reviewerFullName => '$reviewerFirstname $reviewerLastname'.trim();
  String get revieweeFullName => '$revieweeFirstname $revieweeLastname'.trim();
}