
import 'package:flutter/material.dart';
import 'package:myo/model/get_department_model.dart';
import 'package:myo/screen/department_form.dart';
import 'package:myo/service/api_service.dart';
import 'package:pluto_grid/pluto_grid.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class DepartmentTable extends StatefulWidget {
  const DepartmentTable({super.key});

  @override
  State<DepartmentTable> createState() => _DepartmentTableState();
}

class _DepartmentTableState extends State<DepartmentTable> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController =
      TextEditingController();

  late final List<PlutoColumn> columns;

  List<Department> departments = [];
  List<PlutoRow> rows = [];

  bool isLoading = true;
  bool isExportingPdf = false;
  String? errorMessage;

  final Set<int> _deletingIds = {};

  String _statusFilter = 'All';

  final Color blue = const Color.fromARGB(255, 21, 85, 213);
  final Color borderColor = const Color(0xFFD5DCE8);
  final Color purple = const Color(0xFF7C69EE);

  List<PlutoRow> get _filteredRows {
    final query = _searchController.text.toLowerCase().trim();

    return rows.where((row) {
      final status = row.cells['is_active']!.value.toString();

      final matchesStatus = _statusFilter == 'All' ||
          (_statusFilter == 'Active' && status == 'Yes') ||
          (_statusFilter == 'Inactive' && status == 'No');

      final matchesSearch = query.isEmpty ||
          row.cells.entries.any((entry) {
            if (entry.key == 'action' ||
                entry.key == 'department_id') {
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
        title: 'Dept Code',
        field: 'dept_code',
        type: PlutoColumnType.text(),
        width: 130,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Department Name',
        field: 'dept_name',
        type: PlutoColumnType.text(),
        width: 180,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Short Name',
        field: 'dept_short_name',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Department Type',
        field: 'dept_type',
        type: PlutoColumnType.text(),
        width: 180,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Parent Department',
        field: 'parent_dept',
        type: PlutoColumnType.text(),
        width: 180,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Allow Assignment',
        field: 'allow_assignment',
        type: PlutoColumnType.text(),
        width: 155,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Status',
        field: 'is_active',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        width: 155,
        renderer: (rendererContext) {
          final value =
              rendererContext.cell.value.toString();

          final isActive = value.toLowerCase() == 'true' ||
              value == '1' ||
              value == 'Yes';

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                value: isActive,
                activeThumbColor: Colors.white,
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
                      ? const Color(0xFF278653)
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
        width: 100,
        enableEditingMode: false,
        enableSorting: false,
        enableFilterMenuItem: false,
        renderer: (rendererContext) {
          final id = int.tryParse(
            rendererContext.row.cells['department_id']!
                .value
                .toString(),
          );

          final isDeleting =
              id != null && _deletingIds.contains(id);

          return IconButton(
            tooltip: 'Delete department',
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

    loadDepartments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> loadDepartments() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final loadedDepartments =
          await _apiService.fetchDepartments();

      final Map<int, String> departmentNames = {
        for (final department in loadedDepartments)
          department.departmentId: department.deptName,
      };

      final loadedRows = loadedDepartments.map((department) {
        final parentId = department.parentDeptId;

        final parentName = parentId == null
            ? '-'
            : departmentNames[parentId] ?? 'Unknown';

        return PlutoRow(
          cells: {
            'department_id': PlutoCell(
              value: department.departmentId,
            ),
            'dept_code': PlutoCell(
              value: department.deptCode,
            ),
            'dept_name': PlutoCell(
              value: department.deptName,
            ),
            'dept_short_name': PlutoCell(
              value: department.deptShortName,
            ),
            'dept_type': PlutoCell(
              value: department.deptType,
            ),
            'parent_dept': PlutoCell(
              value: parentName,
            ),
            'allow_assignment': PlutoCell(
              value: department.allowAssignment ? 'Yes' : 'No',
            ),
            'is_active': PlutoCell(
              value: department.isActive ? 'Yes' : 'No',
            ),
            'action': PlutoCell(value: ''),
          },
        );
      }).toList();

      if (!mounted) return;

      setState(() {
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

  Future<void> _confirmDelete(int departmentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Department'),
          content: Text(
            'Are you sure you want to delete department ID '
            '$departmentId?',
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
      await _deleteDepartment(departmentId);
    }
  }

  Future<void> _deleteDepartment(int departmentId) async {
    setState(() {
      _deletingIds.add(departmentId);
    });

    try {
      await _apiService.deleteDepartment(departmentId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Department deleted successfully.'),
          backgroundColor: Colors.green,
        ),
      );

      await loadDepartments();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete department: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _deletingIds.remove(departmentId);
        });
      }
    }
  }

  Future<void> _addDepartment() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DepartmentForm(),
      ),
    );

    if (!mounted) return;
    await loadDepartments();
  }

  Future<void> _editDepartment(Department department) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DepartmentForm(
          department: department,
        ),
      ),
    );

    if (!mounted) return;
    await loadDepartments();
  }

  Future<void> _downloadPdf() async {
    final filteredRows = _filteredRows;

    if (filteredRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('There is no data to export.'),
        ),
      );
      return;
    }

    if (isExportingPdf) return;

    setState(() {
      isExportingPdf = true;
    });

    try {
      final pdf = pw.Document();

      final headers = [
        'Dept Code',
        'Department Name',
        'Short Name',
        'Department Type',
        'Parent Department',
        'Allow Assignment',
        'Status',
      ];

      final data = filteredRows.map((row) {
        return [
          row.cells['dept_code']!.value.toString(),
          row.cells['dept_name']!.value.toString(),
          row.cells['dept_short_name']!.value.toString(),
          row.cells['dept_type']!.value.toString(),
          row.cells['parent_dept']!.value.toString(),
          row.cells['allow_assignment']!.value.toString(),
          row.cells['is_active']!.value.toString(),
        ];
      }).toList();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(24),
          build: (context) => [
            pw.Text(
              'Department List',
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
        name: 'department_list.pdf',
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isExportingPdf = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: const Text('Department List'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: isLoading ? null : loadDepartments,
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
                'Could not load departments',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SelectableText(errorMessage!),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: loadDepartments,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    final filteredRows = _filteredRows;

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
                    hintText: 'Search department...',
                    suffixIcon: IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.clear),
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
                onPressed: _addDepartment,
                icon: const Icon(Icons.add, size: 21),
                label: const Text('Add New'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 17,
                    vertical: 14,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed:
                    isExportingPdf ? null : _downloadPdf,
                icon: isExportingPdf
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.download_outlined),
                label: const Text('Download PDF'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: blue,
                  side: BorderSide(color: borderColor),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Expanded(
            child: rows.isEmpty
                ? const Center(
                    child: Text('No departments found.'),
                  )
                : filteredRows.isEmpty
                    ? const Center(
                        child: Text(
                          'No matching departments found.',
                        ),
                      )
                    : PlutoGrid(
                        columns: columns,
                        rows: filteredRows,
                        configuration:
                            const PlutoGridConfiguration(),
                        onRowDoubleTap: (event) {
                          final id = int.tryParse(
                            event.row.cells['department_id']!
                                .value
                                .toString(),
                          );

                          if (id == null) return;

                          for (final department in departments) {
                            if (department.departmentId == id) {
                              _editDepartment(department);
                              break;
                            }
                          }
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
