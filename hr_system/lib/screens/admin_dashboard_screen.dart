import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'employees_screen.dart';
import 'job_applicants_screen.dart';
import 'communications_screen.dart';
import 'notifications_screen.dart';
import 'attendance_log_screen.dart';
import 'reports_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import '../models/user.dart';
import '../models/employee.dart';
import '../services/api_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  final User? user;
  final Employee? employee;

  const AdminDashboardScreen({super.key, this.user, this.employee});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Employee _currentEmployee;
  late User _currentUser;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user ?? User(username: 'admin', role: 'admin');
    _currentEmployee = widget.employee ?? Employee(
      name: 'محمد علي',
      email: 'admin@hr.com',
      phone: '01012345678',
      position: 'مدير النظام',
      department: 'الإدارة العليا',
      nationalId: '12345678901234',
      address: 'القاهرة، مصر',
      hireDate: DateTime.now(),
      qualification: 'بكالوريوس هندسة',
      location: 'المركز الرئيسي',
      salary: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF1DB954);
    final darkBlue = const Color(0xFF0A0E27);

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF0F2F5),
        // Sidebar Menu (Drawer)
        drawer: Drawer(
          child: Column(
            children: [
              UserAccountsDrawerHeader(
                decoration: BoxDecoration(color: darkBlue),
                currentAccountPicture: CircleAvatar(
                  backgroundImage: _currentEmployee.profilePictureUrl != null
                      ? NetworkImage(_currentEmployee.profilePictureUrl!)
                      : const NetworkImage('https://i.pravatar.cc/150?u=admin'),
                ),
                accountName: Text(_currentEmployee.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                accountEmail: Text(_currentEmployee.email),
              ),
              ListTile(
                leading: const Icon(Icons.person_outline, color: Colors.blue),
                title: const Text('الملف الشخصي'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(
                        user: _currentUser,
                        employee: _currentEmployee,
                        onUpdate: (emp) => setState(() => _currentEmployee = emp),
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined, color: Colors.grey),
                title: const Text('الإعدادات'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.help_outline, color: Colors.grey),
                title: const Text('المساعدة والدعم'),
                onTap: () => Navigator.pop(context),
              ),
              const Spacer(),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: Colors.red),
                title: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        body: Column(
          children: [
            // Premium Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [darkBlue, const Color(0xFF1A1F3D)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(_currentEmployee.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(_currentEmployee.position, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(
                            user: _currentUser,
                            employee: _currentEmployee,
                            onUpdate: (emp) => setState(() => _currentEmployee = emp),
                          ),
                        ),
                      );
                    },
                    child: Hero(
                      tag: 'profile_pic',
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: primaryColor, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 25,
                          backgroundImage: _currentEmployee.profilePictureUrl != null
                              ? NetworkImage(_currentEmployee.profilePictureUrl!)
                              : const NetworkImage('https://i.pravatar.cc/150?u=admin'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Summary
                    Row(
                      children: [
                        _buildStatCard('إجمالي الموظفين', '124', Icons.people_alt_rounded, Colors.blue),
                        const SizedBox(width: 15),
                        _buildStatCard('حضور اليوم', '92%', Icons.done_all_rounded, Colors.green),
                      ],
                    ),
                    const SizedBox(height: 25),

                    const Text('آخر التحديثات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    
                    _buildActivityItem('تم قبول طلب إجازة', 'الموظف: أحمد محمد', 'منذ 5 دقائق', Icons.beach_access, Colors.orange),
                    _buildActivityItem('طلب شراء جديد', 'قسم المخازن', 'منذ ساعة', Icons.shopping_cart, Colors.blue),
                    _buildActivityItem('تسجيل حضور متأخر', 'الموظف: سارة علي', 'منذ ساعتين', Icons.warning_amber_rounded, Colors.red),
                    _buildActivityItem('إضافة موظف جديد', 'قسم المبيعات', 'منذ 3 ساعات', Icons.person_add, Colors.teal),
                    
                    const SizedBox(height: 20),
                    _buildQuickActionBanner(primaryColor),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: darkBlue,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavIcon(Icons.badge_outlined, 'الموظفين', const EmployeesScreen()),
              _buildNavIcon(Icons.person_add_alt_1_outlined, 'التوظيف', const JobApplicantsScreen()),
              _buildNavIcon(Icons.mail_outline_rounded, 'المكاتبات', const CommunicationsScreen()),
              _buildNavIcon(Icons.history_toggle_off_rounded, 'الحضور', const AttendanceLogScreen()),
              _buildNavIcon(Icons.insert_chart_outlined_rounded, 'التقارير', const ReportsScreen()),
              _buildNavIcon(Icons.notifications_active_outlined, 'الإشعارات', const NotificationsScreen()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, String label, Widget screen) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => screen)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 22),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 9)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String title, String sub, String time, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          Text(time, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildQuickActionBanner(Color primaryColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [primaryColor, const Color(0xFF008F39)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 30),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('نظام الموارد البشرية المتطور', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text('كفاءة أعلى، ورق أقل.', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
