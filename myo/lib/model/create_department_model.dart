class CreateDepartment {
  final int? parentDeptId;
  final String deptCode;
  final String deptName;
  final String deptShortName;
  final String deptType;
  final bool allowAssignment;
  final bool isActive;

  CreateDepartment({
    this.parentDeptId,
    required this.deptCode,
    required this.deptName,
    required this.deptShortName,
    required this.deptType,
    this.allowAssignment = true,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'parent_dept': parentDeptId,
      'dept_code': deptCode,
      'dept_name': deptName,
      'dept_short_name': deptShortName,
      'dept_type': deptType,
      'allow_assignment': allowAssignment,
      'is_active': isActive,
    };
  }
}