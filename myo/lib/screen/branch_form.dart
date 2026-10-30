import 'package:flutter/material.dart';
import 'package:myo/model/country_model.dart';
import 'package:myo/model/create_branch_model.dart';
import 'package:myo/service/api_service.dart';


class BranchForm extends StatefulWidget {
  const BranchForm({super.key});

  @override
  State<BranchForm> createState() => _BranchFormState();
}

class _BranchFormState extends State<BranchForm> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  final _branchCodeController = TextEditingController();
  final _branchNameController = TextEditingController();
  final _regionController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  final Color purple = const Color.fromARGB(255, 4, 207, 116);

  List<Country> _countries = [];
  int? _selectedCountryId;

  bool _isActive = true;
  bool _isLoadingCountries = true;
  bool _isSaving = false;
  String? _countryError;

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    try {
      final countries = await _apiService.fetchCountries();

      if (!mounted) return;

      setState(() {
        _countries = countries;
        _isLoadingCountries = false;
        _countryError =
            countries.isEmpty ? 'No countries found.' : null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingCountries = false;
        _countryError = e.toString();
      });
    }
  }

  Future<void> _saveBranch() async {
    if (!_formKey.currentState!.validate()) return;

    final postalText = _postalCodeController.text.trim();
    final postalCode =
        postalText.isEmpty ? null : int.tryParse(postalText);

    if (postalText.isNotEmpty && postalCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Postal code must be a whole number.'),
        ),
      );
      return;
    }

    final branch = CreateBranch(
      branchCode: _branchCodeController.text.trim().isEmpty
          ? null
          : _branchCodeController.text.trim(),
      branchName: _branchNameController.text.trim(),
      country: _selectedCountryId,
      region: _regionController.text.trim(),
      city: _cityController.text.trim(),
      address: _addressController.text.trim(),
      postalCode: postalCode,
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      isActive: _isActive,
    );

    setState(() => _isSaving = true);

    try {
      await _apiService.createBranch(branch);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Branch created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      _clearForm();

    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save branch: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();

    _branchCodeController.clear();
    _branchNameController.clear();
    _regionController.clear();
    _cityController.clear();
    _addressController.clear();
    _postalCodeController.clear();
    _phoneController.clear();
    _emailController.clear();

    setState(() {
      _selectedCountryId = null;
      _isActive = true;
    });
  }
  Widget _fieldLabel(String label, {bool requiredField = false}) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF252525),
        ),
        children: [
          TextSpan(text: label),
          if (requiredField)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Colors.red),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool requiredField = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label, requiredField: requiredField),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator ??
              (requiredField
                  ? (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return '$label is required';
                      }
                      return null;
                    }
                  : null),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFF888888),
              fontSize: 15,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 17,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(
                color: Color(0xFFBDBDBD),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(
                color: Color(0xFFBDBDBD),
                width: 1.3,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: BorderSide(
                color: purple,
                width: 1.7,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
  Widget _countryField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Country', requiredField: true),
        const SizedBox(height: 10),
        if (_isLoadingCountries)
          const SizedBox(
            height: 58,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        else if (_countryError != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red.shade200),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Could not load countries: $_countryError',
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
                TextButton.icon(
                  onPressed: _loadCountries,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          )
        else
          DropdownButtonFormField<int>(
            value: _selectedCountryId,
            isExpanded: true,
            hint: const Text(
              'Select country',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF777777),
              ),
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(
                  color: Color(0xFFBDBDBD),
                  width: 1.3,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: BorderSide(
                  color: purple,
                  width: 1.7,
                ),
              ),
            ),
            items: _countries.map((country) {
              return DropdownMenuItem<int>(
                value: country.countryId,
                child: Text(country.countryName),
              );
            }).toList(),
            validator: (value) =>
                value == null ? 'Please select a country' : null,
            onChanged: (value) {
              setState(() {
                _selectedCountryId = value;
              });
            },
          ),
      ],
    );
  }

  Widget _formRow(
    List<Widget> fields, {
    List<int>? flexes,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            children: [
              for (int i = 0; i < fields.length; i++) ...[
                fields[i],
                if (i != fields.length - 1)
                  const SizedBox(height: 20),
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < fields.length; i++) ...[
              Expanded(
                flex: flexes != null ? flexes[i] : 1,
                child: fields[i],
              ),
              if (i != fields.length - 1)
                const SizedBox(width: 28),
            ],
          ],
        );
      },
    );
  }
  @override
  void dispose() {
    _branchCodeController.dispose();
    _branchNameController.dispose();
    _regionController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _postalCodeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F8),
        foregroundColor: const Color(0xFF252525),
        elevation: 0,
        title: const Text(
          'Branch List',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1050),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 25,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        'Add Branch Form',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF171717),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 30),

                    _formRow([
                      _buildTextField(
                        label: 'Branch Code',
                        hint: 'Enter branch code',
                        controller: _branchCodeController,
                      ),
                      _buildTextField(
                        label: 'Branch Name',
                        hint: 'Enter branch name',
                        controller: _branchNameController,
                        requiredField: true,
                      ),
                    ]),
                    const SizedBox(height: 24),

                    _formRow([
                      _countryField(),
                      _buildTextField(
                        label: 'Region/State',
                        hint: 'Enter Region/State',
                        controller: _regionController,
                      ),
                      _buildTextField(
                        label: 'City / Township',
                        hint: 'Enter city / Township',
                        controller: _cityController,
                      ),
                    ]),
                    const SizedBox(height: 22),
                    _formRow(
                      [
                        _buildTextField(
                          label: 'Address',
                          hint: 'Enter address',
                          controller: _addressController,
                          maxLines: 2,
                        ),
                        _buildTextField(
                          label: 'Postal Code',
                          hint: 'Enter postal code',
                          controller: _postalCodeController,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.isEmpty) return null;
                            if (int.tryParse(text) == null) {
                              return 'Enter a valid numeric postal code';
                            }
                            return null;
                          },
                        ),
                      ],
                      flexes: [2, 1],
                    ),
                    const SizedBox(height: 22),

                    _formRow([
                      _buildTextField(
                        label: 'Phone Number',
                        hint: 'Enter phone number',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                      ),
                      _buildTextField(
                        label: 'Email Address',
                        hint: 'Enter branch email',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          if (email.isEmpty) return null;

                          if (!RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          ).hasMatch(email)) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                    ]),
                    const SizedBox(height: 18),

                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Status',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 18),
                        Switch(
                          value: _isActive,
                          activeThumbColor: Colors.white,
                          activeTrackColor: purple,
                          onChanged: _isSaving
                              ? null
                              : (value) {
                                  setState(() {
                                    _isActive = value;
                                  });
                                },
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: _isActive
                                ? const Color.fromARGB(255, 75, 86, 232)
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 24,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: 145,
                            height: 52,
                            child: ElevatedButton(
                              onPressed:
                                  _isSaving ? null : _saveBranch,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: purple,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    purple.withValues(alpha: 0.5),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(9),
                                ),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 21,
                                      height: 21,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Save',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                          SizedBox(
                            width: 145,
                            height: 52,
                            child: OutlinedButton(
                              onPressed:
                                  _isSaving ? null : _clearForm,
                              style: OutlinedButton.styleFrom(
                                foregroundColor:
                                    const Color(0xFF55516A),
                                side: const BorderSide(
                                  color: Color(0xFFBDBDBD),
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(9),
                                ),
                              ),
                              child: const Text(
                                'Clear',
                                style: TextStyle(fontSize: 17),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}