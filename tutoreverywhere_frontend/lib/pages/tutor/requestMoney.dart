import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tutoreverywhere_frontend/constants/app_constants.dart';
import 'package:tutoreverywhere_frontend/providers/auth_provider.dart';

class RequestMoneyDraft {
  const RequestMoneyDraft({
    required this.subject,
    required this.placeName,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.price,
    required this.pinnedLocation,
  });

  final String subject;
  final String placeName;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final int price;
  final LatLng pinnedLocation;
}

class RequestMoneyPage extends StatefulWidget {
  const RequestMoneyPage({
    super.key,
    this.initialPeerUserId,
    this.initialPeerDisplayName,
    this.initialDraft,
  });

  final String? initialPeerUserId;
  final String? initialPeerDisplayName;
  final RequestMoneyDraft? initialDraft;

  @override
  State<RequestMoneyPage> createState() => _RequestMoneyPageState();
}

class _RequestMoneyPageState extends State<RequestMoneyPage> {
  static const List<String> _availableSubjects = AppConstants.featuredSubjects;
  static const LatLng _defaultLocation = LatLng(13.7563, 100.5018);
  static const String _baseUrl = AppConstants.baseUrl;

  late final Dio _dio;

  String? selectedSubject;
  String? _activePeerUserId;
  String _activePeerDisplayName = '';

  final TextEditingController _placeNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  LatLng? _pinnedLocation;
  bool _isSubmitting = false;

  bool get _isEditMode => widget.initialDraft != null;

