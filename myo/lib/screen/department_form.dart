
import 'package:flutter/material.dart';
import 'package:myo/model/create_department_model.dart';
import 'package:myo/model/get_department_model.dart';
import 'package:myo/service/api_service.dart';

class DepartmentForm extends StatefulWidget {
  final Department? department;

  const DepartmentForm({
    super.key,
    this.department,
  });

  @override
  State<DepartmentForm> createState() => _DepartmentFormState();
}

class _DepartmentFormState extends State<DepartmentForm> {
  final ApiService _apiService = ApiService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  static const Color primaryColor = Color.fromARGB(255, 64, 37, 222);
  static const Color backgroundColor = Color(0xFFF4F6F9);
  static const Color textColor = Color(0xFF334155);
  static const Color borderColor = Color(0xFFCBD5E1);

  final TextEditingController _codeController =
      TextEditingController();

  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _shortNameController =
      TextEditingController();

  final List<String> _departmentTypes = [
    'HR',
    'IT',
    'FINANCE',
    'SALES',
    'MARKETING',
    'OPERATIONS',
  ];

  List<Department> _departments = [];

  int _selectedParentDropdown = -1;
  String? _selectedDepartmentType;

  bool _allowAssetAssignment = true;
  bool _isActive = true;
  bool _isLoadingParents = true;
  bool _isSaving = false;
  String? _parentError;

  bool get _isEditing => widget.department != null;

  @override
  void initState() {
    super.initState();

    final department = widget.department;

    _codeController.text = department?.deptCode ?? '';
    _nameController.text = department?.deptName ?? '';
    _shortNameController.text =
        department?.deptShortName ?? '';

    final existingType = department?.deptType;

    _selectedDepartmentType =
        _departmentTypes.contains(existingType)
            ? existingType
            : 'OPERATIONS';

    _selectedParentDropdown =
        department?.parentDeptId ?? -1;

    _allowAssetAssignment =
        department?.allowAssignment ?? true;

    _isActive = department?.isActive ?? true;

    _loadParentDepartments();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _shortNameController.dispose();
    super.dispose();
  }

  Future<void> _loadParentDepartments() async {
    if (mounted) {
      setState(() {
        _isLoadingParents = true;
        _parentError = null;
      });
    }

    try {
      final result = await _apiService.fetchDepartments();

      if (!mounted) return;

      setState(() {
        _departments = result.where((department) {
          // Exclude the current department while editing.
          return department.departmentId !=
              widget.department?.departmentId;
        }).toList();

        final parentExists = _departments.any(
          (department) =>
              department.departmentId ==
              _selectedParentDropdown,
        );

        if (_selectedParentDropdown != -1 &&
            !parentExists) {
          _selectedParentDropdown = -1;
        }

        _isLoadingParents = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingParents = false;
        _parentError = e.toString();
      });
    }
  }

