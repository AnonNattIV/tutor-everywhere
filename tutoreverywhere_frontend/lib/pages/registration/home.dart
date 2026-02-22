import 'package:flutter/material.dart';
import 'package:tutoreverywhere_frontend/pages/registration/tutor.dart';
import 'student.dart';

class RegisterHomePage extends StatelessWidget {
  const RegisterHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Account Registration"), centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Select your role", style: TextStyle(fontSize: 24)),
            
            Card(
              child:
                  ListTile(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => StudentRegister())),
                    leading: Icon(Icons.person),
                    title: Text("Student"),
                    subtitle: Text("Find tutors and study"),
                  ),
              ),
              
            SizedBox(height: 16),
            Card(
              child:
                ListTile(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TutorRegister())),
                  leading: Icon(Icons.person),
                  title: Text("Tutor"),
                  subtitle: Text("Teach students to earn money"),
              )
            )
            ]
          )
        ),
    );
  }
}