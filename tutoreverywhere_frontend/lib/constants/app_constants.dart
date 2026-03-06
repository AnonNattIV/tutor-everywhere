class AppConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/',
  );
  static const List<String> featuredSubjects = [
    'English',
    'Science',
    'Math',
    'Thai',
  ];
}