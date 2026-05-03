import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/attendance.dart';
import '../models/employee.dart';
import '../models/leave.dart';
import '../models/user.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';
import 'leave_request_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  final User user;
  final Employee employee;

  const EmployeeDashboardScreen({
    super.key,
    required this.user,
    required this.employee,
  });

  @override
  State<EmployeeDashboardScreen> createState() =>
      _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  final ApiService _apiService = ApiService();

  List<Attendance> _attendanceRecords = [];
  List<Leave> _leaveRequests = [];
  late Employee _employee;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _employee = widget.employee;
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final employeeId = widget.employee.id;
      if (employeeId == null) {
        throw Exception('معرف الموظف غير موجود');
      }

      final attendance = await _apiService.getAttendanceRecords();
      final leaves = await _apiService.getLeaves(employeeId: employeeId);
      final updatedEmployee = await _apiService.getEmployeeById(employeeId);

      if (!mounted) return;

      setState(() {
        if (updatedEmployee != null) _employee = updatedEmployee;
        _attendanceRecords = attendance
            .where((record) => record.employeeId == employeeId)
            .toList();
        _leaveRequests = [...leaves]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _hasCheckedInToday() {
    if (_attendanceRecords.isEmpty) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return _attendanceRecords.any((record) {
      final recordDay = DateTime(
        record.date.year,
        record.date.month,
        record.date.day,
      );
      return recordDay == today && record.checkInTime != null;
    });
  }

  bool _hasCheckedOutToday() {
    if (_attendanceRecords.isEmpty) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return _attendanceRecords.any((record) {
      final recordDay = DateTime(
        record.date.year,
        record.date.month,
        record.date.day,
      );
      return recordDay == today && record.checkOutTime != null;
    });
  }

  Future<void> _openRequestScreen(String type) async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => LeaveRequestScreen(
          user: widget.user,
          employee: widget.employee,
          initialRequestType: type,
        ),
      ),
    );

    if (created == true && mounted) {
      await _loadDashboardData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF1DB954);
    final secondaryColor = const Color(0xFF2D9CDB);
    final purpleColor = const Color(0xFF9B51E0);

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // 1. Dark Header Section
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0A0E27),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_none, color: Colors.white, size: 28),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا توجد إشعارات جديدة')));
                          },
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'أهلاً بك، ${_employee.name.split(' ').first}',
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _employee.position,
                              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(width: 15),
                        Container(
                          width: 55,
                          height: 55,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24, width: 2),
                          ),
                          child: ClipOval(
                            child: _employee.profilePictureUrl != null
                                ? (_employee.profilePictureUrl!.startsWith('http')
                                    ? Image.network(_employee.profilePictureUrl!, fit: BoxFit.cover)
                                    : Image.file(File(_employee.profilePictureUrl!), fit: BoxFit.cover))
                                : Image.network('https://i.pravatar.cc/150?u=${_employee.id}', fit: BoxFit.cover),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _loadDashboardData,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'لوحة التحكم',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
                            ),
                            const SizedBox(height: 20),

                            // 2. Action Cards Grid
                            _buildActionCard(
                              'تسجيل الحضور/الانصراف',
                              'سجل حضورك وانصرافك اليومي',
                              Icons.calendar_today_rounded,
                              const Color(0xFFE8F5E9),
                              primaryColor,
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EmployeeAttendanceScreen(
                                    employee: widget.employee,
                                    onRefresh: _loadDashboardData,
                                    hasCheckedIn: _hasCheckedInToday(),
                                    hasCheckedOut: _hasCheckedOutToday(),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            _buildActionCard(
                              'طلب إجازة',
                              'تقديم طلب إجازة جديدة',
                              Icons.umbrella_outlined,
                              const Color(0xFFE3F2FD),
                              secondaryColor,
                              () => _openRequestScreen('annual'),
                            ),
                            const SizedBox(height: 15),
                             _buildActionCard(
                              'الملف الشخصي',
                              'عرض وتعديل بياناتي الشخصية',
                              Icons.person_outline,
                              const Color(0xFFF3E5F5),
                              purpleColor,
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProfileScreen(
                                      user: widget.user,
                                      employee: _employee,
                                      onUpdate: (updated) {
                                        setState(() => _employee = updated);
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 35),
                            const Text(
                              'حالتك اليوم',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
                            ),
                            const SizedBox(height: 15),

                            // 3. Status Today Card
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _hasCheckedOutToday() ? 'تم الانصراف' : (_hasCheckedInToday() ? 'حاضر' : 'لم يتم تسجيل الحضور'),
                                        style: TextStyle(
                                          color: _hasCheckedOutToday() ? Colors.grey : (_hasCheckedInToday() ? primaryColor : Colors.orange),
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      if (_hasCheckedOutToday() && _attendanceRecords.isNotEmpty) ...[
                                        Text(
                                          'تم تسجيل انصرافك في',
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                        ),
                                        Text(
                                          DateFormat('hh:mm a').format(_attendanceRecords.last.checkOutTime ?? DateTime.now()),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                      ] else if (_hasCheckedInToday() && _attendanceRecords.isNotEmpty) ...[
                                        Text(
                                          'تم تسجيل حضورك في',
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                        ),
                                        Text(
                                          DateFormat('hh:mm a').format(_attendanceRecords.last.checkInTime ?? DateTime.now()),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                      ] else 
                                        Text(
                                          'بانتظار تسجيل الحضور',
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                        ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: (_hasCheckedOutToday() ? Colors.grey : (_hasCheckedInToday() ? primaryColor : Colors.orange)).withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _hasCheckedOutToday() ? Icons.done_all : (_hasCheckedInToday() ? Icons.check_circle_outline : Icons.access_time),
                                      color: _hasCheckedOutToday() ? Colors.grey : (_hasCheckedInToday() ? primaryColor : Colors.orange),
                                      size: 30,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 30),
                            Center(
                              child: TextButton.icon(
                                onPressed: () => Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                                ),
                                icon: const Icon(Icons.logout, color: Colors.red),
                                label: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color bgColor, Color iconColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }
}

class EmployeeAttendanceScreen extends StatefulWidget {
  final Employee employee;
  final VoidCallback onRefresh;
  final bool hasCheckedIn;
  final bool hasCheckedOut;

  const EmployeeAttendanceScreen({super.key, required this.employee, required this.onRefresh, required this.hasCheckedIn, required this.hasCheckedOut});

  @override
  State<EmployeeAttendanceScreen> createState() => _EmployeeAttendanceScreenState();
}

class _EmployeeAttendanceScreenState extends State<EmployeeAttendanceScreen> {
  final ApiService _apiService = ApiService();
  bool _isChecking = false;
  String _currentTime = '';
  String _currentDate = '';

  @override
  void initState() {
    super.initState();
    _updateTime();
  }

  void _updateTime() {
    if (!mounted) return;
    final now = DateTime.now();
    setState(() {
      _currentTime = DateFormat('hh:mm:ss a').format(now);
      _currentDate = DateFormat('EEEE, d MMMM yyyy', 'ar').format(now);
    });
    Future.delayed(const Duration(seconds: 1), _updateTime);
  }

  Future<void> _handleCheckInOut() async {
    setState(() => _isChecking = true);
    try {
      if (widget.hasCheckedIn && !widget.hasCheckedOut) {
        await _apiService.checkOut(widget.employee.id!);
        if (!mounted) return;
        widget.onRefresh();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تسجيل الانصراف بنجاح')));
      } else {
        await _apiService.checkIn(widget.employee.id!);
        if (!mounted) return;
        widget.onRefresh();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تسجيل الحضور بنجاح')));
      }
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(widget.hasCheckedIn && !widget.hasCheckedOut ? 'تسجيل الانصراف' : 'تسجيل الحضور', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(icon: const Icon(Icons.qr_code_scanner, color: Colors.black), onPressed: () {}),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.hasCheckedOut 
                        ? Colors.grey.withOpacity(0.2) 
                        : (widget.hasCheckedIn ? Colors.redAccent.withOpacity(0.2) : const Color(0xFF1DB954).withOpacity(0.2)), 
                    width: 10
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: widget.hasCheckedOut ? Colors.grey : (widget.hasCheckedIn ? Colors.redAccent : const Color(0xFF1DB954)),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.hasCheckedOut ? Icons.done_all : (widget.hasCheckedIn ? Icons.output_rounded : Icons.check), 
                      color: Colors.white, 
                      size: 80
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                _currentTime,
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A)),
              ),
              Text(
                _currentDate,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on, color: Colors.grey.shade400, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'الموقع الحالي\nالقاهرة، مصر',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: widget.hasCheckedOut || _isChecking ? null : _handleCheckInOut,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.hasCheckedOut ? Colors.grey : (widget.hasCheckedIn ? Colors.redAccent : const Color(0xFF1DB954)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: _isChecking 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        widget.hasCheckedOut ? 'تم التسجيل لليوم' : (widget.hasCheckedIn ? 'تسجيل الانصراف' : 'تسجيل الحضور'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)
                      ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
