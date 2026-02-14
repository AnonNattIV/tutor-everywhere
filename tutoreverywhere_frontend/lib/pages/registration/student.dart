import 'package:flutter/material.dart';

class StudentRegister extends StatefulWidget {
  StudentRegister({super.key});

  @override
  State<StudentRegister> createState() => _StudentRegisterState();
}

class _StudentRegisterState extends State<StudentRegister> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  DateTime? selectedDate;

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      firstDate: DateTime(1926),
      lastDate: DateTime(2027),
    );

    setState(() {
      selectedDate = pickedDate;
    });
  }

  @override
  void dispose(){
    _usernameController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Student Registration"), centerTitle: true,
      ),
      body:
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: [

              Text("Create a new student account", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

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

              Text("Account Information", style: TextStyle(fontSize: 20)),

              TextField(
                obscureText: false,
                controller: _firstNameController,
                decoration: InputDecoration(border: OutlineInputBorder(), labelText: 'First Name'),
              ),


              TextField(
                obscureText: false,
                controller: _lastNameController,
                decoration: InputDecoration(border: OutlineInputBorder(), labelText: 'Last Name'),
              ),

              Row(
                spacing: 16,
                children: [
                  Text(selectedDate != null ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}' : "DD/MM/YY", style: TextStyle(fontSize: 16),),
                  ElevatedButton(onPressed: _selectDate, style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 32)), child: Text("Select date of birth"))
                ],
              ),

              Row(
                spacing: 16,
                children: [
                  Text("Gender", style: TextStyle(fontSize: 16)),
                  DropdownMenu(dropdownMenuEntries: [
                    DropdownMenuEntry(value: "male", label: "Male"),
                    DropdownMenuEntry(value: "female", label: "Female")
                  ]),
                ],
              ),

              Align(
                alignment: AlignmentGeometry.bottomCenter,
                child: ElevatedButton(onPressed: () => print("XD"), style: ElevatedButton.styleFrom(padding: EdgeInsets.only(bottom: 12, top: 12, left: 32, right: 32)), child: Text("Register", style: TextStyle(fontSize: 24,  fontWeight: FontWeight.bold)))
              )
            ],
          ),
        )
    );
  }
}