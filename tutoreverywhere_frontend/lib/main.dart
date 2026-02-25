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
import 'package:provider/provider.dart';
import 'package:tutoreverywhere_frontend/providers/auth_provider.dart';
import './service/api.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authProvider = AuthProvider();
  await authProvider.checkAuth();
  runApp(ChangeNotifierProvider.value(
    value: authProvider,
    child: const MyApp()
  ));
}

final dio = Dio();
final client = RestClient(dio, baseUrl: "http://10.0.2.2:3000");
const Color mainColor = Color(0xFF1DA1F2);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "TutorEverywhere",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: mainColor,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: mainColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(88, 40),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(999)), 
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
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
      if (!mounted) return false;
      var token = testResponse.data.token;  
      var jwtData = JWT.decode(token);
      if (token != null) {
        await context.read<AuthProvider>().login(token, jwtData.payload['userId'], jwtData.payload['role']);
        print(context.read<AuthProvider>().userId);
      }
      print(token);
      print(jwtData.payload['userId']);
      print(jwtData.payload['iat']);
      print(jwtData.payload['exp']);
      switch (jwtData.payload['role']) {
        case "student": 
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const StudentHomePage()),
            (route) => false,
          );
          break;
        case "tutor":
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const TutorHomePage()),
            (route) => false,
          );
          break;
        case "admin":
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const AdminHomePage()),
            (route) => false,
          );
          break;
      }
      return true;
    } on DioException catch (e) {
      if (!mounted) return false;
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
