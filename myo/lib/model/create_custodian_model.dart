class CreateCustodian {
  final String? custodianCode;
  final String custodianName;
  final String custodianType;
  final String? phone;
  final String? email;
  final bool canHoldAssets;
  final bool isActive;
  final int? branchId;
  final int? deptId;

  CreateCustodian({
    this.custodianCode,
    required this.custodianName,
    this.custodianType = 'SUPPLIER',
    this.phone,
    this.email,
    this.canHoldAssets = false,
    this.isActive = true,
    this.branchId,
    this.deptId,
  });

  Map<String, dynamic> toJson() {
    return {
      'custodian_code': custodianCode,
      'custodian_name': custodianName,
      'custodian_type': custodianType,
      'phone': phone,
      'email': email,
      'can_hold_assets': canHoldAssets,
      'is_active': isActive,
      'branch': branchId,
      'dept': deptId,
    };
  }
}