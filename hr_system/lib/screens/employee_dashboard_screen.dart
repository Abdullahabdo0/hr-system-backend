import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/employee.dart';
import '../models/attendance.dart';
import '../models/user.dart';
import '../models/leave.dart';
import 'login_screen.dart';
import '../providers/theme_provider.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  final User user;
  final Employee employee;

  const EmployeeDashboardScreen({
    super.key,
    required this.user,
    required this.employee,
  });

  @override
  State<EmployeeDashboardScreen> createState() => _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  final ApiService _apiService = ApiService();
  List<Attendance> _attendanceRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAttendanceRecords();
  }

  Future<void> _loadAttendanceRecords() async {
    setState(() => _isLoading = true);
    try {
      final records = await _apiService.getAttendanceRecords();
      if (!mounted) return;
      setState(() => _attendanceRecords = records.where((r) => r.employeeId == widget.employee.id).toList());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkIn() async {
    try {
      await _apiService.checkIn(widget.employee.id!);
      await _loadAttendanceRecords();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تسجيل الحضور بنجاح')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e')),
      );
    }
  }

  Future<void> _checkOut() async {
    try {
      await _apiService.checkOut(widget.employee.id!);
      await _loadAttendanceRecords();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تسجيل الانصراف بنجاح')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e')),
      );
    }
  }

  bool _hasCheckedInToday() {
    if (_attendanceRecords.isEmpty) return false;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    return _attendanceRecords.any((record) {
      final recordDate = DateTime(
        record.date.year,
        record.date.month,
        record.date.day,
      );
      return recordDate == todayDate && record.checkInTime != null && record.checkOutTime == null;
    });
  }

  Future<void> _showLeaveRequestDialog() async {
    final startDateController = TextEditingController();
    final endDateController = TextEditingController();
    final reasonController = TextEditingController();

    final selected = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('طلب إجازة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: startDateController,
              decoration: const InputDecoration(
                labelText: 'تاريخ البدء (YYYY-MM-DD)',
                hintText: '2024-01-01',
              ),
            ),
            TextField(
              controller: endDateController,
              decoration: const InputDecoration(
                labelText: 'تاريخ الانتهاء (YYYY-MM-DD)',
                hintText: '2024-01-05',
              ),
            ),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'السبب (اختياري)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('إرسال'),
          ),
        ],
      ),
    );

    if (selected == true) {
      try {
        final startDate = DateTime.parse(startDateController.text);
        final endDate = DateTime.parse(endDateController.text);
        
        final leave = Leave(
          employeeId: widget.employee.id!,
          leaveType: 'annual',
          startDate: startDate,
          endDate: endDate,
          reason: reasonController.text.isEmpty ? null : reasonController.text,
          status: 'pending',
          createdAt: DateTime.now(),
        );
        
        await _apiService.requestLeave(leave);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال طلب الإجازة بنجاح')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة تحكم الموظف'),
          actions: [
            IconButton(
              icon: Icon(
                Theme.of(context).brightness == Brightness.dark
                    ? Icons.light_mode
                    : Icons.dark_mode,
              ),
              onPressed: () {
                Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
              },
              tooltip: 'الوضع الداكن',
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              ),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // معلومات الموظف
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.employee.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('المنصب: ${widget.employee.position}'),
                            Text('القسم: ${widget.employee.department}'),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Icon(Icons.money, color: Colors.green),
                                const SizedBox(width: 8),
                                Text(
                                  'الراتب: ${widget.employee.salary.toStringAsFixed(2)} ج.م',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // أزرار تسجيل الحضور والانصراف
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _hasCheckedInToday() ? null : _checkIn,
                            icon: const Icon(Icons.login),
                            label: const Text('تسجيل الحضور'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _hasCheckedInToday() ? _checkOut : null,
                            icon: const Icon(Icons.logout),
                            label: const Text('تسجيل الانصراف'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // زر طلب إجازة
                    ElevatedButton.icon(
                      onPressed: () => _showLeaveRequestDialog(),
                      icon: const Icon(Icons.calendar_today),
                      label: const Text('طلب إجازة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // سجل الحضور
                    const Text(
                      'سجل الحضور',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _attendanceRecords.isEmpty
                        ? const Center(
                            child: Text('لا توجد سجلات حضور'),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _attendanceRecords.length,
                            itemBuilder: (context, index) {
                              final record = _attendanceRecords[index];
                              return Card(
                                child: ListTile(
                                  title: Text(
                                    DateFormat('yyyy-MM-dd').format(record.date),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (record.checkInTime != null)
                                        Text(
                                          'حضور: ${DateFormat('HH:mm').format(record.checkInTime!)}',
                                        ),
                                      if (record.checkOutTime != null)
                                        Text(
                                          'انصراف: ${DateFormat('HH:mm').format(record.checkOutTime!)}',
                                        ),
                                      if (record.totalHours > 0)
                                        Text(
                                          'إجمالي الساعات: ${record.totalHours.toStringAsFixed(2)}',
                                        ),
                                    ],
                                  ),
                                  trailing: Icon(
                                    _getStatusIcon(record.status),
                                    color: _getStatusColor(record.status),
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'present':
        return Icons.check_circle;
      case 'absent':
        return Icons.cancel;
      case 'late':
        return Icons.access_time;
      default:
        return Icons.help;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'late':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
