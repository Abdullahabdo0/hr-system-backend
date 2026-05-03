import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import 'attendance_log_screen.dart';
import 'audit_log_screen.dart';
import 'employees_screen.dart';
import 'leave_management_screen.dart';
import 'login_screen.dart';
import 'reports_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    EmployeesScreen(),
    AttendanceLogScreen(),
    ReportsScreen(),
    LeaveManagementScreen(),
    AuditLogScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('نظام إدارة الموارد البشرية'),
          backgroundColor: Colors.green.shade700,
          actions: [
            IconButton(
              icon: Icon(
                Theme.of(context).brightness == Brightness.dark
                    ? Icons.light_mode
                    : Icons.dark_mode,
              ),
              onPressed: () {
                Provider.of<ThemeProvider>(
                  context,
                  listen: false,
                ).toggleTheme();
              },
              tooltip: 'تبديل الوضع',
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              ),
              tooltip: 'تسجيل الخروج',
            ),
          ],
        ),
        body: _screens[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'الموظفين',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.list), label: 'السجل'),
            BottomNavigationBarItem(
              icon: Icon(Icons.assessment),
              label: 'التقارير',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment),
              label: 'الطلبات',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'الأنشطة',
            ),
          ],
        ),
      ),
    );
  }
}