  @override
  void initState() {
    super.initState();
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        validateStatus: (status) => status != null,
      ),
    );

    _activePeerUserId = widget.initialPeerUserId;
    _activePeerDisplayName = widget.initialPeerDisplayName?.trim() ?? '';

    final draft = widget.initialDraft;
    if (draft != null) {
      selectedSubject = draft.subject;
      _placeNameController.text = draft.placeName;
      _descriptionController.text = draft.description;
      _priceController.text = draft.price.toString();
      _startDate = draft.startDate;
      _endDate = draft.endDate;
      _pinnedLocation = draft.pinnedLocation;
    }
  }

  @override
  void dispose() {
    _dio.close(force: true);
    _placeNameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDateTime({
    required DateTime? currentDate,
    required TimeOfDay? currentTime,
  }) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: currentDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null) return null;

    if (!mounted) return null;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: currentTime ?? TimeOfDay.now(),
    );
    if (pickedTime == null) return null;

    return DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
  }

  Future<void> _pickStartDateTime() async {
    final result = await _pickDateTime(
      currentDate: _startDate,
      currentTime: _startDate != null
          ? TimeOfDay.fromDateTime(_startDate!)
          : null,
    );
    if (result != null) {
      setState(() {
        _startDate = result;
        if (_endDate != null && !_endDate!.isAfter(result)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _pickEndDateTime() async {
    final result = await _pickDateTime(
      currentDate: _endDate,
      currentTime: _endDate != null ? TimeOfDay.fromDateTime(_endDate!) : null,
    );
    if (result != null) {
      setState(() => _endDate = result);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select';
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '--:--';
    return DateFormat('HH:mm').format(date);
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<Position?> _getCurrentPosition({bool showErrors = true}) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (showErrors) _showSnack('Please enable location services');
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (showErrors) _showSnack('Location permission denied');
      return null;
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  Future<void> _openMapPicker() async {
    final currentPosition = await _getCurrentPosition(showErrors: false);
    final initialCenter =
        _pinnedLocation ??
        (currentPosition == null
            ? _defaultLocation
            : LatLng(currentPosition.latitude, currentPosition.longitude));
    if (currentPosition == null && _pinnedLocation == null) {
      _showSnack('Could not read GPS. Use map pin manually.');
    }

    if (!mounted) return;
    final result = await showModalBottomSheet<_PinnedLocationResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) =>
          _RequestMoneyLocationPickerSheet(initialCenter: initialCenter),
    );

    if (result != null) {
      setState(
        () => _pinnedLocation = LatLng(result.latitude, result.longitude),
      );
    }
  }

  double _calculateHours(DateTime start, DateTime end) {
    final diffMinutes = end.difference(start).inMinutes;
    final hours = diffMinutes / 60.0;
    return double.parse(hours.toStringAsFixed(2));
  }

  String _buildLocationLabel() {
    final placeName = _placeNameController.text.trim();
    if (placeName.isNotEmpty) return placeName;
    final location = _pinnedLocation!;
    return 'Lat ${location.latitude.toStringAsFixed(5)}, Lng ${location.longitude.toStringAsFixed(5)}';
  }

  Future<void> _submitRequestMoney() async {
    final peerUserId = _activePeerUserId;
    if (peerUserId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Missing chat target user')));
      return;
    }

    final subject = selectedSubject?.trim() ?? '';
    final startDate = _startDate;
    final endDate = _endDate;
    final location = _pinnedLocation;
    final amount = int.tryParse(_priceController.text.trim()) ?? 0;

    if (subject.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a subject')));
      return;
    }

    if (startDate == null || endDate == null || !endDate.isAfter(startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select valid start and end time')),
      );
      return;
    }

    if (location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pin a location on map')),
      );
      return;
    }

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Price must be greater than 0')),
      );
      return;
    }

    final hours = _calculateHours(startDate, endDate);
    if (hours <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid duration')));
      return;
    }

    final token = context.read<AuthProvider>().token;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Not authenticated')));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final response = await _dio.post<dynamic>(
        'chat/messages/$peerUserId/request-money',
        data: <String, dynamic>{
          'subject': subject,
          'amount': amount,
          'hours': hours,
          'startAt': startDate.toIso8601String(),
          'endAt': endDate.toIso8601String(),
          'dateLabel': DateFormat('d MMMM yyyy').format(startDate),
          'locationLabel': _buildLocationLabel(),
          'placeName': _placeNameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'latitude': location.latitude,
          'longitude': location.longitude,
        },
        options: Options(headers: <String, dynamic>{'Authorization': token}),
      );

      if (!mounted) return;
      if (response.statusCode != 201) {
        final msg = response.data is Map && response.data['message'] != null
            ? response.data['message'].toString()
            : 'Failed to send request money';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
        return;
      }

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? 'Updated request money successfully'
                : 'Sent request money successfully',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending request money: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Request money to $_activePeerDisplayName'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          spacing: 16,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: selectedSubject,
              decoration: const InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
              ),
              items: _availableSubjects.map((subject) {
                return DropdownMenuItem(value: subject, child: Text(subject));
              }).toList(),
              onChanged: (value) => setState(() => selectedSubject = value),
            ),
            TextField(
              controller: _placeNameController,
              decoration: const InputDecoration(
                labelText: 'Place Name (optional)',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                alignLabelWithHint: true,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _pickStartDateTime,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Start Date',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            suffixIcon: Icon(Icons.calendar_today, size: 18),
                          ),
                          child: Text(
                            _formatDate(_startDate),
                            style: TextStyle(
                              color: _startDate == null
                                  ? Theme.of(context).hintColor
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: _pickEndDateTime,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'End Date',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            suffixIcon: Icon(Icons.calendar_today, size: 18),
                          ),
                          child: Text(
                            _formatDate(_endDate),
                            style: TextStyle(
                              color: _endDate == null
                                  ? Theme.of(context).hintColor
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _pickStartDateTime,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Start Time',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            suffixIcon: Icon(Icons.access_time, size: 18),
                          ),
                          child: Text(
                            _formatTime(_startDate),
                            style: TextStyle(
                              color: _startDate == null
                                  ? Theme.of(context).hintColor
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: _pickEndDateTime,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'End Time',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            suffixIcon: Icon(Icons.access_time, size: 18),
                          ),
                          child: Text(
                            _formatTime(_endDate),
                            style: TextStyle(
                              color: _endDate == null
                                  ? Theme.of(context).hintColor
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Price (Baht)',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                prefixText: '฿ ',
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OutlinedButton.icon(
                  onPressed: _openMapPicker,
                  icon: const Icon(Icons.map_outlined),
                  label: Text(
                    _pinnedLocation == null
                        ? 'Pin Location on Map'
                        : 'Change Pinned Location',
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
                if (_pinnedLocation != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Lat: ${_pinnedLocation!.latitude.toStringAsFixed(6)},  Lng: ${_pinnedLocation!.longitude.toStringAsFixed(6)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ),
            const Spacer(),
            FilledButton(
              onPressed: _isSubmitting ? null : _submitRequestMoney,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _isEditMode ? 'Update Request' : 'Send Request',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinnedLocationResult {
  _PinnedLocationResult({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

class _RequestMoneyLocationPickerSheet extends StatefulWidget {
  const _RequestMoneyLocationPickerSheet({required this.initialCenter});

  final LatLng initialCenter;

  @override
  State<_RequestMoneyLocationPickerSheet> createState() =>
      _RequestMoneyLocationPickerSheetState();
}

class _RequestMoneyLocationPickerSheetState
    extends State<_RequestMoneyLocationPickerSheet> {
  late LatLng _cameraTarget;
  LatLng? _selectedPoint;

  @override
  void initState() {
    super.initState();
    _cameraTarget = widget.initialCenter;
    _selectedPoint = widget.initialCenter;
  }

  void _pinAtCenter() {
    setState(() {
      _selectedPoint = _cameraTarget;
    });
  }

  void _confirmPick() {
    final selectedPoint = _selectedPoint;
    if (selectedPoint == null) return;

    Navigator.pop(
      context,
      _PinnedLocationResult(
        latitude: selectedPoint.latitude,
        longitude: selectedPoint.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canConfirm = _selectedPoint != null;
    final height = MediaQuery.of(context).size.height * 0.75;

    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pin Location',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text(
              'GPS is used as the starting pin. Move/adjust the pin, then confirm.',
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: widget.initialCenter,
                    zoom: 15,
                  ),
                  onTap: (point) => setState(() => _selectedPoint = point),
                  onCameraMove: (cameraPosition) {
                    _cameraTarget = cameraPosition.target;
                  },
                  markers: <Marker>{
                    if (_selectedPoint != null)
                      Marker(
                        markerId: const MarkerId(
                          'request-money-pinned-location',
                        ),
                        position: _selectedPoint!,
                        draggable: true,
                        onDragEnd: (point) =>
                            setState(() => _selectedPoint = point),
                      ),
                  },
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _pinAtCenter,
                  icon: const Icon(Icons.add_location_alt_outlined),
                  label: const Text('Pin center'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: canConfirm ? _confirmPick : null,
                  child: const Text('Confirm pin'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
