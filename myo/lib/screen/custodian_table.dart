
import 'package:flutter/material.dart';
import 'package:myo/model/get_branch_model.dart';
import 'package:myo/model/get_custodian_model.dart';
import 'package:myo/model/get_department_model.dart';
import 'package:myo/service/api_service.dart';
import 'package:myo/screen/custodian_form.dart';
import 'package:pluto_grid/pluto_grid.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class CustodianTable extends StatefulWidget {
  const CustodianTable({super.key});

  @override
  State<CustodianTable> createState() => _CustodianTableState();
}

class _CustodianTableState extends State<CustodianTable> {
  final ApiService _apiService = ApiService();

  late final List<PlutoColumn> columns;

  List<Custodian> custodians = [];
  List<Branch> branches = [];
  List<Department> departments = [];
  List<PlutoRow> rows = [];

  bool isLoading = true;
  String? errorMessage;

  final Set<int> _deletingIds = {};

  String _statusFilter = 'All';

  final Color blue = const Color.fromARGB(255, 78, 132, 240);
  final Color borderColor = const Color(0xFFD5DCE8);
  final Color purple = const Color(0xFF7C69EE);

  final TextEditingController _searchController =
      TextEditingController();

  List<PlutoRow> get _filteredRows {
    final query = _searchController.text.toLowerCase().trim();

    return rows.where((row) {
      final status =
          row.cells['is_active']!.value.toString();

      final matchesStatus = _statusFilter == 'All' ||
          (_statusFilter == 'Active' && status == 'Yes') ||
          (_statusFilter == 'Inactive' && status == 'No');

      final matchesSearch = query.isEmpty ||
          row.cells.entries.any((entry) {
            if (entry.key == 'action' ||
                entry.key == 'custodian_id') {
              return false;
            }

            return entry.value.value
                .toString()
                .toLowerCase()
                .contains(query);
          });

      return matchesStatus && matchesSearch;
    }).toList();
  }

