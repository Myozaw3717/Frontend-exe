class Custodian {
  final int custodianId;
  final String? custodianCode;
  final String custodianName;
  final String custodianType;
  final String? phone;
  final String? email;
  final bool canHoldAssets;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;
  final int? branchId;
  final int? deptId;

  Custodian({
    required this.custodianId,
    this.custodianCode,
    required this.custodianName,
    required this.custodianType,
    this.phone,
    this.email,
    required this.canHoldAssets,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
    this.branchId,
    this.deptId,
  });

  factory Custodian.fromJson(Map<String, dynamic> json) {
    return Custodian(
      custodianId: int.parse(json['custodian_id'].toString()),

      custodianCode: json['custodian_code']?.toString(),

      custodianName: json['custodian_name']?.toString() ?? '',

      custodianType:
          json['custodian_type']?.toString() ?? 'SUPPLIER',

      phone: json['phone']?.toString(),

      email: json['email']?.toString(),

      canHoldAssets: _parseBool(json['can_hold_assets']),

      isActive: _parseBool(json['is_active']),

      createdAt: json['created_at']?.toString(),

      updatedAt: json['updated_at']?.toString(),

      branchId: _parseNullableInt(json['branch']),

      deptId: _parseNullableInt(json['dept']),
    );
  }

  get branchName => null;

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;

    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }

    return false;
  }

  static int? _parseNullableInt(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return null;
    }

    return int.tryParse(value.toString());
  }

  Map<String, dynamic> toJson() {
    return {
      'custodian_id': custodianId,
      'custodian_code': custodianCode,
      'custodian_name': custodianName,
      'custodian_type': custodianType,
      'phone': phone,
      'email': email,
      'can_hold_assets': canHoldAssets,
      'is_active': isActive,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'branch': branchId,
      'dept': deptId,
    };
  }
}