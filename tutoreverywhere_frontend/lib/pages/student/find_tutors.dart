import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:tutoreverywhere_frontend/constants/app_constants.dart';
import 'package:tutoreverywhere_frontend/models/tutors/find_tutors.dart';
import 'package:tutoreverywhere_frontend/pages/tutor/profile.dart';

class FindTutorsPage extends StatefulWidget {
  const FindTutorsPage({super.key, this.initialSubjectFilter});

  final String? initialSubjectFilter;

  @override
  State<FindTutorsPage> createState() => _FindTutorsPageState();
}

class _FindTutorsPageState extends State<FindTutorsPage> {
  final TextEditingController _searchController = TextEditingController();

  late final Dio _dio;
  static const String _baseUrl = AppConstants.baseUrl;

  List<FindTutors> _tutors = [];
  bool _isLoading = true;
  String? _errorMessage;

  String? _subjectFilter;
  String? _provinceFilter;
  String? _zoneFilter;
  String? _locationFilter;
  int? _maxPriceFilter;
  _TutorSort _sortBy = _TutorSort.popularityDesc;

  @override
  void initState() {
    super.initState();
    _setupDio();
    _subjectFilter = widget.initialSubjectFilter;
    _fetchTutors();
  }

  void _setupDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        validateStatus: (status) => status != null,
      ),
    );
    _dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true, error: true),
    );
  }

  Future<void> _fetchTutors() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final queryParams = <String, dynamic>{
        'sortby': _sortBy.queryValue,
        if (_subjectFilter != null) 'subject': _subjectFilter,
        if (_provinceFilter != null) 'province': _provinceFilter,
        if (_zoneFilter != null) 'zone': _zoneFilter,
        if (_locationFilter != null) 'location': _locationFilter,
        if (_maxPriceFilter != null) 'maxprice': _maxPriceFilter.toString(),
        if (_searchController.text.trim().isNotEmpty)
          'name': _searchController.text.trim(),
      };

      final response = await _dio.get<dynamic>(
        'tutors',
        queryParameters: queryParams,
      );

      if (!mounted) return;

      final data = response.data;
      List<FindTutors> results;

      if (data is List) {
        results = data
            .map((e) => FindTutors.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (data is Map<String, dynamic>) {
        results = [FindTutors.fromJson(data)];
      } else {
        results = [];
      }

      setState(() {
        _tutors = results;
        _isLoading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message ?? 'Failed to load tutors';
        _isLoading = false;
      });
      debugPrint('Dio Error: ${e.type} - ${e.message}');
      debugPrint('Response: ${e.response?.data}');
    } catch (e, stackTrace) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unexpected error: $e';
        _isLoading = false;
      });
      debugPrint('Error: $e\nStack: $stackTrace');
    }
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
    _fetchTutors();
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
    _fetchTutors();
  }

  Future<void> _openTeacherProfile(FindTutors tutor) async {
    final selectedTab = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (context) => TutorProfilePage(userId: tutor.userUuid),
      ),
    );
    if (!mounted || selectedTab == null) return;
    Navigator.pop(context, selectedTab);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _dio.close(force: true);
    super.dispose();
  }

  ImageProvider? _resolveProfileImage(String pic) {
    if (pic.isEmpty) return null;

    if (pic.contains('default_pfp.png')) {
      return NetworkImage(AppConstants.defaultProfilePictureUrl);
    }

    final url = AppConstants.resolveApiUrl(pic);
    return NetworkImage(url);
  }

  @override
  Widget build(BuildContext context) {
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
                      onSubmitted: (_) => _fetchTutors(),
                      textInputAction: TextInputAction.search,
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
                            _fetchTutors();
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
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Error: $_errorMessage'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchTutors, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_tutors.isEmpty) return const Center(child: Text('No tutors found'));

    return ListView.separated(
      itemCount: _tutors.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final tutor = _tutors[index];
        return _buildVerticalTutorCard(
          tutor: tutor,
          onTap: () => _openTeacherProfile(tutor),
        );
      },
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
    required FindTutors tutor,
    required VoidCallback onTap,
  }) {
    final fullName = '${tutor.firstname} ${tutor.lastname}';
    final rating = double.tryParse(tutor.avgRating);
    final title = rating != null
        ? '$fullName (${rating.toStringAsFixed(1)} ⭐)'
        : fullName;

    final subjects = tutor.subjectByPrice.entries.toList();
    final profileImage = _resolveProfileImage(tutor.profilePicture);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFCF9FF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.green.shade200,
                backgroundImage: profileImage,
                child: profileImage == null
                    ? const Icon(Icons.person, size: 34, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    if (subjects.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: subjects.map((e) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.deepPurple.shade100,
                              ),
                            ),
                            child: Text(
                              '${e.key} · ${e.value} ฿/hr',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.deepPurple.shade800,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    if (tutor.location != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.red.shade400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            tutor.location!,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (tutor.province != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        tutor.province!,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      '${tutor.reviewCount} review${tutor.reviewCount == "1" ? "" : "s"}',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
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

// ---------------------------------------------------------------------------
// Filter sheet
// ---------------------------------------------------------------------------

class _FilterTutorsSheet extends StatefulWidget {
  const _FilterTutorsSheet({required this.initial});

  final _TutorFilterState initial;

  @override
  State<_FilterTutorsSheet> createState() => _FilterTutorsSheetState();
}

class _FilterTutorsSheetState extends State<_FilterTutorsSheet> {
  late String? _subject = widget.initial.subject;
  late String? _province = widget.initial.province;
  late String? _zone = widget.initial.zone;
  late String? _location = widget.initial.location;
  late int? _maxPrice = widget.initial.maxPrice;
  late _TutorSort _sortBy = widget.initial.sortBy;
  late final TextEditingController _priceController;

  static const int _minPrice = 100;
  static const int _maxPriceCap = 1000;

  static const _subjects = AppConstants.featuredSubjects;

  // Thailand's 6 regions → provinces
  static const _regionProvinces = AppConstants.regionProvinces;

  // Locations defined per province (extend as needed)
  static const _provinceLocations = AppConstants.provinceLocations;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(text: _maxPrice?.toString() ?? '');
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
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
    _syncPriceField();
  }

  // When zone changes, clear province & location downstream
  void _onZoneChanged(String? zone) => setState(() {
    _zone = zone;
    _province = null;
    _location = null;
  });

  // When province changes, clear location downstream
  void _onProvinceChanged(String? province) => setState(() {
    _province = province;
    _location = null;
  });

  void _updateMaxPrice(int? value) {
    setState(() => _maxPrice = value?.clamp(1, _maxPriceCap));
    _syncPriceField();
  }

  void _syncPriceField() {
    final text = _maxPrice?.toString() ?? '';
    if (_priceController.text == text) return;
    _priceController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _handlePriceChanged(String value) {
    if (value.isEmpty) {
      setState(() => _maxPrice = null);
      return;
    }
    final parsed = int.tryParse(value);
    if (parsed != null) _updateMaxPrice(parsed.clamp(1, _maxPriceCap));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provincesInZone = _zone != null
        ? (_regionProvinces[_zone] ?? <String>[])
        : <String>[];
    final locationsInProvince = _province != null
        ? (_provinceLocations[_province] ?? <String>[])
        : <String>[];
    final hasLocations = locationsInProvince.isNotEmpty;

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
              // ── Header ──
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

              // ── Quick Search ──
              _buildSectionLabel('Quick Search'),
              const SizedBox(height: 12),

              _buildSectionLabel('Subject'),
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
                  for (final s in _subjects.take(3))
                    _buildChoiceChip(
                      label: s,
                      selected: _subject == s,
                      onSelected: () => setState(() => _subject = s),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              _buildSectionLabel('Zone'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildChoiceChip(
                    label: 'Any',
                    selected: _zone == null,
                    onSelected: () => _onZoneChanged(null),
                  ),
                  for (final z in _regionProvinces.keys.take(3))
                    _buildChoiceChip(
                      label: z,
                      selected: _zone == z,
                      onSelected: () => _onZoneChanged(z),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              _buildSectionLabel('Sort'),
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

              _buildSectionLabel('Price'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildChoiceChip(
                    label: 'No limit',
                    selected: _maxPrice == null,
                    onSelected: () => _updateMaxPrice(null),
                  ),
                  for (final v in const [250, 300, 400])
                    _buildChoiceChip(
                      label: '<= $v',
                      selected: _maxPrice == v,
                      onSelected: () => _updateMaxPrice(v),
                    ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Filters ──
              _buildSectionLabel('Filters'),
              const SizedBox(height: 12),

              // Subject
              _buildDropdownField<String?>(
                label: 'Subject',
                value: _subject,
                items: _buildStringDropdownItems(
                  anyLabel: 'Any subject',
                  options: _subjects,
                ),
                onChanged: (v) => setState(() => _subject = v),
              ),
              const SizedBox(height: 12),

              // Zone (region of Thailand)
              _buildDropdownField<String?>(
                label: 'Zone (Region)',
                value: _zone,
                items: _buildStringDropdownItems(
                  anyLabel: 'Any zone',
                  options: _regionProvinces.keys.toList(),
                ),
                onChanged: _onZoneChanged,
              ),
              const SizedBox(height: 12),

              // Province — only shown after zone is selected
              if (_zone != null) ...[
                _buildDropdownField<String?>(
                  label: 'Province',
                  value: _province,
                  items: _buildStringDropdownItems(
                    anyLabel: 'Any province',
                    options: provincesInZone,
                  ),
                  onChanged: _onProvinceChanged,
                ),
                const SizedBox(height: 12),
              ],

              // Location — shown when province has known locations
              if (_province != null && hasLocations) ...[
                _buildDropdownField<String?>(
                  label: 'Location',
                  value: _location,
                  items: _buildStringDropdownItems(
                    anyLabel: 'Any location',
                    options: locationsInProvince,
                  ),
                  onChanged: (v) => setState(() => _location = v),
                ),
                const SizedBox(height: 12),
              ],

              // Price limit
              _buildSectionLabel('Price Limit'),
              const SizedBox(height: 8),
              SwitchListTile(
                value: _maxPrice != null,
                contentPadding: EdgeInsets.zero,
                activeThumbColor: Colors.deepPurple,
                title: const Text(
                  'Enable price limit',
                  style: TextStyle(fontSize: 15, color: Colors.black87),
                ),
                onChanged: (enabled) =>
                    _updateMaxPrice(enabled ? (_maxPrice ?? 500) : null),
              ),
              TextField(
                controller: _priceController,
                enabled: _maxPrice != null,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Custom max price',
                  hintText: 'Enter price in Baht',
                  filled: true,
                  fillColor: _maxPrice != null
                      ? Colors.white
                      : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onChanged: _handlePriceChanged,
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
                if (_maxPrice! >= _minPrice)
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
                      onChanged: (value) =>
                          _updateMaxPrice((value / 50).round() * 50),
                    ),
                  ),
              ],
              const SizedBox(height: 8),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(
                      context,
                      _TutorFilterState(
                        subject: _subject,
                        province: _province,
                        zone: _zone,
                        location: _location,
                        maxPrice: _maxPrice,
                        sortBy: _sortBy,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(fontWeight: FontWeight.bold),
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

  Widget _buildSectionLabel(String label) => Text(
    label,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: Colors.black87,
    ),
  );

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T?>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<T?>(
          value: value,
          isExpanded: true,
          items: items,
          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.deepPurple.shade200),
            ),
          ),
        ),
      ],
    );
  }

  List<DropdownMenuItem<String?>> _buildStringDropdownItems({
    required String anyLabel,
    required List<String> options,
  }) {
    return [
      DropdownMenuItem<String?>(value: null, child: Text(anyLabel)),
      ...options.map(
        (o) => DropdownMenuItem<String?>(value: o, child: Text(o)),
      ),
    ];
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

// ---------------------------------------------------------------------------
// Supporting types
// ---------------------------------------------------------------------------

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

extension _TutorSortExt on _TutorSort {
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

  String get queryValue {
    switch (this) {
      case _TutorSort.popularityDesc:
        return 'popular';
      case _TutorSort.ratingDesc:
        return 'toprated';
      case _TutorSort.priceAsc:
        return 'lowprice';
      case _TutorSort.priceDesc:
        return 'maxprice';
    }
  }
}
