import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:tutoreverywhere_frontend/models/reviews/data.dart';
import 'package:tutoreverywhere_frontend/models/students/data.dart';
import 'package:tutoreverywhere_frontend/models/tutors/data.dart';
import 'package:tutoreverywhere_frontend/models/tutors/subjects.dart';
import '../models/jwt.dart';
import '../models/auth.dart';
import '../models/register/student.dart';
import '../models/register/tutor.dart';

part 'api.g.dart';

@RestApi(baseUrl: "http://10.0.2.2:3000/")
abstract class RestClient {
  factory RestClient(Dio dio, {String? baseUrl}) = _RestClient;

  @POST("/auth")
  Future<Jwt> login(@Body() Auth auth);

  @POST("/auth")
  Future<HttpResponse<Jwt>> testLogin(@Body() Auth auth);

  @POST("/register/student")
  Future<HttpResponse<void>> registerStudent(@Body() RegisterStudent student);

  @POST("/register/tutor")
  Future<HttpResponse<void>> registerTutor(@Body() RegisterTutor tutor);

  // Tutors
  @GET("/tutors/profile/{userId}")
  Future<TutorData> getTutorDataById(@Path("userId") String userId);

  @POST("/tutors/bio")
  Future<void> setTutorBio(@Header("Authorization") String jwtToken, @Field("bio") String bio );

  @POST("/tutors/preferredPlace")
  Future<void> setTutorPreferredPlace(@Header("Authorization") String jwtToken, @Field("preferred_place") preferred_place);

  // Tutors: Subjects
  @GET("/tutors/subjects/{userId}")
  Future<List<TutorSubject>> getTutorSubjectsByTutorId(@Path("userId") String tutorId);

  @POST("/tutors/subjects/")
  Future<void> addTutorSubject(@Header("Authorization") String jwtToken, @Field("subject") String subject, @Field("price") int price);

  @PATCH("/tutors/subjects/")
  Future<void> updateTutorSubjectPrice(@Header("Authorization") String jwtToken, @Field("subject") String subject, @Field("price") int price);

  @DELETE("/tutors/subjects/")
  Future<void> deleteTutorSubject(@Header("Authorization") String jwtToken, @Field("subject") String subject);

  // Students
  @GET("/students/profile/{userId}")
  Future<StudentData> getStudentsDataById(@Path("userId") String userId);

  @POST("/students/bio")
  Future<void> setStudentBio(@Header("Authorization") String jwtToken, @Field("bio") String bio );

  // Reviews

  @GET("/reviews/{tutorId}")
  Future<List<Review>> getReviewsByRevieweeId(@Path("tutorId") String tutorId);

  @POST("/reviews")
  Future<void> addReview(@Header("Authorization") String jwtToken, @Body() Review review);
}
