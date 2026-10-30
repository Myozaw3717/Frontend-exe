class Department {
  final int departmentId;
  final int? parentDeptId;
  final String deptCode;
  final String deptName;
  final String deptShortName;
  final String deptType;
  final bool allowAssignment;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;

  Department({
    required this.departmentId,
    this.parentDeptId,
    required this.deptCode,
    required this.deptName,
    required this.deptShortName,
    required this.deptType,
    required this.allowAssignment,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      departmentId: int.parse(json['department_id'].toString()),
      parentDeptId: json['parent_dept'] == null
          ? null
          : int.parse(json['parent_dept'].toString()),
      deptCode: json['dept_code']?.toString() ?? '',
      deptName: json['dept_name']?.toString() ?? '',
      deptShortName: json['dept_short_name']?.toString() ?? '',
      deptType: json['dept_type']?.toString() ?? 'OPERATIONS',
      allowAssignment: _parseBool(json['allow_assignment']),
      isActive: _parseBool(json['is_active']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  get departmentID => null;

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return false;
  }

  Map<String, dynamic> toJson() {
    return {
      'department_id': departmentId,
      'parent_dept': parentDeptId,
      'dept_code': deptCode,
      'dept_name': deptName,
      'dept_short_name': deptShortName,
      'dept_type': deptType,
      'allow_assignment': allowAssignment,
      'is_active': isActive,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}