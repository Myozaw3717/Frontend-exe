class CreateBranch {
  final String? branchCode;
  final String branchName;
  final int? country;
  final String? region;
  final String? city;
  final String? address;
  final String? phone;
  final String? email;
  final int? postalCode;
  final bool isActive;

  const CreateBranch({
    this.branchCode,
    required this.branchName,
    this.country,
    this.region,
    this.city,
    this.address,
    this.phone,
    this.email,
    this.postalCode,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'branch_code': branchCode,
      'branch_name': branchName,
      'country': country,
      'region': region,
      'city': city,
      'address': address,
      'phone': phone,
      'email': email,
      'postal_code': postalCode,
      'is_active': isActive,
    };
  }
}