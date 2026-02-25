import 'package:flutter/material.dart';
import 'package:tutoreverywhere_frontend/pages/student/teacher_profile.dart';

class FindTutorsPage extends StatefulWidget {
  const FindTutorsPage({super.key});

  @override
  State<FindTutorsPage> createState() => _FindTutorsPageState();
}

class _FindTutorsPageState extends State<FindTutorsPage> {
  final TextEditingController _searchController = TextEditingController();

  final List<_TutorItem> _tutors = const [
    _TutorItem(
      name: 'Tutor 1',
      rating: 5.0,
      popularityScore: 97,
      subject: 'English',
      province: 'Bangkok',
      zone: 'North Bangkok',
      location: 'Chatuchak',
      pricePerHour: 300,
    ),
    _TutorItem(
      name: 'Tutor 2',
      rating: 5.0,
      popularityScore: 90,
      subject: 'Science',
      province: 'Bangkok',
      zone: 'North Bangkok',
      location: 'Ladprao',
      pricePerHour: 300,
    ),
    _TutorItem(
      name: 'Tutor 3',
      rating: 4.9,
      popularityScore: 88,
      subject: 'Math',
      province: 'Bangkok',
      zone: 'Central Bangkok',
      location: 'Bang Sue',
      pricePerHour: 350,
    ),
    _TutorItem(
      name: 'Tutor 4',
      rating: 4.8,
      popularityScore: 82,
      subject: 'English',
      province: 'Nonthaburi',
      zone: 'West Metropolitan',
      location: 'Mueang Nonthaburi',
      pricePerHour: 250,
    ),
    _TutorItem(
      name: 'Tutor 5',
      rating: 4.7,
      popularityScore: 79,
      subject: 'Thai',
      province: 'Pathum Thani',
      zone: 'North Metropolitan',
      location: 'Rangsit',
      pricePerHour: 280,
    ),
    _TutorItem(
      name: 'Tutor 6',
      rating: 4.9,
      popularityScore: 92,
      subject: 'Science',
      province: 'Samut Prakan',
      zone: 'South Metropolitan',
      location: 'Pak Nam',
      pricePerHour: 320,
    ),
  ];

  String? _subjectFilter;
  String? _provinceFilter;
  String? _zoneFilter;
  String? _locationFilter;
  int? _maxPriceFilter;
  _TutorSort _sortBy = _TutorSort.popularityDesc;

  String get _query => _searchController.text.trim().toLowerCase();

  List<String> get _subjects {
    final values = _tutors.map((tutor) => tutor.subject).toSet().toList();
    values.sort();
    return values;
  }

  List<String> get _locations {
    final values = _tutors.map((tutor) => tutor.location).toSet().toList();
    values.sort();
    return values;
  }

  List<String> get _zones {
    final values = _tutors.map((tutor) => tutor.zone).toSet().toList();
    values.sort();
    return values;
  }

  List<String> get _provinces {
    final values = _tutors.map((tutor) => tutor.province).toSet().toList();
    values.sort();
    return values;
  }

  bool get _hasActiveFilters =>
      _subjectFilter != null ||
      _provinceFilter != null ||
      _zoneFilter != null ||
      _locationFilter != null ||
      _maxPriceFilter != null;

  int get _activeFilterCount {
    var count = 0;
    if (_subjectFilter != null) count++;
    if (_provinceFilter != null) count++;
    if (_zoneFilter != null) count++;
    if (_locationFilter != null) count++;
    if (_maxPriceFilter != null) count++;
    return count;
  }

