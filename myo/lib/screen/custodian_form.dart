import 'package:flutter/material.dart';
import 'package:myo/model/create_custodian_model.dart';
import 'package:myo/model/get_custodian_model.dart';
import 'package:myo/model/get_department_model.dart';
import 'package:myo/service/api_service.dart';


class CustodianForm extends StatefulWidget {
  final Custodian? custodian;

  const CustodianForm({
    super.key,
    this.custodian,
  });

  @override
  State<CustodianForm> createState() => _CustodianFormState();
}

class _CustodianFormState extends State<CustodianForm> {
  final ApiService _apiService = ApiService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  static const Color primaryColor = Color.fromARGB(255, 50, 27, 184);
  static const Color backgroundColor = Color(0xFFF4F6F9);
  static const Color textColor = Color(0xFF334155);
  static const Color borderColor = Color(0xFFCBD5E1);

  final TextEditingController _codeController =
      TextEditingController();
  final TextEditingController _nameController =
      TextEditingController();
  final TextEditingController _phoneController =
      TextEditingController();
  final TextEditingController _emailController =
      TextEditingController();

  final List<String> _custodianTypes = [
    'SUPPLIER',
    'EMPLOYEE',
    'EXTERNAL',
  ];

  List<dynamic> _branches = [];
  List<Department> _departments = [];

  int? _selectedBranchId;
  int? _selectedDepartmentId;

  String _selectedCustodianType = 'SUPPLIER';

  bool _canHoldAssets = false;
  bool _isActive = true;
  bool _isLoadingOptions = true;
  bool _isSaving = false;
  String? _optionsError;

  bool get _isEditing => widget.custodian != null;

  @override
  void initState() {
    super.initState();

    final custodian = widget.custodian;

    _codeController.text = custodian?.custodianCode ?? '';
    _nameController.text = custodian?.custodianName ?? '';
    _phoneController.text = custodian?.phone ?? '';
    _emailController.text = custodian?.email ?? '';

    _selectedCustodianType =
        custodian?.custodianType ?? 'SUPPLIER';

    _selectedBranchId = custodian?.branchId;
    _selectedDepartmentId = custodian?.deptId;

    _canHoldAssets = custodian?.canHoldAssets ?? false;
    _isActive = custodian?.isActive ?? true;

    _loadOptions();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    try {
      // These methods must exist in your ApiService.
      final results = await Future.wait([
        _apiService.fetchBranches(),
        _apiService.fetchDepartments(),
      ]);

      if (!mounted) return;

      setState(() {
        _branches = results[0] as List;
        _departments = results[1] as List<Department>;
        _isLoadingOptions = false;

        // Clear selections that no longer exist.
        if (_selectedBranchId != null &&
            !_branches.any(
              (branch) =>
                  branch.branchId == _selectedBranchId,
            )) {
          _selectedBranchId = null;
        }

        if (_selectedDepartmentId != null &&
            !_departments.any(
              (department) =>
                  department.departmentId ==
                  _selectedDepartmentId,
            )) {
          _selectedDepartmentId = null;
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingOptions = false;
        _optionsError = e.toString();
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

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }

    return null;
  }

  Future<void> _saveCustodian() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final custodian = CreateCustodian(
        custodianCode:
            _codeController.text.trim().isEmpty
                ? null
                : _codeController.text.trim(),
        custodianName: _nameController.text.trim(),
        custodianType: _selectedCustodianType,
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        canHoldAssets: _canHoldAssets,
        isActive: _isActive,
        branchId: _selectedBranchId,
        deptId: _selectedDepartmentId,
      );

      if (_isEditing) {
        await _apiService.updateCustodian(
          widget.custodian!.custodianId,
          custodian,
        );
      } else {
        await _apiService.createCustodian(custodian);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Custodian updated successfully.'
                : 'Custodian created successfully.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save custodian: $e'),
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
    _phoneController.clear();
    _emailController.clear();

    setState(() {
      _selectedBranchId = null;
      _selectedDepartmentId = null;
      _selectedCustodianType = 'SUPPLIER';
      _canHoldAssets = false;
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

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
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
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: _inputDecoration(hint),
          validator: validator ??
              (value) => _requiredValidator(value, fieldName),
        ),
      ],
    );
  }
  Widget _buildTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCustodianType,
      isExpanded: true,
      decoration: _inputDecoration('Select custodian type'),
      items: _custodianTypes.map((type) {
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
              if (value == null) return;
              setState(() {
                _selectedCustodianType = value;
              });
            },
    );
  }

