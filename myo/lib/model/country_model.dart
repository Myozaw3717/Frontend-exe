class Country {
  final int countryId;
  final int? currencyId;
  final String countryCode;
  final String countryName;
  final String? iso;
  final String? phone;
  final String? defaultTimeZone;
  final String? defaultLanguage;
  final String? dateFormat;
  final bool allowAssetLocation;
  final bool defaultCountry;
  final bool isActive;

  const Country({
    required this.countryId,
    this.currencyId,
    required this.countryCode,
    required this.countryName,
    this.iso,
    this.phone,
    this.defaultTimeZone,
    this.defaultLanguage,
    this.dateFormat,
    this.allowAssetLocation = true,
    this.defaultCountry = false,
    this.isActive = true,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      countryId: _toInt(json['country_id']) ?? 0,
      currencyId: _toInt(json['currency'] ?? json['currency_id']),
      countryCode: json['country_code']?.toString() ?? '',
      countryName: json['country_name']?.toString() ?? '',
      iso: json['iso']?.toString(),
      phone: json['phone']?.toString(),
      defaultTimeZone: json['defalut_time_zone']?.toString() ??
          json['default_time_zone']?.toString(),
      defaultLanguage: json['default_language']?.toString(),
      dateFormat: json['date_format']?.toString(),
      allowAssetLocation:
          _toBool(json['allow_asset_location'], true),
      defaultCountry: _toBool(json['default_country'], false),
      isActive: _toBool(json['is_active'], true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'country_id': countryId,
      'currency': currencyId,
      'country_code': countryCode,
      'country_name': countryName,
      'iso': iso,
      'phone': phone,
      'defalut_time_zone': defaultTimeZone,
      'default_language': defaultLanguage,
      'date_format': dateFormat,
      'allow_asset_location': allowAssetLocation,
      'default_country': defaultCountry,
      'is_active': isActive,
    };
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static bool _toBool(dynamic value, bool defaultValue) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is num) return value != 0;

    final text = value.toString().toLowerCase();
    if (text == 'true' || text == '1') return true;
    if (text == 'false' || text == '0') return false;

    return defaultValue;
  }
}