  List<_TutorItem> get _filteredTutors {
    final results = _tutors.where((tutor) {
      final matchesQuery = _query.isEmpty || tutor.searchText.contains(_query);
      final matchesSubject =
          _subjectFilter == null || tutor.subject == _subjectFilter;
      final matchesProvince =
          _provinceFilter == null || tutor.province == _provinceFilter;
      final matchesZone = _zoneFilter == null || tutor.zone == _zoneFilter;
      final matchesLocation =
          _locationFilter == null || tutor.location == _locationFilter;
      final matchesPrice =
          _maxPriceFilter == null || tutor.pricePerHour <= _maxPriceFilter!;

      return matchesQuery &&
          matchesSubject &&
          matchesProvince &&
          matchesZone &&
          matchesLocation &&
          matchesPrice;
    }).toList();

    results.sort((a, b) {
      switch (_sortBy) {
        case _TutorSort.popularityDesc:
          return b.popularityScore.compareTo(a.popularityScore);
        case _TutorSort.ratingDesc:
          return b.rating.compareTo(a.rating);
        case _TutorSort.priceAsc:
          return a.pricePerHour.compareTo(b.pricePerHour);
        case _TutorSort.priceDesc:
          return b.pricePerHour.compareTo(a.pricePerHour);
      }
    });

    return results;
  }

