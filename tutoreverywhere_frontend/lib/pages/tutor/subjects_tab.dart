// lib/pages/tutor/subjects_tab.dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:tutoreverywhere_frontend/constants/app_constants.dart';
import 'package:tutoreverywhere_frontend/models/tutors/subjects.dart';
import 'package:tutoreverywhere_frontend/service/api.dart';
import 'package:tutoreverywhere_frontend/providers/auth_provider.dart';

class SubjectsTab extends StatefulWidget {
  const SubjectsTab({
    super.key,
    required this.tutorId,
    required this.tutorName,
  });

  final String tutorId;
  final String tutorName;

  @override
  State<SubjectsTab> createState() => _SubjectsTabState();
}

class _SubjectsTabState extends State<SubjectsTab> {
  bool _isLoading = true;
  bool _isAddingSubject = false;
  bool _isDeletingSubject = false;
  bool _isUpdatingPrice = false; // New state for price update operation
  List<TutorSubject> _subjects = [];
  String? _errorMessage;
  String _searchQuery = '';

  late final Dio _dio;
  late final RestClient _client;
  static String get _baseUrl => AppConstants.normalizedBaseUrl;

  @override
  void initState() {
    super.initState();
    _setupDio();
    _fetchSubjects();
  }

  void _setupDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        contentType: "application/json",
        validateStatus: (status) => status != null,
      ),
    );
    _dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true, error: true),
    );
    _client = RestClient(_dio, baseUrl: _baseUrl);
  }

  Future<void> _fetchSubjects() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _searchQuery = '';
    });

    try {
      final subjects = await _client.getTutorSubjectsByTutorId(widget.tutorId);

      if (!mounted) return;
      setState(() {
        _subjects = subjects;
        _isLoading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            e.response?.data['message'] ??
            e.message ??
            'Failed to load subjects';
        _isLoading = false;
      });
      debugPrint('Dio Error fetching subjects: ${e.type} - ${e.message}');
    } catch (e, stackTrace) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unexpected error: $e';
        _isLoading = false;
      });
      debugPrint('Error fetching subjects: $e\nStack: $stackTrace');
    }
  }

  // Add subject via API
  Future<void> _addSubject(String subject, String priceStr) async {
    final price = (double.tryParse(priceStr) ?? 0).round();

    setState(() => _isAddingSubject = true);

    try {
      final token = context.read<AuthProvider>().token;
      if (token == null) throw Exception('Authentication required');

      await _client.addTutorSubject(token, subject, price);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subject added successfully!')),
      );
      await _fetchSubjects();
    } on DioException catch (e) {
      if (!mounted) return;
      final message =
          e.response?.data['message'] ?? e.message ?? 'Failed to add subject';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      debugPrint('Dio Error adding subject: ${e.type} - ${e.message}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      debugPrint('Error adding subject: $e');
    } finally {
      if (mounted) setState(() => _isAddingSubject = false);
    }
  }

  // Update subject price via API
  Future<void> _updateSubjectPrice(String subject, String priceStr) async {
    final price = (double.tryParse(priceStr) ?? 0).round();

    setState(() => _isUpdatingPrice = true);

    try {
      final token = context.read<AuthProvider>().token;
      if (token == null) throw Exception('Authentication required');

      await _client.updateTutorSubjectPrice(token, subject, price);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Price updated successfully!')),
      );
      await _fetchSubjects();
    } on DioException catch (e) {
      if (!mounted) return;
      final message =
          e.response?.data['message'] ?? e.message ?? 'Failed to update price';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      debugPrint('Dio Error updating price: ${e.type} - ${e.message}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      debugPrint('Error updating price: $e');
    } finally {
      if (mounted) setState(() => _isUpdatingPrice = false);
    }
  }

  // Show dialog to add new subject with dropdown
  void _showAddSubjectDialog() {
    final formKey = GlobalKey<FormState>();
    String? selectedSubject;
    String priceInput = '';

    final List<String> subjectOptions = AppConstants.featuredSubjects;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add New Subject'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedSubject,
                      decoration: const InputDecoration(
                        labelText: 'Subject',
                        border: OutlineInputBorder(),
                        hintText: 'Select a subject',
                      ),
                      items: subjectOptions.map((String subject) {
                        return DropdownMenuItem<String>(
                          value: subject,
                          child: Text(subject),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setDialogState(() => selectedSubject = newValue);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a subject';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Price per Hour (฿)',
                        hintText: 'e.g., 300',
                        border: OutlineInputBorder(),
                        prefixText: '฿ ',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a price';
                        }
                        final price = double.tryParse(value);
                        if (price == null || price <= 0) {
                          return 'Enter a valid price > 0';
                        }
                        return null;
                      },
                      onSaved: (value) => priceInput = value!.trim(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: _isAddingSubject || selectedSubject == null
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            formKey.currentState!.save();
                            await _addSubject(selectedSubject!, priceInput);
                            if (mounted) Navigator.pop(context);
                          }
                        },
                  child: _isAddingSubject
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Show dialog to edit subject price
  void _showEditPriceDialog(String subjectName, int currentPrice) {
    final formKey = GlobalKey<FormState>();
    String priceInput = currentPrice.toString();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Price'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Subject: $subjectName',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: priceInput,
                  decoration: const InputDecoration(
                    labelText: 'New Price per Hour (฿)',
                    hintText: 'e.g., 350',
                    border: OutlineInputBorder(),
                    prefixText: '฿ ',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a price';
                    }
                    final price = double.tryParse(value);
                    if (price == null || price <= 0) {
                      return 'Enter a valid price > 0';
                    }
                    return null;
                  },
                  onSaved: (value) => priceInput = value!.trim(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: _isUpdatingPrice
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        formKey.currentState!.save();
                        await _updateSubjectPrice(subjectName, priceInput);
                        if (mounted) Navigator.pop(context);
                      }
                    },
              child: _isUpdatingPrice
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Confirm and delete subject
  void _confirmDeleteSubject(String subjectName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subject'),
        content: Text(
          'Are you sure you want to remove "$subjectName" from your teaching subjects?',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _isDeletingSubject
                ? null
                : () async {
                    Navigator.pop(context);
                    await _deleteSubject(subjectName);
                  },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: _isDeletingSubject
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Delete subject via API
  Future<void> _deleteSubject(String subject) async {
    setState(() => _isDeletingSubject = true);

    try {
      final token = context.read<AuthProvider>().token;
      if (token == null) throw Exception('Authentication required');

      await _client.deleteTutorSubject(token, subject);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subject deleted successfully!')),
      );
      await _fetchSubjects();
    } on DioException catch (e) {
      if (!mounted) return;
      final message =
          e.response?.data['message'] ??
          e.message ??
          'Failed to delete subject';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      debugPrint('Dio Error deleting subject: ${e.type} - ${e.message}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      debugPrint('Error deleting subject: $e');
    } finally {
      if (mounted) setState(() => _isDeletingSubject = false);
    }
  }

  List<TutorSubject> get _filteredSubjects {
    if (_searchQuery.isEmpty) return _subjects;
    final query = _searchQuery.toLowerCase();
    return _subjects
        .where((s) => s.subject.toLowerCase().contains(query))
        .toList();
  }

  IconData _getSubjectIcon(String subjectName) {
    final name = subjectName.toLowerCase();
    if (name.contains('math') ||
        name.contains('algebra') ||
        name.contains('calculus'))
      return Icons.calculate;
    if (name.contains('english') ||
        name.contains('language') ||
        name.contains('literature'))
      return Icons.menu_book;
    if (name.contains('science') ||
        name.contains('biology') ||
        name.contains('chemistry') ||
        name.contains('physics'))
      return Icons.science;
    if (name.contains('history') ||
        name.contains('social') ||
        name.contains('geography'))
      return Icons.history_edu;
    if (name.contains('music') ||
        name.contains('art') ||
        name.contains('drawing'))
      return Icons.music_note;
    if (name.contains('programming') ||
        name.contains('code') ||
        name.contains('computer') ||
        name.contains('web'))
      return Icons.code;
    if (name.contains('business') ||
        name.contains('economy') ||
        name.contains('finance'))
      return Icons.account_balance;
    return Icons.school_outlined;
  }

  String _formatPrice(num price) {
    return price.toStringAsFixed(price.truncateToDouble() == price ? 0 : 2);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isOwner = context.read<AuthProvider>().userId == widget.tutorId;

    // Loading state with skeleton
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (context, index) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            height: 72,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 16,
                        color: colorScheme.surfaceContainerHighest,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 60,
                        height: 14,
                        color: colorScheme.surfaceContainerHighest,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Error state
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: colorScheme.error, size: 56),
              const SizedBox(height: 16),
              Text(
                'Unable to load subjects',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _fetchSubjects,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    // Empty state
    if (_subjects.isEmpty) {
      return Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_add_outlined,
                    size: 72,
                    color: colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No subjects yet',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.tutorName} hasn\'t added any teaching subjects yet.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          if (isOwner)
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton(
                onPressed: _showAddSubjectDialog,
                child: const Icon(Icons.add),
                tooltip: 'Add Subject',
              ),
            ),
        ],
      );
    }

    // Success: List of subjects with search
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _fetchSubjects,
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search subjects...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.outline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.outline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 16,
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerLow,
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),

              // Results count
              if (_searchQuery.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '${_filteredSubjects.length} result${_filteredSubjects.length == 1 ? '' : 's'}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              if (_searchQuery.isNotEmpty) const SizedBox(height: 8),

              // Subjects list
              Expanded(
                child: _filteredSubjects.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 48,
                                color: colorScheme.onSurface.withOpacity(0.4),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No matches found',
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Try a different search term',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: _filteredSubjects.length,
                        itemBuilder: (context, index) {
                          final subject = _filteredSubjects[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  // Subject icon
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      _getSubjectIcon(subject.subject),
                                      color: colorScheme.onPrimaryContainer,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Subject name + price
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          subject.subject,
                                          style: textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          semanticsLabel:
                                              'Subject: ${subject.subject}',
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '฿${_formatPrice(subject.price)}/hour', // Changed $ to ฿
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: colorScheme.primary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          semanticsLabel:
                                              'Price: ${subject.price} baht per hour',
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Edit and Delete buttons
                                  if (isOwner)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Edit price button (pencil icon)
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                            size: 20,
                                          ),
                                          onPressed: () => _showEditPriceDialog(
                                            subject.subject,
                                            subject.price,
                                          ),
                                          tooltip: 'Edit price',
                                          color: colorScheme.primary,
                                          constraints: const BoxConstraints(
                                            minWidth: 36,
                                            minHeight: 36,
                                          ),
                                          padding: EdgeInsets.zero,
                                        ),
                                        // Delete button (trash icon)
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            size: 20,
                                          ),
                                          onPressed: () =>
                                              _confirmDeleteSubject(
                                                subject.subject,
                                              ),
                                          tooltip: 'Delete subject',
                                          color: colorScheme.error,
                                          constraints: const BoxConstraints(
                                            minWidth: 36,
                                            minHeight: 36,
                                          ),
                                          padding: EdgeInsets.zero,
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        // Floating Action Button for adding subjects
        if (isOwner)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: _showAddSubjectDialog,
              child: const Icon(Icons.add),
              tooltip: 'Add Subject',
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _dio.close(force: true);
    super.dispose();
  }
}
