import 'package:flutter/material.dart';

import 'dashboard_screen.dart';
import 'branch_table.dart';
import 'department_table.dart';
import 'custodian_table.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<String> _titles = [
    'Dashboard',
    'Branch Management',
    'Department Management',
    'Custodian Management',
  ];

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildCurrentScreen() {
    switch (_selectedIndex) {
      case 0:
        return DashboardScreen(
          key: const ValueKey('dashboard'),
          onNavigate: _onItemSelected,
        );
      case 1:
        return const BranchTable(
          key: ValueKey('branches'),
        );
      case 2:
        return const DepartmentTable(
          key: ValueKey('departments'),
        );
      case 3:
        return const CustodianTable(
          key: ValueKey('custodians'),
        );
      default:
        return DashboardScreen(
          onNavigate: _onItemSelected,
        );
    }
  }

  Widget _buildMenuItem({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String title,
  }) {
    final bool selected = _selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 4,
      ),
      child: ListTile(
        selected: selected,
        selectedTileColor: const Color(0xFFDBEAFE),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        leading: Icon(
          selected ? selectedIcon : icon,
          color: selected
              ? const Color(0xFF2563EB)
              : Colors.blueGrey,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight:
                selected ? FontWeight.bold : FontWeight.normal,
            color: selected
                ? const Color(0xFF1D4ED8)
                : const Color(0xFF334155),
          ),
        ),
        onTap: () => _onItemSelected(index),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 100,
            padding: const EdgeInsets.all(20),
            alignment: Alignment.centerLeft,
            child: const Row(
              children: [
                Icon(
                  Icons.dashboard_customize_rounded,
                  size: 32,
                  color: Color(0xFF2563EB),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'BizSoft CRM',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF172554),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _buildMenuItem(
            index: 0,
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard_rounded,
            title: 'Dashboard',
          ),
          _buildMenuItem(
            index: 1,
            icon: Icons.account_tree_outlined,
            selectedIcon: Icons.account_tree_rounded,
            title: 'Branches',
          ),
          _buildMenuItem(
            index: 2,
            icon: Icons.business_outlined,
            selectedIcon: Icons.business_rounded,
            title: 'Departments',
          ),
          _buildMenuItem(
            index: 3,
            icon: Icons.people_outline_rounded,
            selectedIcon: Icons.people_alt_rounded,
            title: 'Custodians',
          ),
          const Spacer(),
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'BizSoft Management System',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blueGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 700;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FB),
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF172554),
            elevation: 0,
            title: Text(
              _titles[_selectedIndex],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          drawer: isDesktop
              ? null
              : Drawer(
                  child: SafeArea(
                    child: _buildSidebar(),
                  ),
                ),
          body: Row(
            children: [
              if (isDesktop) _buildSidebar(),
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: [
                    DashboardScreen(
                      onNavigate: _onItemSelected,
                    ),
                    const BranchTable(),
                    const DepartmentTable(),
                    const CustodianTable(),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: isDesktop
              ? null
              : NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onItemSelected,
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: 'Home',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.account_tree_outlined),
                      selectedIcon: Icon(Icons.account_tree),
                      label: 'Branch',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.business_outlined),
                      selectedIcon: Icon(Icons.business),
                      label: 'Department',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.people_outline),
                      selectedIcon: Icon(Icons.people),
                      label: 'Custodian',
                    ),
                  ],
                ),
        );
      },
    );
  }
}