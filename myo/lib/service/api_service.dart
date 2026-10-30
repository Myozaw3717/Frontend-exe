import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:myo/config/api_config.dart';
import 'package:myo/model/country_model.dart';
import 'package:myo/model/create_branch_model.dart';
import 'package:myo/model/create_custodian_model.dart';
import 'package:myo/model/create_department_model.dart';
import 'package:myo/model/get_branch_model.dart';
import 'package:myo/model/get_custodian_model.dart';
import 'package:myo/model/get_department_model.dart';



class ApiService {
  // API endpoints
  String get _branchesUrl =>
      '${AppConfig.baseUrl}/api/v1/intern/branches/';

  String get _countriesUrl =>
      '${AppConfig.baseUrl}/api/v1/intern/countries/';

  
  List<dynamic> _extractList(dynamic decoded) {
    if (decoded is List) {
      return decoded;
    }

    if (decoded is Map<String, dynamic>) {
      for (final key in ['result', 'results', 'data']) {
        if (decoded[key] is List) {
          return decoded[key] as List<dynamic>;
        }
      }
    }

    throw Exception(
      'Unexpected API response format: ${jsonEncode(decoded)}',
    );
  }

  // GET: Fetch all branches
  Future<List<Branch>> fetchBranches() async {
    final url = Uri.parse(_branchesUrl);

    final response = await http.get(
      url,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final data = _extractList(decoded);

      return data
          .map(
            (item) => Branch.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    }

    throw Exception(
      'Failed to load branches: '
      '${response.statusCode} ${response.body}',
    );
  }

  // GET: Fetch all countries for the dropdown
  Future<List<Country>> fetchCountries() async {
    final url = Uri.parse(_countriesUrl);

    final response = await http.get(
      url,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final data = _extractList(decoded);

      return data
          .map(
            (item) => Country.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    }

    throw Exception(
      'Failed to load countries: '
      '${response.statusCode} ${response.body}',
    );
  }

  // POST: Create a branch
  Future<void> createBranch(CreateBranch branch) async {
    final url = Uri.parse(_branchesUrl);
    final body = jsonEncode(branch.toJson());

    print('Creating branch: $url');
    print('Request body: $body');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: body,
    );

    print('Create branch status: ${response.statusCode}');
    print('Create branch response: ${response.body}');

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      return;
    }

    throw Exception(
      'Failed to create branch: '
      '${response.statusCode} ${response.body}',
    );
  }

  // DELETE: Delete a branch by its primary key
  Future<void> deleteBranch(int branchId) async {
    final url = Uri.parse('$_branchesUrl$branchId/');

    final response = await http.delete(
      url,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200 ||
        response.statusCode == 202 ||
        response.statusCode == 204) {
      return;
    }

    throw Exception(
      'Failed to delete branch: '
      '${response.statusCode} ${response.body}',
    );
  }
  // Fetch all departments
  Future<List<Department>> fetchDepartments() async {
    final url = Uri.parse(
      '${AppConfig.baseUrl}/api/v1/intern/departments/',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      // Support either a direct list or a wrapped response.
      dynamic data = decoded;

      if (decoded is Map<String, dynamic>) {
        data = decoded['result'] ??
            decoded['results'] ??
            decoded['data'];
      }

      if (data is! List) {
        throw Exception(
          'Invalid department response format: ${response.body}',
        );
      }

      return data
          .map(
            (item) => Department.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    }

    throw Exception(
      'Failed to fetch departments: '
      '${response.statusCode} ${response.body}',
    );
  }

  // Create a new department
  Future<Department> createDepartment(
    CreateDepartment department,
  ) async {
    final url = Uri.parse(
      '${AppConfig.baseUrl}/api/v1/intern/departments/',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(department.toJson()),
    );

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      final decoded = jsonDecode(response.body);

      return Department.fromJson(
        Map<String, dynamic>.from(decoded as Map),
      );
    }

    throw Exception(
      'Failed to create department: '
      '${response.statusCode} ${response.body}',
    );
  }

