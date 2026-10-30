class Branch {
  final int branchId;
  final String? branchCode;
  final String branchName;
  final int? countryId;
  final String? region;
  final String? city;
  final String? address;
  final String? phone;
  final String? email;
  final int? postalCode;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Branch({
    required this.branchId,
    this.branchCode,
    required this.branchName,
    this.countryId,
    this.region,
    this.city,
    this.address,
    this.phone,
    this.email,
    this.postalCode,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      branchId: _toInt(json['branch_id']) ?? 0,
      branchCode: json['branch_code']?.toString(),
      branchName: json['branch_name']?.toString() ?? '',
      countryId: _toInt(json['country'] ?? json['country_id']),
      region: json['region']?.toString(),
      city: json['city']?.toString(),
      address: json['address']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      postalCode: _toInt(json['postal_code']),
      isActive: _toBool(json['is_active']),
      createdAt: _toDateTime(json['created_at']),
      updatedAt: _toDateTime(json['updated_at']),
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return true;
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}