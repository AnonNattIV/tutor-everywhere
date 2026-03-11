import 'package:flutter/material.dart';
import 'package:tutoreverywhere_frontend/main.dart';
import 'package:tutoreverywhere_frontend/constants/app_constants.dart';
import 'package:tutoreverywhere_frontend/models/register/tutor.dart';
import '../../service/api.dart';
import 'package:dio/dio.dart';

class TutorRegister extends StatefulWidget {
  const TutorRegister({super.key});

  @override
  State<TutorRegister> createState() => _TutorRegisterState();
}

class _TutorRegisterState extends State<TutorRegister> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  DateTime? selectedDate;
  String? selectedGender;

  late final RestClient _restClient;

  // Opens the native date picker and stores the selected birth date.
  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      firstDate: DateTime(1926),
      lastDate: DateTime(2027),
    );

    if (pickedDate != null) setState(() => selectedDate = pickedDate);
  }

  // Validates form input and sends tutor registration to backend.
  Future<void> _register() async {
    try {
      if (!_formKey.currentState!.validate() ||
          selectedDate == null ||
          selectedGender == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
        return;
      }

      final tutor = RegisterTutor(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        firstname: _firstNameController.text.trim(),
        lastname: _lastNameController.text.trim(),
        dateofbirth: selectedDate!,
        gender: selectedGender!,
      );

      // API call: create tutor account.
      await _restClient.registerTutor(tutor);

      if (!mounted) return;

      // Successful
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Success!"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
        (route) => false,
      );
    } on DioException catch (e) {
      if (!mounted) return;
      String errorMsg = "Registration failed";
      if (e.response?.statusCode == 400) {
        errorMsg = e.response?.data['message'] ?? "Invalid data";
      } else if (e.response?.statusCode == 409) {
        errorMsg = "Username already exists";
      } else if (e.response?.statusCode == 500) {
        errorMsg = "Register Account Server error";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // Initialize REST client once for this screen.
    final dio = Dio(BaseOptions(contentType: Headers.jsonContentType));
    _restClient = RestClient(dio, baseUrl: AppConstants.baseUrl);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Tutor Registration"), centerTitle: true),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),

          children: [
            Text(
              "Create a new tutor account",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 16),

            TextField(
              obscureText: false,
              controller: _usernameController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Username',
              ),
            ),

            SizedBox(height: 16),

            TextField(
              obscureText: true,
              controller: _passwordController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Password',
              ),
            ),

            SizedBox(height: 16),

            Text("Account Information", style: TextStyle(fontSize: 20)),

            SizedBox(height: 16),

            TextField(
              obscureText: false,
              controller: _firstNameController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'First Name',
              ),
            ),

            SizedBox(height: 16),

            TextField(
              obscureText: false,
              controller: _lastNameController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Last Name',
              ),
            ),

            SizedBox(height: 16),

            Row(
              spacing: 16,
              children: [
                Text(
                  selectedDate != null
                      ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                      : "DD/MM/YY",
                  style: TextStyle(fontSize: 16),
                ),
                ElevatedButton(
                  onPressed: _selectDate,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                  ),
                  child: Text("Select date of birth"),
                ),
              ],
            ),

            SizedBox(height: 16),

            Row(
              spacing: 16,
              children: [
                Text("Gender", style: TextStyle(fontSize: 16)),
                DropdownMenu(
                  onSelected: (value) => setState(() => selectedGender = value),
                  dropdownMenuEntries: [
                    DropdownMenuEntry(value: "male", label: "Male"),
                    DropdownMenuEntry(value: "female", label: "Female"),
                  ],
                ),
              ],
            ),

            SizedBox(height: 16),

            Align(
              alignment: AlignmentGeometry.bottomCenter,
              child: ElevatedButton(
                onPressed: _register,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.only(
                    bottom: 12,
                    top: 12,
                    left: 32,
                    right: 32,
                  ),
                ),
                child: Text(
                  "Register",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