  // Update an existing department
  Future<Department> updateDepartment(
    int departmentId,
    CreateDepartment department,
  ) async {
    final url = Uri.parse(
      '${AppConfig.baseUrl}/api/v1/intern/departments/$departmentId/',
    );

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(department.toJson()),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      return Department.fromJson(
        Map<String, dynamic>.from(decoded as Map),
      );
    }

    throw Exception(
      'Failed to update department: '
      '${response.statusCode} ${response.body}',
    );
  }

  // Delete a department
  Future<void> deleteDepartment(int departmentId) async {
    final url = Uri.parse(
      '${AppConfig.baseUrl}/api/v1/intern/departments/$departmentId/',
    );

    final response = await http.delete(url);

    if (response.statusCode == 200 ||
        response.statusCode == 202 ||
        response.statusCode == 204) {
      return;
    }

    throw Exception(
      'Failed to delete department: '
      '${response.statusCode} ${response.body}',
    );
  }

  String get _custodianUrl =>
      '${AppConfig.baseUrl.replaceFirst(RegExp(r'/+$'), '')}/api/v1/intern/custodians/';

  // Extract list from Django API response
  List<dynamic> _extractCustodianList(dynamic decoded) {
    if (decoded is List) {
      return decoded;
    }

    if (decoded is Map<String, dynamic>) {
      for (final key in ['result', 'results', 'data']) {
        if (decoded[key] is List) {
          return decoded[key] as List<dynamic>;
        }
      }
    }

    throw Exception('Invalid custodians API response format');
  }

  // 1. GET: Fetch all custodians
  Future<List<Custodian>> fetchCustodians() async {
    final response = await http.get(
      Uri.parse(_custodianUrl),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return _extractCustodianList(decoded)
          .map((json) => Custodian.fromJson(
                Map<String, dynamic>.from(json as Map),
              ))
          .toList();
    }
    throw Exception(
      'Failed to fetch custodians: '
      '${response.statusCode} ${response.body}',
    );
  }

  // 2. POST: Create a custodian
  Future<Custodian> createCustodian(
    CreateCustodian custodian,
  ) async {
    final response = await http.post(
      Uri.parse(_custodianUrl),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(custodian.toJson()),
    );

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      final decoded = jsonDecode(response.body);

      // Supports a direct object or an object inside "result".
      final data = decoded is Map<String, dynamic> &&
              decoded['result'] is Map
          ? decoded['result'] as Map
          : decoded;

      return Custodian.fromJson(
        Map<String, dynamic>.from(data as Map),
      );
    }

    throw Exception(
      'Failed to create custodian: '
      '${response.statusCode} ${response.body}',
    );
  }

  // 3. PUT: Update an existing custodian
  Future<Custodian> updateCustodian(
    int custodianId,
    CreateCustodian custodian,
  ) async {
    final response = await http.put(
      Uri.parse('$_custodianUrl$custodianId/'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(custodian.toJson()),
    );

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      final decoded = jsonDecode(response.body);

      final data = decoded is Map<String, dynamic> &&
              decoded['result'] is Map
          ? decoded['result'] as Map
          : decoded;

      return Custodian.fromJson(
        Map<String, dynamic>.from(data as Map),
      );
    }

    throw Exception(
      'Failed to update custodian: '
      '${response.statusCode} ${response.body}',
    );
  }

  // 4. DELETE: Delete a custodian
  Future<void> deleteCustodian(int custodianId) async {
    final response = await http.delete(
      Uri.parse('$_custodianUrl$custodianId/'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200 ||
        response.statusCode == 202 ||
        response.statusCode == 204) {
      return;
    }

    throw Exception(
      'Failed to delete custodian: '
      '${response.statusCode} ${response.body}',
    );
  }


}