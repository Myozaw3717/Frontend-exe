import 'package:flutter/material.dart';
import 'package:myo/model/country_model.dart';
import 'package:myo/model/get_branch_model.dart';
import 'package:myo/screen/branch_form.dart';
import 'package:myo/service/api_service.dart';
import 'package:pluto_grid/pluto_grid.dart';


class BranchTable extends StatefulWidget {
  const BranchTable({super.key});

  @override
  State<BranchTable> createState() => _BranchTableState();
}

class _BranchTableState extends State<BranchTable> {
  final ApiService _apiService = ApiService();

  late final List<PlutoColumn> columns;

  List<PlutoRow> rows = [];
  bool isLoading = true;
  String? errorMessage;

  final Set<int> _deletingIds = {};

  String _statusFilter = 'All';

  final Color blue = const Color(0xFF4267B2);
  final Color borderColor = const Color(0xFFD5DCE8);

  final TextEditingController _searchController =
      TextEditingController();

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
                entry.key == 'branch_id') {
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
        title: 'Branch Code',
        field: 'branch_code',
        type: PlutoColumnType.text(),
        width: 110,
      ),
      PlutoColumn(
        title: 'Branch Name',
        field: 'branch_name',
        type: PlutoColumnType.text(),
        width: 140,
      ),
      PlutoColumn(
        title: 'Phone',
        field: 'phone',
        type: PlutoColumnType.text(),
        width: 110,
      ),
      PlutoColumn(
        title: 'Email',
        field: 'email',
        type: PlutoColumnType.text(),
        width: 160,
      ),
      PlutoColumn(
        title: 'Address',
        field: 'address',
        type: PlutoColumnType.text(),
        width: 150,
      ),
      PlutoColumn(
        title: 'City',
        field: 'city',
        type: PlutoColumnType.text(),
        width: 100,
      ),
      PlutoColumn(
        title: 'Country',
        field: 'country',
        type: PlutoColumnType.text(),
        width: 100,
      ),
      PlutoColumn(
        title: 'Status',
        field: 'is_active',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        width: 155,
        renderer: (rendererContext) {
          final value = rendererContext.cell.value;

          final bool isActive =
              value == true ||
              value.toString().toLowerCase() == 'true' ||
              value.toString() == '1' ||
              value.toString() == 'Yes';
              return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                value: isActive,
                activeThumbColor: Colors.white,
                activeTrackColor: const Color.fromARGB(255, 65, 3, 146),
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
        width: 80,
        enableEditingMode: false,
        enableSorting: false,
        enableFilterMenuItem: false,
        renderer: (rendererContext) {
          final id = int.tryParse(
            rendererContext.row.cells['branch_id']!
                .value
                .toString(),
          );

          final isDeleting =
              id != null && _deletingIds.contains(id);

          return IconButton(
            tooltip: 'Delete branch',
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

    loadBranches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> loadBranches() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final results = await Future.wait([
        _apiService.fetchBranches(),
        _apiService.fetchCountries(),
      ]);

      final List<Branch> branches =
          results[0] as List<Branch>;

      final List<Country> countries =
          results[1] as List<Country>;

      final loadedRows = branches.map((branch) {
        final matchingCountries = countries.where(
          (country) => country.countryId == branch.countryId,
        );

        final countryName = matchingCountries.isNotEmpty
            ? matchingCountries.first.countryName
            : '';

        return PlutoRow(
          cells: {
            'branch_id': PlutoCell(value: branch.branchId),
            'branch_code': PlutoCell(
              value: branch.branchCode ?? '',
            ),
            'branch_name': PlutoCell(
              value: branch.branchName,
            ),
            'phone': PlutoCell(
              value: branch.phone ?? '',
            ),
            'email': PlutoCell(
              value: branch.email ?? '',
            ),
            'address': PlutoCell(
              value: branch.address ?? '',
            ),
            'city': PlutoCell(
              value: branch.city ?? '',
            ),
            'country': PlutoCell(
              value: countryName,
            ),
            'is_active': PlutoCell(
              value: branch.isActive ? 'Yes' : 'No',
            ),
            'action': PlutoCell(value: ''),
          },
        );
      }).toList();

      if (!mounted) return;

      setState(() {
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
  Future<void> _confirmDelete(int branchId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Branch'),
          content: Text(
            'Are you sure you want to delete branch ID $branchId?',
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
      await _deleteBranch(branchId);
    }
  }

  Future<void> _deleteBranch(int branchId) async {
    setState(() {
      _deletingIds.add(branchId);
    });

    try {
      await _apiService.deleteBranch(branchId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Branch deleted successfully.'),
          backgroundColor: Colors.green,
        ),
      );

      await loadBranches();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete branch: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _deletingIds.remove(branchId);
        });
      }
    }
  }

  Future<void> _addBranch() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BranchForm(),
      ),
    );

    if (!mounted) return;

    await loadBranches();
  }

  void _downloadPdfMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Connect a PDF export package to download the branch list.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: const Text('Branch List'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: isLoading ? null : loadBranches,
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
                'Could not load branches',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SelectableText(errorMessage!),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: loadBranches,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }
    if (rows.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.business_outlined,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 12),
            const Text('No branches found.'),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: loadBranches,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status filter and search field
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
                      value: _statusFilter,
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
                  onChanged: (_) {
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF75829B),
                      fontSize: 14,
                    ),
                    suffixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF63728E),
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

          // Add New and Download PDF
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                onPressed: _addBranch,
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
                onPressed: _downloadPdfMessage,
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

          // Branch table
          Expanded(
            child: _filteredRows.isEmpty
                ? const Center(
                    child: Text('No matching branches found.'),
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