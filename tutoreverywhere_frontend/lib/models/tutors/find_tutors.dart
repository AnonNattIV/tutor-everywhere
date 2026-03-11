import 'package:json_annotation/json_annotation.dart';

// This part directive is required for json_serializable to generate code
part 'find_tutors.g.dart';

@JsonSerializable()
class FindTutors {
  @JsonKey(name: 'user_uuid')
  final String userUuid;

  final String firstname;
  final String lastname;

  @JsonKey(name: 'dateofbirth')
  final DateTime dateofbirth;

  final String gender;

  @JsonKey(name: 'profile_picture')
  final String profilePicture;

  final bool verified;
  
  // Nullable fields as per the example JSON (null values)
  final String? province;
  final String? location;

  @JsonKey(name: 'avg_rating')
  final String avgRating;

  @JsonKey(name: 'review_count')
  final String reviewCount;

  @JsonKey(name: 'subject_by_price')
  final Map<String, int> subjectByPrice;

  FindTutors({
    required this.userUuid,
    required this.firstname,
    required this.lastname,
    required this.dateofbirth,
    required this.gender,
    required this.profilePicture,
    required this.verified,
    this.province,
    this.location,
    required this.avgRating,
    required this.reviewCount,
    required this.subjectByPrice,
  });

  factory FindTutors.fromJson(Map<String, dynamic> json) =>
      _$FindTutorsFromJson(json);

  Map<String, dynamic> toJson() => _$FindTutorsToJson(this);
}