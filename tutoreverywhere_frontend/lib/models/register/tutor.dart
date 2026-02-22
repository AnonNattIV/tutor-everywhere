import 'package:json_annotation/json_annotation.dart';
import 'package:intl/intl.dart';
part 'tutor.g.dart';

String _dateToString(DateTime? date) => date == null ? '' : DateFormat('yyyy-MM-dd').format(date);
DateTime? _stringToDate(String? date) => date == null || date.isEmpty ? null : DateFormat('yyyy-MM-dd').parse(date);

@JsonSerializable()
class RegisterTutor {
  final String username;
  final String password;
  final String firstname;
  final String lastname;
  final String gender;

  @JsonKey(toJson: _dateToString, fromJson: _stringToDate)
  final DateTime? dateofbirth;

  RegisterTutor({required this.username, required this.password, required this.firstname, required this.lastname, required this.dateofbirth, required this.gender});

  factory RegisterTutor.fromJson(Map<String, dynamic> json) => _$RegisterTutorFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterTutorToJson(this);
}