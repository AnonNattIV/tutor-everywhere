import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:tutoreverywhere_frontend/models/auth.dart';
import 'package:tutoreverywhere_frontend/pages/admin/home.dart';
import 'package:tutoreverywhere_frontend/pages/student/home.dart';
import 'package:tutoreverywhere_frontend/pages/tutor/home.dart';
import 'package:tutoreverywhere_frontend/pages/registration/home.dart';
import './service/api.dart';

void main() {
  runApp(const MyApp());
}

final dio = Dio();
final client = RestClient(dio, baseUrl: "http://10.0.2.2:3000");

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "TutorEverywhere",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlue[400],
            foregroundColor: Colors.white,
            minimumSize: Size(88, 36),
            padding: EdgeInsets.symmetric(horizontal: 16),
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(2)))
          ),
        )
      ),
      home: HomePage()
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return LoginPage();
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<bool> login(String username, String password) async {
    try {
      HttpResponse testResponse = await client.testLogin(Auth(username: username, password: password));
      var token = testResponse.data.token;
      var jwtData = JWT.decode(token);
      switch (jwtData.payload['role']) {
        case "student":
          Navigator.push(context, MaterialPageRoute<void>(builder: (context) => StudentHomePage()));
          break;
        case "tutor":
          Navigator.push(context, MaterialPageRoute<void>(builder: (context) => TutorHomePage()));
          break;
        case "admin":
          Navigator.push(context, MaterialPageRoute<void>(builder: (context) => AdminHomePage()));
          break;
      }
      return true;
    } on DioException catch (e) {
      showDialog(context: context, builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text("Error"),
          children: [
            Container(padding: EdgeInsets.symmetric(horizontal: 24), child: Text("${e.response?.statusCode}")),
            Container(padding: EdgeInsets.symmetric(horizontal: 24), child: Text("${e.response?.data['error']}")),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context),
              child: Text("OK")
            )
          ]
        );
      });
      return false;
    }
  }

  @override
  void dispose(){
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        margin: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 25,
        
          children: [
            Text("TutorEverywhere", style: Theme.of(context).textTheme.headlineLarge),
        
            TextField(
              obscureText: false,
              controller: _usernameController,
              decoration: InputDecoration(border: OutlineInputBorder(), labelText: 'Username'),
            ),
        
            TextField(
              obscureText: true,
              controller: _passwordController,
              decoration: InputDecoration(border: OutlineInputBorder(), labelText: 'Password'),
            ),
    
            RichText(text: 
              TextSpan(
                children: [
                  TextSpan(text: "No account? Register ", style: Theme.of(context).textTheme.bodyLarge),
                  TextSpan(text: "here", recognizer: TapGestureRecognizer()..onTap = () => Navigator.push(context, MaterialPageRoute<void>(builder: (context) => RegisterHomePage())),style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.blueAccent)),
                ]
              )
            ),
    
            ElevatedButton(onPressed: () async {
              await login(_usernameController.text, _passwordController.text);
            }, style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 32)), child: Text("Login", style: TextStyle(fontWeight: FontWeight.bold)))
          ],
        ),
      )
    );
  }
}