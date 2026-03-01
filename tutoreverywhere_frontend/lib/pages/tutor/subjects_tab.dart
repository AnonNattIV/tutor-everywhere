// lib/pages/tutor/subjects_tab.dart
import 'package:flutter/material.dart';

class SubjectsTab extends StatefulWidget {
  const SubjectsTab({super.key, required this.tutorId, required this.tutorName});

  final String tutorId;
  final String tutorName;

  @override
  State<SubjectsTab> createState() => _SubjectsTabState();
}

class _SubjectsTabState extends State<SubjectsTab> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _subjects = [];
  String? _errorMessage;

  // TODO: Add API call to fetch subjects
  Future<void> _fetchSubjects() async {
    try {
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() {
        _subjects = [
          {'id': '1', 'name': 'Mathematics', 'level': 'High School', 'price': '\$25/hr'},
          {'id': '2', 'name': 'Physics', 'level': 'University', 'price': '\$35/hr'},
          {'id': '3', 'name': 'English', 'level': 'All Levels', 'price': '\$20/hr'},
        ];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load subjects';
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchSubjects, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_subjects.isEmpty) {
      return const Center(child: Text('No subjects listed'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _subjects.length,
      itemBuilder: (context, index) {
        final subject = _subjects[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              subject['name'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Level: ${subject['level']}', style: const TextStyle(color: Colors.black87)),
                Text('Price: ${subject['price']}', style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.w600)),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {
              // TODO: Navigate to subject details
            },
          ),
        );
      },
    );
  }
}