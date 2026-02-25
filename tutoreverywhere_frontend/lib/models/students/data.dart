import 'package:json_annotation/json_annotation.dart';

part 'data.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class StudentData {
  final String userUuid;
  final String firstname;
  final String lastname;
  final DateTime dateofbirth;
  final String gender;
  final String profilePicture;
  final String? bio;
  final bool verified;

  StudentData({
    required this.userUuid,
    required this.firstname,
    required this.lastname,
    required this.dateofbirth,
    required this.gender,
    required this.profilePicture,
    this.bio,
    required this.verified
  });

  factory StudentData.fromJson(Map<String, dynamic> json) => _$StudentDataFromJson(json);
  Map<String, dynamic> toJson() => _$StudentDataToJson(this);
}