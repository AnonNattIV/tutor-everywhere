import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:tutoreverywhere_frontend/models/tutors/data.dart';
import '../models/jwt.dart';
import '../models/auth.dart';
import '../models/register/student.dart';
import '../models/register/tutor.dart';

part 'api.g.dart';

@RestApi(baseUrl: "http://10.0.2.2:3000/")
abstract class RestClient {
  factory RestClient(Dio dio, {String baseUrl}) = _RestClient;

  @POST("/auth")
  Future<Jwt> login(@Body() Auth auth);

  @POST("/auth")
  Future<HttpResponse<Jwt>> testLogin(@Body() Auth auth);

  @POST("/register/student")
  Future<HttpResponse<void>> registerStudent(@Body() RegisterStudent student);

  @POST("/register/tutor")
  Future<HttpResponse<void>> registerTutor(@Body() RegisterTutor tutor);

  @GET("/tutors/{userId}")
  Future<HttpResponse<TutorData>> getTutorDataById(@Path("userId") String userId);
}
