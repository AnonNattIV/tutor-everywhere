import 'dart:io';

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:tutoreverywhere_frontend/constants/app_constants.dart';
import 'package:tutoreverywhere_frontend/models/admins/requiredverifications.dart';
import 'package:tutoreverywhere_frontend/models/reviews/data.dart';
import 'package:tutoreverywhere_frontend/models/students/data.dart';
import 'package:tutoreverywhere_frontend/models/tutors/appointment.dart';
import 'package:tutoreverywhere_frontend/models/tutors/data.dart';
import 'package:tutoreverywhere_frontend/models/tutors/find_tutors.dart';
import 'package:tutoreverywhere_frontend/models/tutors/subjects.dart';
import '../models/jwt.dart';
import '../models/auth.dart';
import '../models/register/student.dart';
import '../models/register/tutor.dart';

part 'api.g.dart';

@RestApi(baseUrl: AppConstants.baseUrl)
abstract class RestClient {
  factory RestClient(Dio dio, {String? baseUrl}) = _RestClient;

  // Auth: sends username/password and receives JWT + user role/userId payload.
  @POST('/auth')
  Future<Jwt> login(@Body() Auth auth);

  // Same request as login(), but keeps full HTTP response for richer error handling.
  @POST('/auth')
  Future<HttpResponse<Jwt>> testLogin(@Body() Auth auth);

  // Registration request: send student form to backend.
  @POST('/register/student')
  Future<HttpResponse<void>> registerStudent(@Body() RegisterStudent student);

  // Registration request: send tutor form to backend.
  @POST('/register/tutor')
  Future<HttpResponse<void>> registerTutor(@Body() RegisterTutor tutor);

  // Tutors: list/search tutors using optional query filters.
  @GET('/tutors')
  Future<List<FindTutors>> getTutors({
    @Query('subject') String? subject,
    @Query('province') String? province,
    @Query('location') String? location,
    @Query('maxprice') String? maxPrice,
    @Query('name') String? name,
    @Query('sortby') String? sortBy,
  });

  // Tutors: read one tutor profile by user id.
  @GET('/tutors/profile/{userId}')
  Future<TutorData> getTutorDataById(@Path('userId') String userId);

  // Tutors: send new bio text (authorized).
  @POST('/tutors/bio')
  Future<void> setTutorBio(
    @Header('Authorization') String jwtToken,
    @Field('bio') String bio,
  );

  // Tutors: send preferred place text (authorized).
  @POST('/tutors/preferredPlace')
  Future<void> setTutorPreferredPlace(
    @Header('Authorization') String jwtToken,
    @Field('preferred_place') String preferredPlace,
  );

  // Tutors: update province/location used by profile and search (authorized).
  @PATCH('/tutors/location')
  Future<void> setTutorLocation(
    @Header('Authorization') String jwtToken,
    @Field('province') String province,
    @Field('location') String location,
  );

  // Tutors: send avatar image via multipart/form-data (authorized).
  @PATCH('/tutors/profile-picture')
  Future<void> uploadTutorProfilePicture(
    @Header('Authorization') String jwtToken,
    @Part(name: 'profilePicture') File profilePicture,
  );

  // Tutors: send PromptPay QR image for payment requests (authorized).
  @PATCH('/tutors/promptpay-picture')
  Future<void> uploadTutorPromptPayPicture(
    @Header('Authorization') String jwtToken,
    @Part(name: 'promptPayPicture') File promptPayPicture,
  );

  // Tutors: send verification image for admin review (authorized).
  @PATCH('/tutors/verification-picture')
  Future<void> uploadTutorVerificationPicture(
    @Header('Authorization') String jwtToken,
    @Part(name: 'verificationPicture') File verificationPicture,
  );

  // Tutors: Subjects

  // Reads all subjects/prices for a tutor.
  @GET('/tutors/subjects/{userId}')
  Future<List<TutorSubject>> getTutorSubjectsByTutorId(
    @Path('userId') String tutorId,
  );

  // Sends a new tutor subject row (authorized).
  @POST('/tutors/subjects/')
  Future<void> addTutorSubject(
    @Header('Authorization') String jwtToken,
    @Field('subject') String subject,
    @Field('price') int price,
  );

  // Sends updated price for an existing subject (authorized).
  @PATCH('/tutors/subjects/')
  Future<void> updateTutorSubjectPrice(
    @Header('Authorization') String jwtToken,
    @Field('subject') String subject,
    @Field('price') int price,
  );

  // Sends delete request for a subject (authorized).
  @DELETE('/tutors/subjects/')
  Future<void> deleteTutorSubject(
    @Header('Authorization') String jwtToken,
    @Field('subject') String subject,
  );

  // Tutors: Appointments (supports year/month/day filtering for calendar marks).
  @GET('/tutors/appointments/{userId}')
  Future<List<Appointment>> getAppointmentByTutorId(
    @Path('userId') String userId, {
    @Query('year') int? year,
    @Query('month') int? month,
    @Query('day') int? day,
  });

  // Students

  // Students: read one student profile by user id.
  @GET('/students/profile/{userId}')
  Future<StudentData> getStudentsDataById(@Path('userId') String userId);

  // Students: send new bio text (authorized).
  @POST('/students/bio')
  Future<void> setStudentBio(
    @Header('Authorization') String jwtToken,
    @Field('bio') String bio,
  );

  // Students: send avatar image via multipart/form-data (authorized).
  @PATCH('/students/profile-picture')
  Future<void> uploadStudentProfilePicture(
    @Header('Authorization') String jwtToken,
    @Part(name: 'profilePicture') File profilePicture,
  );

  // Students: Appointments (supports year/month/day filtering for calendar marks).
  @GET('/students/appointments/{userId}')
  Future<List<Appointment>> getAppointmentByStudentId(
    @Path('userId') String userId, {
    @Query('year') int? year,
    @Query('month') int? month,
    @Query('day') int? day,
  });

  // Reviews

  // Reads reviews shown in tutor profile.
  @GET('/reviews/{tutorId}')
  Future<List<Review>> getReviewsByRevieweeId(@Path('tutorId') String tutorId);

  // Sends a new review payload (authorized).
  @POST('/reviews')
  Future<void> addReview(
    @Header('Authorization') String jwtToken,
    @Body() Review review,
  );

  // Chat payment flow: sends "accept" command for a request-money message.
  @POST('/chat/accept')
  Future<void> acceptPromptPay(
    @Header('Authorization') String jwtToken,
    @Field('message_id') String messageId,
  );

  // Admin

  // Reads tutor verification queue for admin.
  @GET('/admin/required-verifications')
  Future<List<RequiredVerificationsResponse>> getRequiredVerifications(
    @Header('Authorization') String jwtToken,
  );

  // Sends admin decision: accept tutor verification.
  @POST('/admin/acceptverification')
  Future<void> acceptVerification(
    @Header('Authorization') String jwtToken,
    @Field('tutor_id') String tutorId,
  );

  // Sends admin decision: deny tutor verification.
  @POST('/admin/denyverification')
  Future<void> denyVerification(
    @Header('Authorization') String jwtToken,
    @Field('tutor_id') String tutorId,
  );
}