  @override
  void initState() {
    super.initState();

    columns = [
      PlutoColumn(
        title: 'Code',
        field: 'custodian_code',
        type: PlutoColumnType.text(),
        width: 130,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Name',
        field: 'custodian_name',
        type: PlutoColumnType.text(),
        width: 180,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Type',
        field: 'custodian_type',
        type: PlutoColumnType.text(),
        width: 130,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Phone',
        field: 'phone',
        type: PlutoColumnType.text(),
        width: 130,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Email',
        field: 'email',
        type: PlutoColumnType.text(),
        width: 200,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Branch Name',
        field: 'branchname',
        type: PlutoColumnType.text(),
        width: 160,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Department Name',
        field: 'dept',
        type: PlutoColumnType.text(),
        width: 170,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Can Hold Assets',
        field: 'can_hold_assets',
        type: PlutoColumnType.text(),
        width: 150,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Status',
        field: 'is_active',
        type: PlutoColumnType.text(),
        width: 155,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final value =
              rendererContext.cell.value.toString();

          final bool isActive =
              value.toLowerCase() == 'true' ||
              value == '1' ||
              value == 'Yes';

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                value: isActive,
                activeThumbColor: const Color.fromARGB(255, 159, 236, 27),
                activeTrackColor: purple,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.grey.shade400,
                onChanged: null,
              ),
              const SizedBox(width: 5),
              Text(
                isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isActive
                      ? const Color.fromARGB(255, 44, 134, 39)
                      : Colors.grey,
                ),
              ),
            ],
          );
        },
      ),
      PlutoColumn(
        title: 'Action',
        field: 'action',
        type: PlutoColumnType.text(),
        width: 90,
        enableEditingMode: false,
        enableSorting: false,
        enableFilterMenuItem: false,
        renderer: (rendererContext) {
          final id = int.tryParse(
            rendererContext.row.cells['custodian_id']!
                .value
                .toString(),
          );

          final isDeleting =
              id != null && _deletingIds.contains(id);

          return IconButton(
            tooltip: 'Delete custodian',
            onPressed: id == null || isDeleting
                ? null
                : () => _confirmDelete(id),
            icon: isDeleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
          );
        },
      ),
    ];

    loadCustodians();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> loadCustodians() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final results = await Future.wait<dynamic>([
        _apiService.fetchCustodians(),
        _apiService.fetchBranches(),
        _apiService.fetchDepartments(),
      ]);

      final loadedCustodians =
          results[0] as List<Custodian>;

      final loadedBranches = results[1] as List<Branch>;

      final loadedDepartments =
          results[2] as List<Department>;

      final Map<int, String> branchNames = {
        for (final branch in loadedBranches)
          branch.branchId: branch.branchName,
      };

      final Map<int, String> departmentNames = {
        for (final department in loadedDepartments)
          department.departmentId: department.deptName,
      };

      final loadedRows = loadedCustodians.map((custodian) {
        return PlutoRow(
          cells: {
            'custodian_id': PlutoCell(
              value: custodian.custodianId,
            ),
            'custodian_code': PlutoCell(
              value: custodian.custodianCode ?? '-',
            ),
            'custodian_name': PlutoCell(
              value: custodian.custodianName,
            ),
            'custodian_type': PlutoCell(
              value: custodian.custodianType,
            ),
            'phone': PlutoCell(
              value: custodian.phone ?? '-',
            ),
            'email': PlutoCell(
              value: custodian.email ?? '-',
            ),
            'branchname': PlutoCell(
              value: branchNames[custodian.branchId] ?? '-',
            ),
            'dept': PlutoCell(
              value: departmentNames[custodian.deptId] ?? '-',
            ),
            'can_hold_assets': PlutoCell(
              value: custodian.canHoldAssets ? 'Yes' : 'No',
            ),
            'is_active': PlutoCell(
              value: custodian.isActive ? 'Yes' : 'No',
            ),
            'action': PlutoCell(value: ''),
          },
        );
      }).toList();

      if (!mounted) return;

      setState(() {
        custodians = loadedCustodians;
        branches = loadedBranches;
        departments = loadedDepartments;
        rows = loadedRows;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  Future<void> _confirmDelete(int custodianId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Custodian'),
          content: Text(
            'Are you sure you want to delete custodian ID '
            '$custodianId?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _deleteCustodian(custodianId);
    }
  }

  Future<void> _deleteCustodian(int custodianId) async {
    setState(() {
      _deletingIds.add(custodianId);
    });

    try {
      await _apiService.deleteCustodian(custodianId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Custodian deleted successfully.'),
          backgroundColor: Colors.green,
        ),
      );

      await loadCustodians();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete custodian: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _deletingIds.remove(custodianId);
        });
      }
    }
  }

  Future<void> _addCustodian() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const CustodianForm(),
      ),
    );

    if (!mounted) return;

    // Refresh after returning from the form.
    if (result == true) {
      await loadCustodians();
    }
  }

  Future<void> _downloadPdf() async {
    if (_filteredRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('There is no data to export.'),
        ),
      );
      return;
    }

    try {
      final pdf = pw.Document();

      final headers = [
        'Code',
        'Name',
        'Type',
        'Phone',
        'Email',
        'Branch',
        'Department',
        'Can Hold Assets',
        'Status',
      ];

      final data = _filteredRows.map((row) {
        return [
          row.cells['custodian_code']!.value.toString(),
          row.cells['custodian_name']!.value.toString(),
          row.cells['custodian_type']!.value.toString(),
          row.cells['phone']!.value.toString(),
          row.cells['email']!.value.toString(),
          row.cells['branchname']!.value.toString(),
          row.cells['dept']!.value.toString(),
          row.cells['can_hold_assets']!.value.toString(),
          row.cells['is_active']!.value.toString(),
        ];
      }).toList();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(24),
          build: (context) => [
            pw.Text(
              'Custodian List',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: data,
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.indigo,
              ),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.centerLeft,
              border: pw.TableBorder.all(
                color: PdfColors.grey400,
                width: 0.5,
              ),
            ),
          ],
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: 'custodian_list.pdf',
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: const Text('Custodian List'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: isLoading ? null : loadCustodians,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 12),
              const Text(
                'Could not load custodians',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SelectableText(errorMessage!),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: loadCustodians,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 22,
            runSpacing: 14,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Status',
                    style: TextStyle(
                      color: Color(0xFF30415F),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 20),
                  SizedBox(
                    width: 180,
                    child: DropdownButtonFormField<String>(
                      initialValue: _statusFilter,
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding:
                            const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(7),
                          borderSide:
                              BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(7),
                          borderSide:
                              BorderSide(color: borderColor),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'All',
                          child: Text('All'),
                        ),
                        DropdownMenuItem(
                          value: 'Active',
                          child: Text('Active'),
                        ),
                        DropdownMenuItem(
                          value: 'Inactive',
                          child: Text('Inactive'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;

                        setState(() {
                          _statusFilter = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(
                width: 325,
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF75829B),
                      fontSize: 14,
                    ),
                    suffixIcon: IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(
                        Icons.clear,
                        color: Color(0xFF63728E),
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(7),
                      borderSide:
                          BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(7),
                      borderSide:
                          BorderSide(color: borderColor),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                onPressed: _addCustodian,
                icon: const Icon(Icons.add, size: 21),
                label: const Text('Add New'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 17,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  elevation: 0,
                ),
              ),
              OutlinedButton.icon(
                onPressed: _downloadPdf,
                icon: const Icon(Icons.download_outlined),
                label: const Text('Download PDF'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: blue,
                  side: BorderSide(color: borderColor),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Expanded(
            child: rows.isEmpty
                ? const Center(
                    child: Text('No custodians found.'),
                  )
                : _filteredRows.isEmpty
                    ? const Center(
                        child: Text(
                          'No matching custodians found.',
                        ),
                      )
                    : PlutoGrid(
                        columns: columns,
                        rows: _filteredRows,
                        configuration:
                            const PlutoGridConfiguration(),
                      ),
          ),
        ],
      ),
    );
  }
}