  Widget _buildBranchDropdown() {
    return DropdownButtonFormField<int?>(
      value: _selectedBranchId,
      isExpanded: true,
      decoration: _inputDecoration('Select branch (optional)'),
      items: [
        const DropdownMenuItem<int?>(
          value: null,
          child: Text('No branch'),
        ),
        ..._branches.map((branch) {
          return DropdownMenuItem<int?>(
            value: branch.branchId as int,
            child: Text(
              '${branch.branchName}',
              overflow: TextOverflow.ellipsis,
            ),
          );
        }),
      ],
      onChanged: _isSaving
          ? null
          : (value) {
              setState(() {
                _selectedBranchId = value;
              });
            },
    );
  }

  Widget _buildDepartmentDropdown() {
    return DropdownButtonFormField<int?>(
      value: _selectedDepartmentId,
      isExpanded: true,
      decoration: _inputDecoration('Select department (optional)'),
      items: [
        const DropdownMenuItem<int?>(
          value: null,
          child: Text('No department'),
        ),
        ..._departments.map((department) {
          return DropdownMenuItem<int?>(
            value: department.departmentId,
            child: Text(
              department.deptName,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }),
      ],
      onChanged: _isSaving
          ? null
          : (value) {
              setState(() {
                _selectedDepartmentId = value;
              });
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
          _isEditing ? 'Edit Custodian' : 'Add Custodian Form',
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
              constraints: const BoxConstraints(maxWidth: 750),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: Text(
                            _isEditing
                                ? 'Edit Custodian Form'
                                : 'Add Custodian Form',
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
                          label: 'Custodian Code',
                          hint: 'Enter custodian code (optional)',
                          controller: _codeController,
                          fieldName: 'Custodian code',
                          validator: (_) => null,
                        ),

                        const SizedBox(height: 20),

                        _buildTextField(
                          label: 'Custodian Name *',
                          hint: 'Enter custodian name',
                          controller: _nameController,
                          fieldName: 'Custodian name',
                        ),

                        const SizedBox(height: 20),

                        _buildFieldPair(
                          wide: wide,
                          first: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Custodian Type *'),
                              const SizedBox(height: 8),
                              _buildTypeDropdown(),
                            ],
                          ),
                          second: _buildTextField(
                            label: 'Phone',
                            hint: 'Enter phone number (optional)',
                            controller: _phoneController,
                            fieldName: 'Phone',
                            validator: (_) => null,
                            keyboardType: TextInputType.phone,
                          ),
                        ),

                        const SizedBox(height: 20),

                        _buildTextField(
                          label: 'Email',
                          hint: 'Enter email address (optional)',
                          controller: _emailController,
                          fieldName: 'Email',
                          validator: _emailValidator,
                          keyboardType: TextInputType.emailAddress,
                        ),

                        const SizedBox(height: 20),

                    if (_isLoadingOptions)
                          const LinearProgressIndicator(
                            color: primaryColor,
                          )
                        else if (_optionsError != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Could not load branch/department options.',
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _loadOptions,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                              ),
                            ],
                          )
                        else
                          _buildFieldPair(
                            wide: wide,
                            first: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Branch'),
                                const SizedBox(height: 8),
                                _buildBranchDropdown(),
                              ],
                            ),
                            second: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Department'),
                                const SizedBox(height: 8),
                                _buildDepartmentDropdown(),
                              ],
                            ),
                          ),

                        const SizedBox(height: 28),

                        Wrap(
                          spacing: 20,
                          runSpacing: 12,
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Checkbox(
                                  value: _canHoldAssets,
                                  activeColor: primaryColor,
                                  onChanged: _isSaving
                                      ? null
                                      : (value) {
                                          setState(() {
                                            _canHoldAssets =
                                                value ?? false;
                                          });
                                        },
                                ),
                                const Text(
                                  'Can Hold Assets',
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
                                Switch(
                                  value: _isActive,
                                  activeThumbColor: const Color.fromARGB(255, 16, 216, 70),
                                  activeTrackColor: const Color.fromARGB(255, 184, 168, 27),
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
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: _isActive
                                        ? const Color.fromARGB(255, 22, 190, 58)
                                        : const Color.fromARGB(255, 245, 242, 242),
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
                                    backgroundColor: const Color.fromARGB(255, 13, 160, 16),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: _isSaving
                                      ? null
                                      : _saveCustodian,
                                  child: _isSaving
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
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