  Future<void> _openFilterSheet() async {
    final result = await showModalBottomSheet<_TutorFilterState>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _FilterTutorsSheet(
          initial: _TutorFilterState(
            subject: _subjectFilter,
            province: _provinceFilter,
            zone: _zoneFilter,
            location: _locationFilter,
            maxPrice: _maxPriceFilter,
            sortBy: _sortBy,
          ),
          subjects: _subjects,
          provinces: _provinces,
          zones: _zones,
          locations: _locations,
        );
      },
    );

    if (!mounted || result == null) return;

    setState(() {
      _subjectFilter = result.subject;
      _provinceFilter = result.province;
      _zoneFilter = result.zone;
      _locationFilter = result.location;
      _maxPriceFilter = result.maxPrice;
      _sortBy = result.sortBy;
    });
  }

  void _clearFilters() {
    setState(() {
      _subjectFilter = null;
      _provinceFilter = null;
      _zoneFilter = null;
      _locationFilter = null;
      _maxPriceFilter = null;
      _sortBy = _TutorSort.popularityDesc;
    });
  }

  Future<void> _openTeacherProfile(_TutorItem tutor) async {
    final selectedTab = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (context) => TeacherProfilePage(tutorName: tutor.name),
      ),
    );

    if (!mounted || selectedTab == null) return;

    Navigator.pop(context, selectedTab);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tutors = _filteredTutors;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Find Tutors',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search for name here',
                        hintStyle: TextStyle(color: Colors.grey.shade600),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.black54,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(
                            Icons.cancel_outlined,
                            color: Colors.black54,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: _openFilterSheet,
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: _hasActiveFilters
                          ? Colors.deepPurple.shade50
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _hasActiveFilters
                            ? Colors.deepPurple.shade200
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.tune,
                          color: _hasActiveFilters
                              ? Colors.deepPurple
                              : Colors.black54,
                        ),
                        if (_hasActiveFilters) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$_activeFilterCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_hasActiveFilters) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (_subjectFilter != null)
                      _buildActiveChip('Subject: $_subjectFilter'),
                    if (_provinceFilter != null)
                      _buildActiveChip('Province: $_provinceFilter'),
                    if (_zoneFilter != null)
                      _buildActiveChip('Zone: $_zoneFilter'),
                    if (_locationFilter != null)
                      _buildActiveChip('Location: $_locationFilter'),
                    if (_maxPriceFilter != null)
                      _buildActiveChip('<= $_maxPriceFilter Baht'),
                    ActionChip(
                      label: const Text('Clear'),
                      onPressed: _clearFilters,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            Expanded(
              child: tutors.isEmpty
                  ? const Center(child: Text('No tutors found'))
                  : ListView.separated(
                      itemCount: tutors.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final tutor = tutors[index];
                        return _buildVerticalTutorCard(
                          tutor: tutor,
                          onTap: () => _openTeacherProfile(tutor),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveChip(String label) {
    return Chip(
      label: Text(label),
      backgroundColor: Colors.deepPurple.shade50,
      side: BorderSide(color: Colors.deepPurple.shade100),
      labelStyle: const TextStyle(fontSize: 12),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildVerticalTutorCard({
    required _TutorItem tutor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFCF9FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.green.shade200,
                child: const Icon(Icons.person, size: 45, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tutor.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tutor.subject,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.red.shade400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          tutor.location,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${tutor.zone} • ${tutor.province}',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tutor.priceLabel,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 15,
                      ),
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
}

class _FilterTutorsSheet extends StatefulWidget {
  const _FilterTutorsSheet({
    required this.initial,
    required this.subjects,
    required this.provinces,
    required this.zones,
    required this.locations,
  });

  final _TutorFilterState initial;
  final List<String> subjects;
  final List<String> provinces;
  final List<String> zones;
  final List<String> locations;

  @override
  State<_FilterTutorsSheet> createState() => _FilterTutorsSheetState();
}

class _FilterTutorsSheetState extends State<_FilterTutorsSheet> {
  static const Object _anySelection = Object();
  late String? _subject = widget.initial.subject;
  late String? _province = widget.initial.province;
  late String? _zone = widget.initial.zone;
  late String? _location = widget.initial.location;
  late int? _maxPrice = widget.initial.maxPrice;
  late _TutorSort _sortBy = widget.initial.sortBy;

  static const int _minPrice = 100;
  static const int _maxPriceCap = 1000;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF4EDFA),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        24,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter Tutors',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  TextButton(
                    onPressed: _resetFilters,
                    child: const Text('Reset'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildFilterRow(
                label: 'Subject',
                value: _subject ?? 'Any subject',
                onTap: _pickSubject,
              ),
              _buildDivider(),
              _buildFilterRow(
                label: 'Province',
                value: _province ?? 'Any province',
                onTap: _pickProvince,
              ),
              _buildDivider(),
              _buildFilterRow(
                label: 'Zone',
                value: _zone ?? 'Any zone',
                onTap: _pickZone,
              ),
              _buildDivider(),
              _buildFilterRow(
                label: 'Sort',
                value: _sortBy.label,
                onTap: _pickSort,
              ),
              _buildDivider(),
              _buildFilterRow(
                label: 'Price',
                value: _maxPrice == null
                    ? 'No limit'
                    : 'Not over $_maxPrice Baht',
                onTap: _pickMaxPrice,
              ),
              _buildDivider(),
              _buildFilterRow(
                label: 'Location',
                value: _location ?? 'Any location',
                onTap: _pickLocation,
              ),
              _buildDivider(),
              const SizedBox(height: 16),
              _buildSectionLabel('Quick Subject'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildChoiceChip(
                    label: 'Any',
                    selected: _subject == null,
                    onSelected: () => setState(() => _subject = null),
                  ),
                  for (final subject in widget.subjects)
                    _buildChoiceChip(
                      label: subject,
                      selected: _subject == subject,
                      onSelected: () => setState(() => _subject = subject),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionLabel('Quick Province'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildChoiceChip(
                    label: 'Any',
                    selected: _province == null,
                    onSelected: () => setState(() => _province = null),
                  ),
                  for (final province in widget.provinces)
                    _buildChoiceChip(
                      label: province,
                      selected: _province == province,
                      onSelected: () => setState(() => _province = province),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionLabel('Quick Zone'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildChoiceChip(
                    label: 'Any',
                    selected: _zone == null,
                    onSelected: () => setState(() => _zone = null),
                  ),
                  for (final zone in widget.zones)
                    _buildChoiceChip(
                      label: zone,
                      selected: _zone == zone,
                      onSelected: () => setState(() => _zone = zone),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionLabel('Quick Location'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildChoiceChip(
                    label: 'Any',
                    selected: _location == null,
                    onSelected: () => setState(() => _location = null),
                  ),
                  for (final location in widget.locations)
                    _buildChoiceChip(
                      label: location,
                      selected: _location == location,
                      onSelected: () => setState(() => _location = location),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionLabel('Quick Sort'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final sort in _TutorSort.values)
                    _buildChoiceChip(
                      label: sort.shortLabel,
                      selected: _sortBy == sort,
                      onSelected: () => setState(() => _sortBy = sort),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionLabel('Quick Price'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildChoiceChip(
                    label: 'No limit',
                    selected: _maxPrice == null,
                    onSelected: () => setState(() => _maxPrice = null),
                  ),
                  for (final value in const [250, 300, 400, 500, 700])
                    _buildChoiceChip(
                      label: '<= $value',
                      selected: _maxPrice == value,
                      onSelected: () => setState(() => _maxPrice = value),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (_maxPrice != null) ...[
                Text(
                  'Custom price cap: $_maxPrice Baht / Hour',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SliderTheme(
                  data: theme.sliderTheme.copyWith(
                    activeTrackColor: Colors.deepPurple,
                    thumbColor: Colors.deepPurple,
                    overlayColor: Colors.deepPurple.withValues(alpha: 0.15),
                  ),
                  child: Slider(
                    min: _minPrice.toDouble(),
                    max: _maxPriceCap.toDouble(),
                    divisions: (_maxPriceCap - _minPrice) ~/ 50,
                    value: _maxPrice!.toDouble().clamp(
                      _minPrice.toDouble(),
                      _maxPriceCap.toDouble(),
                    ),
                    label: '$_maxPrice',
                    onChanged: (value) {
                      setState(() {
                        _maxPrice = (value / 50).round() * 50;
                      });
                    },
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        _TutorFilterState(
                          subject: _subject,
                          province: _province,
                          zone: _zone,
                          location: _location,
                          maxPrice: _maxPrice,
                          sortBy: _sortBy,
                        ),
                      );
                    },
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _subject = null;
      _province = null;
      _zone = null;
      _location = null;
      _maxPrice = null;
      _sortBy = _TutorSort.popularityDesc;
    });
  }

  Future<void> _pickSubject() async {
    final result = await _showStringPicker(
      title: 'Select subject',
      options: widget.subjects,
      selected: _subject,
    );
    if (!mounted || result == null) return;

    setState(() {
      _subject = identical(result, _anySelection) ? null : result as String;
    });
  }

  Future<void> _pickLocation() async {
    final result = await _showStringPicker(
      title: 'Select location',
      options: widget.locations,
      selected: _location,
    );
    if (!mounted || result == null) return;

    setState(() {
      _location = identical(result, _anySelection) ? null : result as String;
    });
  }

  Future<void> _pickProvince() async {
    final result = await _showStringPicker(
      title: 'Select province',
      options: widget.provinces,
      selected: _province,
    );
    if (!mounted || result == null) return;

    setState(() {
      _province = identical(result, _anySelection) ? null : result as String;
    });
  }

  Future<void> _pickZone() async {
    final result = await _showStringPicker(
      title: 'Select zone',
      options: widget.zones,
      selected: _zone,
    );
    if (!mounted || result == null) return;

    setState(() {
      _zone = identical(result, _anySelection) ? null : result as String;
    });
  }

  Future<void> _pickSort() async {
    final result = await showDialog<_TutorSort>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Sort tutors'),
          children: [
            for (final sort in _TutorSort.values)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, sort),
                child: Row(
                  children: [
                    Expanded(child: Text(sort.label)),
                    if (sort == _sortBy)
                      const Icon(
                        Icons.check,
                        size: 18,
                        color: Colors.deepPurple,
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );

    if (!mounted || result == null) return;

    setState(() {
      _sortBy = result;
    });
  }

  Future<void> _pickMaxPrice() async {
    final result = await showDialog<_PricePickerResult>(
      context: context,
      builder: (context) {
        var enabled = _maxPrice != null;
        var tempPrice = (_maxPrice ?? 500).toDouble();

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Max price'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    value: enabled,
                    activeThumbColor: Colors.deepPurple,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Enable price limit'),
                    onChanged: (value) {
                      setDialogState(() {
                        enabled = value;
                      });
                    },
                  ),
                  if (enabled) ...[
                    Text(
                      'Not over ${tempPrice.round()} Baht / Hour',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Slider(
                      min: _minPrice.toDouble(),
                      max: _maxPriceCap.toDouble(),
                      divisions: (_maxPriceCap - _minPrice) ~/ 50,
                      value: tempPrice.clamp(
                        _minPrice.toDouble(),
                        _maxPriceCap.toDouble(),
                      ),
                      label: '${tempPrice.round()}',
                      onChanged: (value) {
                        setDialogState(() {
                          tempPrice = ((value / 50).round() * 50).toDouble();
                        });
                      },
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      _PricePickerResult(
                        enabled: enabled,
                        maxPrice: enabled ? tempPrice.round() : null,
                      ),
                    );
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || result == null) return;

    setState(() {
      _maxPrice = result.enabled ? result.maxPrice : null;
    });
  }

  Future<Object?> _showStringPicker({
    required String title,
    required List<String> options,
    required String? selected,
  }) async {
    return showDialog<Object?>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text(title),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, _anySelection),
              child: Row(
                children: [
                  const Expanded(child: Text('Any')),
                  if (selected == null)
                    const Icon(Icons.check, size: 18, color: Colors.deepPurple),
                ],
              ),
            ),
            for (final option in options)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, option),
                child: Row(
                  children: [
                    Expanded(child: Text(option)),
                    if (selected == option)
                      const Icon(
                        Icons.check,
                        size: 18,
                        color: Colors.deepPurple,
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildFilterRow({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '$label  $value',
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
            ),
            const Icon(Icons.arrow_right, color: Colors.black54, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, thickness: 1, color: Colors.grey.shade300);
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: Colors.deepPurple.shade100,
      side: BorderSide(
        color: selected ? Colors.deepPurple.shade200 : Colors.grey.shade300,
      ),
      labelStyle: TextStyle(
        fontSize: 12,
        color: selected ? Colors.deepPurple.shade900 : Colors.black87,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      ),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _PricePickerResult {
  const _PricePickerResult({required this.enabled, required this.maxPrice});

  final bool enabled;
  final int? maxPrice;
}

class _TutorItem {
  const _TutorItem({
    required this.name,
    required this.rating,
    required this.popularityScore,
    required this.subject,
    required this.province,
    required this.zone,
    required this.location,
    required this.pricePerHour,
  });

  final String name;
  final double rating;
  final int popularityScore;
  final String subject;
  final String province;
  final String zone;
  final String location;
  final int pricePerHour;

  String get title => '$name (${rating.toStringAsFixed(1)} ⭐)';
  String get priceLabel => '$pricePerHour Baht / Hour';
  String get searchText =>
      '${name.toLowerCase()} ${subject.toLowerCase()} ${location.toLowerCase()} ${zone.toLowerCase()} ${province.toLowerCase()}';
}

class _TutorFilterState {
  const _TutorFilterState({
    required this.subject,
    required this.province,
    required this.zone,
    required this.location,
    required this.maxPrice,
    required this.sortBy,
  });

  final String? subject;
  final String? province;
  final String? zone;
  final String? location;
  final int? maxPrice;
  final _TutorSort sortBy;
}

enum _TutorSort { popularityDesc, ratingDesc, priceAsc, priceDesc }

extension on _TutorSort {
  String get label {
    switch (this) {
      case _TutorSort.popularityDesc:
        return 'Most popular';
      case _TutorSort.ratingDesc:
        return 'Highest rating';
      case _TutorSort.priceAsc:
        return 'Price: low to high';
      case _TutorSort.priceDesc:
        return 'Price: high to low';
    }
  }

  String get shortLabel {
    switch (this) {
      case _TutorSort.popularityDesc:
        return 'Popular';
      case _TutorSort.ratingDesc:
        return 'Top Rated';
      case _TutorSort.priceAsc:
        return 'Low Price';
      case _TutorSort.priceDesc:
        return 'High Price';
    }
  }
}
