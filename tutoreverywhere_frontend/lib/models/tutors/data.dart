import 'package:json_annotation/json_annotation.dart';

part 'data.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class TutorData {
  final String userUuid;
  final String firstname;
  final String lastname;
  final DateTime dateofbirth;
  final String gender;
  final String profilePicture;
  final String? bio;
  final bool verified;
  final String? preferredPlace;
  final String? province;
  final String? location;
  final String? verificationPicture;

  TutorData({
    required this.userUuid,
    required this.firstname,
    required this.lastname,
    required this.dateofbirth,
    required this.gender,
    required this.profilePicture,
    this.bio,
    required this.verified,
    this.preferredPlace,
    this.province,
    this.location,
    this.verificationPicture
  });

  factory TutorData.fromJson(Map<String, dynamic> json) => _$TutorDataFromJson(json);
  Map<String, dynamic> toJson() => _$TutorDataToJson(this);
}