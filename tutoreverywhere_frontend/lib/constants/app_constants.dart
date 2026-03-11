class AppConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/',
  );

  static String get normalizedBaseUrl {
    return baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
  }

  static String get defaultProfilePictureUrl {
    return resolveApiUrl('assets/pfp/default_pfp.png');
  }

  static String _normalizeRelativePath(String path) {
    var normalized = path.trim().replaceAll('\\', '/');

    final assetsIndex = normalized.toLowerCase().indexOf('assets/');
    if (assetsIndex > 0) {
      normalized = normalized.substring(assetsIndex);
    }

    return normalized.replaceFirst(RegExp(r'^/+'), '');
  }

  static String resolveApiUrl(String? path, {String? fallbackRelativePath}) {
    final trimmedPath = path?.trim() ?? '';
    if (trimmedPath.isEmpty) {
      final fallback = fallbackRelativePath?.trim() ?? '';
      if (fallback.isEmpty) return normalizedBaseUrl;
      if (fallback.startsWith('http://') || fallback.startsWith('https://')) {
        return fallback;
      }
      return '$normalizedBaseUrl${_normalizeRelativePath(fallback)}';
    }

    if (trimmedPath.startsWith('http://') ||
        trimmedPath.startsWith('https://')) {
      return trimmedPath;
    }

    return '$normalizedBaseUrl${_normalizeRelativePath(trimmedPath)}';
  }

  static const List<String> featuredSubjects = [
    'English',
    'Science',
    'Math',
    'Thai',
  ];
  // Thailand's 6 regions → provinces
  static const regionProvinces = <String, List<String>>{
    'Central': [
      'Bangkok',
      'Ang Thong',
      'Chai Nat',
      'Kanchanaburi',
      'Lop Buri',
      'Nakhon Nayok',
      'Nakhon Pathom',
      'Nonthaburi',
      'Pathum Thani',
      'Phra Nakhon Si Ayutthaya',
      'Prachin Buri',
      'Ratchaburi',
      'Samut Prakan',
      'Samut Sakhon',
      'Samut Songkhram',
      'Saraburi',
      'Sing Buri',
      'Suphan Buri',
    ],
    'Northern': [
      'Chiang Mai',
      'Chiang Rai',
      'Kamphaeng Phet',
      'Lampang',
      'Lamphun',
      'Mae Hong Son',
      'Nan',
      'Phayao',
      'Phetchabun',
      'Phichit',
      'Phitsanulok',
      'Phrae',
      'Sukhothai',
      'Tak',
      'Uthai Thani',
      'Uttaradit',
    ],
    'Northeastern': [
      'Amnat Charoen',
      'Bueng Kan',
      'Buri Ram',
      'Chaiyaphum',
      'Kalasin',
      'Khon Kaen',
      'Loei',
      'Maha Sarakham',
      'Mukdahan',
      'Nakhon Phanom',
      'Nakhon Ratchasima',
      'Nong Bua Lam Phu',
      'Nong Khai',
      'Roi Et',
      'Sa Kaeo',
      'Sakon Nakhon',
      'Si Sa Ket',
      'Surin',
      'Ubon Ratchathani',
      'Udon Thani',
      'Yasothon',
    ],
    'Eastern': [
      'Chachoengsao',
      'Chanthaburi',
      'Chon Buri',
      'Rayong',
      'Sa Kaeo',
      'Trat',
    ],
    'Western': [
      'Kanchanaburi',
      'Phetchaburi',
      'Prachuap Khiri Khan',
      'Ratchaburi',
      'Samut Songkhram',
      'Tak',
    ],
    'Southern': [
      'Chumphon',
      'Krabi',
      'Nakhon Si Thammarat',
      'Narathiwat',
      'Pattani',
      'Phangnga',
      'Phatthalung',
      'Phuket',
      'Ranong',
      'Satun',
      'Songkhla',
      'Surat Thani',
      'Trang',
      'Yala',
    ],
  };

  // Locations defined per province (extend as needed)
  static const provinceLocations = <String, List<String>>{
    'Bangkok': [
      'Bang Kapi',
      'Bang Khae',
      'Bang Khen',
      'Bang Kolaem',
      'Bang Na',
      'Bang Rak',
      'Bang Sue',
      'Bangbon',
      'Chatuchak',
      'Chom Thong',
      'Din Daeng',
      'Don Mueang',
      'Dusit',
      'Huai Khwang',
      'Khan Na Yao',
      'Khlong Sam Wa',
      'Khlong San',
      'Khlong Toei',
      'Lak Si',
      'Lat Krabang',
      'Lat Phrao',
      'Meen Buri',
      'Minburi',
      'Nong Chok',
      'Nong Khaem',
      'Pasi Charoen',
      'Pathum Wan',
      'Phaya Thai',
      'Phra Khanong',
      'Phra Nakhon',
      'Pom Prap Sattru Phai',
      'Prawet',
      'Rat Burana',
      'Ratchathewi',
      'Sai Mai',
      'Samphanthawong',
      'Saphan Sung',
      'Sathon',
      'Suan Luang',
      'Taling Chan',
      'Thawi Watthana',
      'Thon Buri',
      'Thung Khru',
      'Wang Thonglang',
      'Yan Nawa',
    ],
    'Nonthaburi': [
      'Mueang Nonthaburi',
      'Bang Bua Thong',
      'Bang Kruai',
      'Bang Yai',
      'Pak Kret',
      'Sai Noi',
    ],
    'Pathum Thani': [
      'Mueang Pathum Thani',
      'Khlong Luang',
      'Lam Luk Ka',
      'Lat Lum Kaeo',
      'Rangsit',
      'Sam Khok',
      'Thanyaburi',
    ],
    'Samut Prakan': [
      'Mueang Samut Prakan',
      'Bang Bo',
      'Bang Phli',
      'Bang Sao Thong',
      'Pak Nam',
      'Phra Pradaeng',
      'Phra Samut Chedi',
    ],
    'Chiang Mai': [
      'Mueang Chiang Mai',
      'Chiang Dao',
      'Doi Saket',
      'Fang',
      'Hot',
      'Mae Rim',
      'Mae Taeng',
      'Samoeng',
      'San Kamphaeng',
      'San Sai',
    ],
    'Chon Buri': [
      'Mueang Chon Buri',
      'Bang Lamung',
      'Bo Thong',
      'Ko Chan',
      'Ko Si Chang',
      'Pattaya',
      'Phan Thong',
      'Sattahip',
      'Si Racha',
    ],
  };

  static List<String> getProvincesForRegion(String region) =>
      regionProvinces[region] ?? [];

  static List<String> getLocationsForProvince(String province) =>
      provinceLocations[province] ?? [];

  static String findRegionForProvince(String province) {
    for (final entry in regionProvinces.entries) {
      if (entry.value.contains(province)) return entry.key;
    }
    return 'Central'; // default fallback
  }
}