  String? _requiredValidator(
    String? value,
    String fieldName,
  ) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    return null;
  }

  Future<void> _saveDepartment() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final department = CreateDepartment(
        parentDeptId: _selectedParentDropdown == -1
            ? null
            : _selectedParentDropdown,
        deptCode: _codeController.text.trim(),
        deptName: _nameController.text.trim(),
        deptShortName: _shortNameController.text.trim(),
        deptType: _selectedDepartmentType ?? 'OPERATIONS',
        allowAssignment: _allowAssetAssignment,
        isActive: _isActive,
      );

      if (_isEditing) {
        await _apiService.updateDepartment(
          widget.department!.departmentId,
          department,
        );
      } else {
        await _apiService.createDepartment(department);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Department updated successfully.'
                : 'Department created successfully.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save department: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _clearForm() {
    if (_isSaving) return;

    _formKey.currentState?.reset();

    _codeController.clear();
    _nameController.clear();
    _shortNameController.clear();

    setState(() {
      _selectedParentDropdown = -1;
      _selectedDepartmentType = 'OPERATIONS';
      _allowAssetAssignment = true;
      _isActive = true;
    });
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );
  }

  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Color(0xFF94A3B8),
        fontSize: 14,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: primaryColor,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required String fieldName,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: _inputDecoration(hint),
          validator: (value) =>
              _requiredValidator(value, fieldName),
        ),
      ],
    );
  }

  Widget _buildParentDropdown() {
    if (_isLoadingParents) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: LinearProgressIndicator(
          color: primaryColor,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<int>(
          initialValue: _selectedParentDropdown,
          isExpanded: true,
          decoration: _inputDecoration(
            'Select parent department',
          ),
          items: [
            const DropdownMenuItem<int>(
              value: -1,
              child: Text(
                'No parent department',
                style: TextStyle(fontSize: 14),
              ),
            ),
            ..._departments.map(
              (department) => DropdownMenuItem<int>(
                value: department.departmentId,
                child: Text(
                  '${department.deptName} (${department.deptCode})',
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          onChanged: _isSaving
              ? null
              : (value) {
                  setState(() {
                    _selectedParentDropdown = value ?? -1;
                  });
                },
        ),
        if (_parentError != null) ...[
          const SizedBox(height: 6),
          Text(
            'Could not load parent departments.',
            style: TextStyle(
              color: Colors.red.shade700,
              fontSize: 12,
            ),
          ),
          TextButton.icon(
            onPressed: _loadParentDepartments,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ],
    );
  }

  Widget _buildDepartmentTypeDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedDepartmentType,
      isExpanded: true,
      decoration: _inputDecoration(
        'Select department type',
      ),
      items: _departmentTypes.map((type) {
        return DropdownMenuItem<String>(
          value: type,
          child: Text(
            type,
            style: const TextStyle(fontSize: 14),
          ),
        );
      }).toList(),
      onChanged: _isSaving
          ? null
          : (value) {
              setState(() {
                _selectedDepartmentType = value;
              });
            },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Department type is required';
        }
        return null;
      },
    );
  }

  Widget _buildFieldPair({
    required Widget first,
    required Widget second,
    required bool wide,
  }) {
    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          first,
          const SizedBox(height: 20),
          second,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: first),
        const SizedBox(width: 20),
        Expanded(child: second),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Department' : 'Add Department Form',
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: 750,
              ),
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 560;

                    return Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: Text(
                            _isEditing
                                ? 'Edit Department Form'
                                : 'Add Department Form',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildTextField(
                          label: 'Department Code *',
                          hint: 'Enter department code',
                          controller: _codeController,
                          fieldName: 'Department code',
                        ),
                        const SizedBox(height: 20),
                        _buildFieldPair(
                          wide: wide,
                          first: _buildTextField(
                            label: 'Department Name *',
                            hint: 'Enter department name',
                            controller: _nameController,
                            fieldName: 'Department name',
                          ),
                          second: _buildTextField(
                            label: 'Department Short Name *',
                            hint: 'Enter short name',
                            controller: _shortNameController,
                            fieldName: 'Department short name',
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildFieldPair(
                          wide: wide,
                          first: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Parent Department'),
                              const SizedBox(height: 8),
                              _buildParentDropdown(),
                            ],
                          ),
                          second: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Department Type *'),
                              const SizedBox(height: 8),
                              _buildDepartmentTypeDropdown(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        Wrap(
                          spacing: 20,
                          runSpacing: 12,
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment:
                              WrapCrossAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Checkbox(
                                  value: _allowAssetAssignment,
                                  activeColor: primaryColor,
                                  onChanged: _isSaving
                                      ? null
                                      : (value) {
                                          setState(() {
                                            _allowAssetAssignment =
                                                value ?? true;
                                          });
                                        },
                                ),
                                const Text(
                                  'Allow Assignment',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Status',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Switch.adaptive(
                                  value: _isActive,
                                  activeTrackColor: primaryColor,
                                  onChanged: _isSaving
                                      ? null
                                      : (value) {
                                          setState(() {
                                            _isActive = value;
                                          });
                                        },
                                ),
                                Text(
                                  _isActive ? 'Active' : 'Inactive',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        Center(
                          child: Wrap(
                            spacing: 16,
                            runSpacing: 12,
                            alignment: WrapAlignment.center,
                            children: [
                              SizedBox(
                                width: 130,
                                height: 46,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(255, 114, 222, 37),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: _isSaving
                                      ? null
                                      : _saveDepartment,
                                  child: _isSaving
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child:
                                              CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          _isEditing ? 'Update' : 'Save',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                              SizedBox(
                                width: 130,
                                height: 46,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor:
                                        const Color(0xFF64748B),
                                    side: const BorderSide(
                                      color: borderColor,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: _isSaving ? null : _clearForm,
                                  child: const Text(
                                    'Clear',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
