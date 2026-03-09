import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tutoreverywhere_frontend/constants/app_constants.dart';

class RequestMoneyPage extends StatefulWidget {
  RequestMoneyPage({
    super.key,
    this.initialPeerUserId,
    this.initialPeerDisplayName,
  });

  final String? initialPeerUserId;
  final String? initialPeerDisplayName;

  @override
  State<RequestMoneyPage> createState() => _RequestMoneyPageState();
}

class _RequestMoneyPageState extends State<RequestMoneyPage> {
  static const List<String> _availableSubjects = AppConstants.featuredSubjects;

  String? selectedSubject;
  String? _activePeerUserId;
  String _activePeerDisplayName = '';

  final TextEditingController _placeNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  LatLng? _pinnedLocation;

  @override
  void initState() {
    super.initState();
    _activePeerUserId = widget.initialPeerUserId;
    _activePeerDisplayName = widget.initialPeerDisplayName?.trim() ?? '';
  }

  @override
  void dispose() {
    _placeNameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDateTime({
    required DateTime? currentDate,
    required TimeOfDay? currentTime,
    required bool isStart,
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
      currentTime: _startDate != null ? TimeOfDay.fromDateTime(_startDate!) : null,
      isStart: true,
    );
    if (result != null) {
      setState(() {
        _startDate = result;
        if (_endDate != null && _endDate!.isBefore(result)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _pickEndDateTime() async {
    final result = await _pickDateTime(
      currentDate: _endDate,
      currentTime: _endDate != null ? TimeOfDay.fromDateTime(_endDate!) : null,
      isStart: false,
    );
    if (result != null) {
      setState(() => _endDate = result);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '--:--';
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => _MapPickerPage(initialLocation: _pinnedLocation),
      ),
    );
    if (result != null) {
      setState(() => _pinnedLocation = result);
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
              value: selectedSubject,
              decoration: const InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
              items: _availableSubjects.map((subject) {
                return DropdownMenuItem(value: subject, child: Text(subject));
              }).toList(),
              onChanged: (value) => setState(() => selectedSubject = value),
              validator: (value) =>
                  value == null ? 'Please select a subject' : null,
            ),

            TextField(
              controller: _placeNameController,
              decoration: const InputDecoration(
                labelText: 'Place Name (optional)',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),

            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            suffixIcon: Icon(Icons.calendar_today, size: 18),
                          ),
                          child: Text(
                            _formatDate(_startDate),
                            style: TextStyle(
                              color: _startDate == null ? Theme.of(context).hintColor : null,
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
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            suffixIcon: Icon(Icons.calendar_today, size: 18),
                          ),
                          child: Text(
                            _formatDate(_endDate),
                            style: TextStyle(
                              color: _endDate == null ? Theme.of(context).hintColor : null,
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
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            suffixIcon: Icon(Icons.access_time, size: 18),
                          ),
                          child: Text(
                            _formatTime(_startDate),
                            style: TextStyle(
                              color: _startDate == null ? Theme.of(context).hintColor : null,
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
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            suffixIcon: Icon(Icons.access_time, size: 18),
                          ),
                          child: Text(
                            _formatTime(_endDate),
                            style: TextStyle(
                              color: _endDate == null ? Theme.of(context).hintColor : null,
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
                labelText: 'Price (฿)',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                prefixText: '\$ ',
              ),
            ),

            // Map location picker button + coordinate display
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OutlinedButton.icon(
                  onPressed: _openMapPicker,
                  icon: const Icon(Icons.map_outlined),
                  label: Text(_pinnedLocation == null ? 'Pin Location on Map' : 'Change Pinned Location'),
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

            // Send Request button
            FilledButton(
              onPressed: null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: const Text('Send Request', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPickerPage extends StatefulWidget {
  const _MapPickerPage({this.initialLocation});
  final LatLng? initialLocation;

  @override
  State<_MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<_MapPickerPage> {
  static const LatLng _defaultLocation = LatLng(37.7749, -122.4194); // San Francisco fallback

  late LatLng _markerPosition;

  @override
  void initState() {
    super.initState();
    _markerPosition = widget.initialLocation ?? _defaultLocation;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pin Location'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _markerPosition),
            child: const Text('Confirm'),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _markerPosition,
              zoom: 14,
            ),
            markers: {
              Marker(
                markerId: const MarkerId('pinned'),
                position: _markerPosition,
                draggable: true,
                onDragEnd: (pos) => setState(() => _markerPosition = pos),
              ),
            },
            onTap: (pos) => setState(() => _markerPosition = pos),
          ),
          // Hint banner
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  'Tap on the map or drag the marker to set location',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}